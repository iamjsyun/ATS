using DevExpress.Mvvm;
using DevExpress.Mvvm.DataAnnotations;
using System;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using XTA.Models;
using XTA.Infrastructure.Data;
using DevExpress.Xpo;
using XTA.XData.Models;
using DevExpress.Data.Filtering;
using XTA.XData.Services;
using ATSA.UI.Models;

namespace ATSA.UI.UCtrls
{
    public class UCXTGMsgViewModel : ViewModelBase
    {
        private readonly XParameter? _param;
        public int CNO { get; }
        public ObservableCollection<BindableXTgMessage> Messages { get; } = new();

        public UCXTGMsgViewModel(int cno)
        {
            _param = App.Param;
            CNO = cno;

            if (_param != null)
            {
                _ = RefreshFromDbAsync();
            }
        }

        [Command]
        public async Task RefreshFromDbAsync()
        {
            var db = _param?.GetService<XpoSqliteService>();
            if (db == null) return;

            try
            {
                var criteria = CriteriaOperator.Parse("CNO = ?", CNO);
                var sorts = new[] { new SortProperty("Time", DevExpress.Xpo.DB.SortingDirection.Descending) };
                
                var xpoMsgs = await db.GetLayer().FindListAsync<XpoTgMessage>(criteria, sorts);
                
                var domainMsgs = xpoMsgs.Take(100).Select(x => x.ToDomainModel()).ToList();

                System.Windows.Application.Current?.Dispatcher.Invoke(() =>
                {
                    Messages.Clear();
                    foreach (var m in domainMsgs) 
                    {
                        Messages.Add(BindableXTgMessage.FromModel(new XTA.Models.XTgMessage 
                        { 
                            Oid = (int)m.Id,
                            CID = m.CID,
                            Time = m.Time,
                            CNO = m.CNO,
                            Text = m.Text,
                            Status = m.Status
                        }));
                    }
                });
            }
            catch (Exception ex)
            {
                _param?.nlog.Error(ex, $"[UCXTGMsgViewModel] Refresh Error for CNO {CNO}");
            }
        }
    }
}
