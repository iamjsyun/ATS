using DevExpress.Data.Filtering;
using DevExpress.Xpo;
using DevExpress.Xpo.DB;
using DevExpress.Xpo.Metadata;
using NLog;
using System;
using System.IO;
using System.Linq;
using XTA.XData.Models;

namespace XTA.XData.Services;

/// <summary>
/// SQLite 전용 XPO 데이터 환경 초기화를 담당하는 기본 클래스
/// </summary>
public abstract class XpoSqliteBase : IDisposable
{
    protected static readonly Logger nlog = LogManager.GetCurrentClassLogger();
    protected IDataLayer _dataLayer = null!;
    protected string _dbPath = string.Empty;
    private readonly object _initLock = new object();

    public XpoSqliteBase(string dbPath) { _dbPath = dbPath; }

    public virtual void Initialize()
    {
        if (_dataLayer != null) return;
        lock (_initLock)
        {
            if (_dataLayer != null) return;
            try
            {
                string? dbDir = Path.GetDirectoryName(_dbPath);
                if (!string.IsNullOrEmpty(dbDir) && !Directory.Exists(dbDir)) Directory.CreateDirectory(dbDir);

                string connStr = SQLiteConnectionProvider.GetConnectionString(_dbPath);
                XPDictionary dict = new ReflectionDictionary();
                dict.CollectClassInfos(typeof(XpoSignal).Assembly);

                IDataStore store = XpoDefault.GetConnectionProvider(connStr, AutoCreateOption.DatabaseAndSchema);
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
    public virtual void Dispose() { _dataLayer?.Dispose(); }
}
