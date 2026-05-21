using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using ATSA.UI.Models;
using XTA.Core;
using XTA.Models;
using XTA.XData.Interfaces;

namespace ATSA.UI.UCtrls
{
    public class UCXSignalViewModel
    {
        public string ChannelName { get; set; }
        public int CNO { get; set; }
        public ObservableCollection<BindableXSignal> Signals { get; } = new ObservableCollection<BindableXSignal>();

        public UCXSignalViewModel(string channelName, int cno = 0)
        {
            ChannelName = channelName;
            CNO = cno;
        }

        public async Task LoadSignalsAsync()
        {
            var repo = XContext.Instance.GetService<ISignalRepository>();
            if (repo == null) return;

            try
            {
                // Active/Pending 위주로 최신 50개 로드
                var signals = await repo.GetSignalsByCnoAsync(CNO, 50);
                
                System.Windows.Application.Current?.Dispatcher.Invoke(() =>
                {
                    // 최신 데이터로 동기화 (간단하게 Clear 후 Add)
                    // TODO: 성능 최적화가 필요할 경우 Merge 로직 적용
                    Signals.Clear();
                    foreach (var s in signals)
                    {
                        Signals.Add(BindableXSignal.FromModel(XTA.Models.XSignal.FromBase(s)));
                    }
                });
            }
            catch (Exception ex)
            {
                XContext.Instance.Parameter.nlog.Error(ex, $"[UCXSignal:{CNO}] Failed to load signals.");
            }
        }

        public void UpdateSignal(BindableXSignal newSignal)
        {
            var existing = Signals.FirstOrDefault(s => s.sid == newSignal.sid);
            if (existing != null)
            {
                // 기존 신호 업데이트
                int index = Signals.IndexOf(existing);
                Signals[index] = newSignal;
            }
            else
            {
                // 새 신호 상단 추가
                Signals.Insert(0, newSignal);
                if (Signals.Count > 50) Signals.RemoveAt(Signals.Count - 1);
            }
        }

        public void AddMockSignal(string sid, int dir, double lot, double price)
        {
            var mock = new BindableXSignal { 
                sid = sid, 
                symbol = "GOLD#", 
                dir = dir, 
                lot = lot, 
                price_signal = price, 
                updated = DateTime.Now 
            };
            UpdateSignal(mock);
        }
    }
}
