using DevExpress.Data.Filtering;
using DevExpress.Xpo;
using DevExpress.Xpo.DB;
using NLog;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using global::XTA.XData.Models;
using global::XTA.XData.Interfaces;
using global::XTA.XData.Services;
using XTA.Models;
using XTA.Core;

namespace XTA.Infrastructure.Data
{
    public class SignalSavedEventArgs : EventArgs
    {
        public string Sid { get; }
        public bool IsNew { get; }
        public SignalSavedEventArgs(string sid, bool isNew) { Sid = sid; IsNew = isNew; }
    }

    /// <summary>
    /// XPO 기반 SQLite 데이터 서비스
    /// </summary>
    public class XpoSqliteService : XObject, ISignalRepository, IChannelOptionRepository, IGridProfileRepository
    {
        public event EventHandler<SignalSavedEventArgs>? SignalSaved;

        private IDataLayer? _dataLayer;
        private string? _dbPath;
        private readonly object _initLock = new object();

        private readonly ConcurrentQueue<XDataObject> _signalQueue = new();
        private readonly ConcurrentQueue<XDataObject> _messageQueue = new();
        private System.Threading.CancellationTokenSource? _dbLoopCancelSource;

        public XpoSqliteService(XParameter param) : base(param)
        {
        }

        public void Initialize()
        {
            if (_dataLayer != null) return;
            lock (_initLock)
            {
                if (_dataLayer != null) return;
                try
                {
                    string? path = param.Config?.System?.DatabaseFullPath;
                    string commonPath = System.IO.Path.Combine(
                        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                        @"MetaQuotes\Terminal\Common\Files");

                    if (string.IsNullOrEmpty(path))
                    {
                        path = System.IO.Path.Combine(commonPath, "ATS.db");
                    }
                    else if (!System.IO.Path.IsPathRooted(path))
                    {
                        // 상대 경로이거나 파일명만 있는 경우 공용 폴더 기준으로 해석
                        path = System.IO.Path.Combine(commonPath, path);
                    }

                    _dbPath = System.IO.Path.GetFullPath(path);
                    nlog.Trace($"[DB] Initializing SQLite DataLayer. ABSOLUTE PATH: {_dbPath}");
                    Console.WriteLine($"[DB] Initializing SQLite DataLayer. ABSOLUTE PATH: {_dbPath}");

                    string? dbDir = System.IO.Path.GetDirectoryName(_dbPath);
                    if (!string.IsNullOrEmpty(dbDir) && !System.IO.Directory.Exists(dbDir)) System.IO.Directory.CreateDirectory(dbDir);

                    string connStr = SQLiteConnectionProvider.GetConnectionString(_dbPath);
                    var dict = new DevExpress.Xpo.Metadata.ReflectionDictionary();
                    dict.CollectClassInfos(typeof(XpoSignal).Assembly);

                    var store = XpoDefault.GetConnectionProvider(connStr, AutoCreateOption.DatabaseAndSchema);
                    if (store is SQLiteConnectionProvider sqliteProvider)
                    {
                        try { using var cmd = sqliteProvider.Connection.CreateCommand(); cmd.CommandText = "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;"; cmd.ExecuteNonQuery(); }
                        catch { }
                    }

                    _dataLayer = new ThreadSafeDataLayer(dict, store);
                    _dataLayer.UpdateSchema(false, dict.CollectClassInfos(typeof(XpoSignal).Assembly).ToArray());
                }
                catch (Exception ex) { nlog.Fatal(ex, $"[XData] XPO INIT FAILED! Path: {_dbPath}"); throw; }
            }
        }

        public IDataLayer GetLayer() { if (_dataLayer == null) Initialize(); return _dataLayer!; }

        private bool _isStarted = false;
        public override void Start()
        {
            lock (_initLock) { if (_isStarted) return; _isStarted = true; }
            Initialize();
            _dbLoopCancelSource = new System.Threading.CancellationTokenSource();
            Task.Run(ProcessSignalQueue, _dbLoopCancelSource.Token);
            Task.Run(ProcessMessageQueue, _dbLoopCancelSource.Token);
            Task.Run(ProcessArchivingQueue, _dbLoopCancelSource.Token);
            nlog.Trace("XpoSqliteService Started.");
        }

        public override void Stop() { _dbLoopCancelSource?.Cancel(); _dataLayer?.Dispose(); _dataLayer = null; _isStarted = false; }

        public string DbPath 
        { 
            get 
            { 
                if (string.IsNullOrEmpty(_dbPath)) Initialize();
                return _dbPath ?? "N/A"; 
            } 
        }

        #region ISignalRepository Implementation
        public async Task<XTA.XData.Models.XSignal?> GetSignalBySidAsync(string sid)
        {
            var xpo = await GetLayer().FindObjectAsync<XpoSignal>(CriteriaOperator.Parse("sid = ?", sid));
            return xpo?.ToDomainModel();
        }

        public async Task<List<XTA.XData.Models.XSignal>> GetSignalsByCnoAsync(int cno, int count = 500)
        {
            string tagPattern = $"%({cno})%";
            var criteria = cno > 0 ? CriteriaOperator.Parse("cno = ? OR tag LIKE ?", cno, tagPattern) : CriteriaOperator.Parse("True");
            // [v9.0] SID 내림차순 정렬 (최신 신호 상단 배치)
            var sorts = new[] { new SortProperty("sid", SortingDirection.Descending) };
            var list = await GetLayer().FindListAsync<XpoSignal>(criteria, sorts);
            
            Console.WriteLine($"[DB:QUERY] CNO:{cno} | Criteria: {criteria} | Found: {list.Count} | DB: {_dbPath}");
            
            if (count > 0) return list.Take(count).Select(x => x.ToDomainModel()).ToList();
            return list.Select(x => x.ToDomainModel()).ToList();
        }

        public List<XTA.XData.Models.XSignal> GetSignalsByCno(int cno, int count = 500) => GetSignalsByCnoAsync(cno, count).Result;

        public async Task SaveSignalAsync(XTA.XData.Models.XSignal signal)
        {
            _signalQueue.Enqueue(new XDataObject { Signal = signal as XTA.Models.XSignal ?? XTA.Models.XSignal.FromBase(signal) });
            await Task.CompletedTask;
        }

        public async Task SaveSignalImmediateAsync(XTA.XData.Models.XSignal signal, bool force = false)
        {
            using var uow = new UnitOfWork(GetLayer());
            var xpo = await uow.FindObjectAsync<XpoSignal>(CriteriaOperator.Parse("sid = ?", signal.sid));
            
            // [v9.8.4] 히스토리 테이블 검색 (좀비 신호 방지)
            // [v9.0] force=true 일 경우 히스토리 가드 무시 (수동 재주입 지원)
            if (xpo == null && !force)
            {
                var history = await uow.FindObjectAsync<XpoSignalHistory>(CriteriaOperator.Parse("sid = ?", signal.sid));
                if (history != null)
                {
                    nlog.Warn($"[DB:SAVE_IMMEDIATE] Signal {signal.sid} is already archived. Ignoring update to prevent zombie state.");
                    return; // 히스토리에 있으면 새 활성 레코드 생성 무시
                }
            }

            bool isNew = xpo == null;
            if (isNew) { xpo = new XpoSignal(uow) { created = DateTime.Now, sid = signal.sid }; }
            signal.ToXpoModel(xpo!);
            xpo!.updated = DateTime.Now;
            await uow.CommitChangesAsync();
            nlog.Debug($"[DB:SAVE] Signal {signal.sid} {(isNew ? "Inserted" : "Updated")} into {_dbPath}");            Console.WriteLine($"[DB:SAVE] Signal {signal.sid} {(isNew ? "Inserted" : "Updated")} into {_dbPath}");
            
            SignalSaved?.Invoke(this, new SignalSavedEventArgs(signal.sid, isNew));
        }

        public async Task UpdateSignalStatusAsync(string sid, int xeStatus, string xeStatusMsg)
        {
            using var uow = new UnitOfWork(GetLayer());
            var xpo = await uow.FindObjectAsync<XpoSignal>(CriteriaOperator.Parse("sid = ?", sid));
            if (xpo != null)
            {
                xpo.SetXeStatus(xeStatus); xpo.xe_status_msg = xeStatusMsg; xpo.updated = DateTime.Now;
                var h = new XpoSignalStatusHistory(uow) { ref_id = xpo.id, sid = xpo.sid, xe_status = xeStatus, time = DateTime.Now, msg = xeStatusMsg ?? string.Empty };
                await uow.CommitChangesAsync();
            }
        }

        public async Task UpdateXaStatusAsync(string sid, int xaStatus) 
        { 
            using var uow = new UnitOfWork(GetLayer()); 
            var xpo = await uow.FindObjectAsync<XpoSignal>(CriteriaOperator.Parse("sid = ?", sid)); 
            if (xpo != null) 
            { 
                xpo.xa_exit = xaStatus; // [v9.8.9] xa_entry 대신 xa_exit을 정확히 타겟팅하도록 수정
                xpo.updated = DateTime.Now; 
                await uow.CommitChangesAsync(); 
            } 
        }

        public async Task UpdateXaEntryAsync(string sid, int xaEntry)
        {
            using var uow = new UnitOfWork(GetLayer());
            var xpo = await uow.FindObjectAsync<XpoSignal>(CriteriaOperator.Parse("sid = ?", sid));
            if (xpo != null)
            {
                xpo.xa_entry = xaEntry;
                xpo.updated = DateTime.Now;
                await uow.CommitChangesAsync();
            }
        }
        public async Task<int> SaveRawSignalAsync(XTA.XData.Models.XSignal signal, string rawText) { using var uow = new UnitOfWork(GetLayer()); var raw = new XpoSignalRaw(uow) { symbol = signal.symbol, dir = signal.dir, type = signal.type, price = signal.price_signal, lot = signal.lot, sno = signal.sno, raw_text = rawText ?? string.Empty, created_at = DateTime.Now }; await uow.CommitChangesAsync(); return raw.Oid; }
        public async Task DeleteSignalAsync(string sid) { using var uow = new UnitOfWork(GetLayer()); var xpo = await uow.FindObjectAsync<XpoSignal>(CriteriaOperator.Parse("sid = ?", sid)); if (xpo != null) { xpo.Delete(); await uow.CommitChangesAsync(); } }
        public async Task DeleteAllSignalsAsync() { using var uow = new UnitOfWork(GetLayer()); try { await uow.ExecuteNonQueryAsync("DELETE FROM signals"); await uow.CommitChangesAsync(); } catch (Exception ex) { nlog.Error(ex, "[DB] Failed to delete all signals."); throw; } }
        public async Task<XTA.XData.Models.XSignal?> FindLastActiveSignalBySnoAsync(int cno, int sno) { var criteria = CriteriaOperator.Parse("(cno = ? OR tag LIKE ?) AND sno = ? AND ((xa_entry > ? AND xe_status < ?) OR (xa_exit > ?))", cno, $"%({cno})%", sno, XCode.XA_RAW, (int)XCode.EaStatus.Closed_Signal, XCode.XA_RAW); var list = await GetLayer().FindListAsync<XpoSignal>(criteria, new SortProperty("created", SortingDirection.Descending)); return list.FirstOrDefault()?.ToDomainModel(); }
        public async Task<List<XTA.XData.Models.XSignal>> FindActiveSignalsBySnoAsync(int cno, int sno) { var criteria = CriteriaOperator.Parse("(cno = ? OR tag LIKE ?) AND sno = ? AND ((xa_entry > ? AND xe_status < ?) OR (xa_exit > ?))", cno, $"%({cno})%", sno, XCode.XA_RAW, (int)XCode.EaStatus.Closed_Signal, XCode.XA_RAW); var list = await GetLayer().FindListAsync<XpoSignal>(criteria, new SortProperty("created", SortingDirection.Descending)); return list.Select(x => x.ToDomainModel()).ToList(); }
        
        /// <summary>
        /// [v9.6.6] 활성 및 히스토리를 모두 검색하여 해당 회차의 신호가 존재했는지 확인
        /// </summary>
        public async Task<XTA.XData.Models.XSignal?> FindAnySignalBySnoAsync(int cno, int sno)
        {
            // 1. 활성 테이블 검색
            var activeCriteria = CriteriaOperator.Parse("(cno = ? OR tag LIKE ?) AND sno = ?", cno, $"%({cno})%", sno);
            var activeList = await GetLayer().FindListAsync<XpoSignal>(activeCriteria, new SortProperty("created", SortingDirection.Descending));
            var active = activeList.FirstOrDefault();
            if (active != null) return active.ToDomainModel();

            // 2. 히스토리 테이블 검색
            var historyCriteria = CriteriaOperator.Parse("(cno = ? OR tag LIKE ?) AND sno = ?", cno, $"%({cno})%", sno);
            var historyList = await GetLayer().FindListAsync<XpoSignalHistory>(historyCriteria, new SortProperty("created", SortingDirection.Descending));
            var history = historyList.FirstOrDefault();
            return history?.ToDomainModel();
        }

        public async Task<List<XTA.XData.Models.XSignal>> GetAllActiveSignalsAsync() { var criteria = CriteriaOperator.Parse("(xa_entry > ? AND xe_status < ?) OR (xa_exit > ?)", XCode.XA_RAW, (int)XCode.EaStatus.Closed_Signal, XCode.XA_RAW); var list = await GetLayer().FindListAsync<XpoSignal>(criteria); return list.Select(x => x.ToDomainModel()).ToList(); }
        public async Task<List<XTA.XData.Models.XSignal>> GetClosedSignalsAsync() { var criteria = CriteriaOperator.Parse("xe_status >= ?", (int)XCode.EaStatus.Closed_Signal); var list = await GetLayer().FindListAsync<XpoSignal>(criteria); return list.Select(x => x.ToDomainModel()).ToList(); }
        public async Task<List<XTA.XData.Models.XSignal>> GetErrorSignalsAsync() { var criteria = CriteriaOperator.Parse("xe_status = ?", 99); var list = await GetLayer().FindListAsync<XpoSignal>(criteria); return list.Select(x => x.ToDomainModel()).ToList(); }
        #endregion

        #region IChannelOptionRepository Implementation
        public async Task<XTA.XData.Models.XChannelOption?> GetOptionAsync(int cno) { var xpo = await GetLayer().FindObjectAsync<XpoChannelOption>(CriteriaOperator.Parse("cno = ?", cno)); return xpo?.ToDomainModel(); }
        public async Task SaveOptionAsync(XTA.XData.Models.XChannelOption option) => await GetLayer().SaveObjectAsync<XpoChannelOption>((xpo, uow) => option.ToXpoModel(xpo), CriteriaOperator.Parse("cno = ?", option.cno));
        public async Task<List<XTA.XData.Models.XChannelOption>> GetAllOptionsAsync() => (await GetLayer().FindListAsync<XpoChannelOption>(CriteriaOperator.Parse("True"))).Select(x => x.ToDomainModel()).ToList();
        public void SetOption(XTA.XData.Models.XChannelOption option) => _ = SaveOptionAsync(option);
        public XTA.XData.Models.XChannelOption? GetOption(int cno) => GetOptionAsync(cno).Result;
        #endregion

        #region IGridProfileRepository Implementation
        public async Task<XTA.XData.Models.XGridProfile?> GetGridProfileAsync(int cno, int dir, int gno) { var xpo = await GetLayer().FindObjectAsync<XpoGridProfile>(CriteriaOperator.Parse("cno = ? AND dir = ? AND gno = ?", cno, dir, gno)); return xpo?.ToDomainModel(); }
        public async Task<List<XTA.XData.Models.XGridProfile>> GetGridProfilesAsync(int cno, int dir) => (await GetLayer().FindListAsync<XpoGridProfile>(CriteriaOperator.Parse("cno = ? AND dir = ?", cno, dir), new SortProperty("gno", SortingDirection.Ascending))).Select(x => x.ToDomainModel()).ToList();
        public async Task SaveGridProfileAsync(XTA.XData.Models.XGridProfile profile) => await GetLayer().SaveObjectAsync<XpoGridProfile>((xpo, uow) => profile.ToXpoModel(xpo), CriteriaOperator.Parse("cno = ? AND dir = ? AND gno = ?", profile.cno, profile.dir, profile.gno));
        public List<XTA.XData.Models.XGridProfile> GetGridProfiles(int cno, int dir) => GetGridProfilesAsync(cno, dir).Result;
        public void SetGridProfile(XTA.XData.Models.XGridProfile profile) => _ = SaveGridProfileAsync(profile);
        #endregion

        public async Task ClearAllSignalsAsync() { using var uow = new UnitOfWork(GetLayer()); try { await uow.ExecuteNonQueryAsync($"DELETE FROM signals WHERE xe_status >= {(int)XCode.EaStatus.Closed_Signal}"); await uow.CommitChangesAsync(); } catch (Exception ex) { nlog.Error(ex, "[DB] Failed to clear signals."); throw; } }

        private async Task ProcessSignalQueue() { 
            while (_dbLoopCancelSource != null && !_dbLoopCancelSource.IsCancellationRequested) { 
                try { 
                    if (!_signalQueue.IsEmpty) { 
                        using var uow = new UnitOfWork(GetLayer()); 
                        var savedEvents = new List<SignalSavedEventArgs>();
                        while (_signalQueue.TryDequeue(out var xdo)) { 
                            if (xdo?.Signal == null) continue; 
                            
                            // 1. 활성 테이블 검색
                            var xpo = await uow.FindObjectAsync<XpoSignal>(CriteriaOperator.Parse("sid = ?", xdo.Signal.sid)); 
                            
                            // 2. [v9.8.4] 히스토리 테이블 검색 (좀비 신호 방지)
                            if (xpo == null)
                            {
                                var history = await uow.FindObjectAsync<XpoSignalHistory>(CriteriaOperator.Parse("sid = ?", xdo.Signal.sid));
                                if (history != null)
                                {
                                    nlog.Warn($"[DB:QUEUE] Signal {xdo.Signal.sid} is already archived. Ignoring update to prevent zombie state.");
                                    continue; // 히스토리에 있으면 새 활성 레코드 생성 무시
                                }
                            }

                            bool isNew = xpo == null;
                            if (isNew) xpo = new XpoSignal(uow) { created = DateTime.Now, sid = xdo.Signal.sid }; 
                            xdo.Signal.ToXpoModel(xpo!); 
                            xpo!.updated = DateTime.Now; 
                            nlog.Trace($"[DB:QUEUE] Signal {xdo.Signal.sid} {(isNew ? "Inserted" : "Updated")}");
                            savedEvents.Add(new SignalSavedEventArgs(xdo.Signal.sid, isNew));
                        } 
                        await uow.CommitChangesAsync(); 

                        foreach (var e in savedEvents)
                        {
                            SignalSaved?.Invoke(this, e);
                        }
                    } 
                } catch (Exception ex) { nlog.Error(ex, "[DB] Signal Queue Error"); } 
                await Task.Delay(1000); 
            } 
        }
        private async Task ProcessMessageQueue() { while (_dbLoopCancelSource != null && !_dbLoopCancelSource.IsCancellationRequested) { try { if (!_messageQueue.IsEmpty) { using var uow = new UnitOfWork(GetLayer()); while (_messageQueue.TryDequeue(out var xdo)) { var msg = new XpoTgMessage(uow) { CID = xdo.CID, Time = DateTime.Now, CNO = xdo.CNO, Text = xdo.Text ?? string.Empty, Status = 0 }; } await uow.CommitChangesAsync(); } } catch (Exception ex) { nlog.Error(ex, "[DB] Message Queue Error"); } await Task.Delay(1000); } }
        private async Task ProcessArchivingQueue() { while (_dbLoopCancelSource != null && !_dbLoopCancelSource.IsCancellationRequested) { try { await ArchiveSignalsInternal(); } catch (Exception ex) { nlog.Error(ex, "[DB] Archiving Loop Error"); } int delaySec = 1; try { var param = this.param as XTA.Models.XParameter; if (param?.Config?.System != null) delaySec = Math.Max(1, param.Config.System.ArchiveIntervalSeconds); } catch { } await Task.Delay(TimeSpan.FromSeconds(delaySec)); } }
        public async Task ArchiveSignalsInternal() { try { using var uow = new UnitOfWork(GetLayer()); var targets = new XPCollection<XpoSignal>(uow, CriteriaOperator.Parse("xa_exit = ? AND xe_status >= ?", XCode.XA_ARCHIVE_READY, (int)XCode.EaStatus.Closed_Signal)).ToList(); var sids = targets.Select(t => t.sid).ToList(); foreach (var s in targets) { var h = new XpoSignalHistory(uow); s.ToHistoryModel(h); s.Delete(); } if (targets.Count > 0) { await uow.CommitChangesAsync(); // Clear TTS played cache for archived SIDs so reinjection can trigger audio again
                    try { XContext.Instance.Sound?.ClearPlayedForSid(sids.FirstOrDefault() ?? string.Empty); } catch { }
                } } catch (Exception ex) { nlog.Error(ex, "[DB:ARCHIVE] Archiving Protocol Failure."); } }
    }
}
