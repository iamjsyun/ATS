using DevExpress.Mvvm;
using System;
using System.ComponentModel;
using XTA.Models;
using XTA.XData.Models;

namespace ATSA.UI.Models
{
    /// <summary>
    /// XTA.Models.XSignal을 상속받아 UI 바인딩 기능을 추가한 확장 클래스
    /// </summary>
    public class BindableXSignal : XTA.Models.XSignal, INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler? PropertyChanged;

        protected void RaisePropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
        }

        public void RefreshAll()
        {
            // WPF standard for "all properties changed" is null or empty string
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(string.Empty));
        }

        // --- SID Decomposition & Composition ---
        private string _yymmddhh = string.Empty;
        public string yymmddhh 
        { 
            get => _yymmddhh; 
            set { if (_yymmddhh != value) { _yymmddhh = value; UpdateSid(); RaisePropertyChanged(nameof(yymmddhh)); } } 
        }

        public new int cno { get => base.cno; set { if (base.cno != value) { base.cno = value; UpdateSid(); RaisePropertyChanged(nameof(cno)); } } }
        public new int sno { get => base.sno; set { if (base.sno != value) { base.sno = value; UpdateSid(); RaisePropertyChanged(nameof(sno)); } } }
        public new int gno { get => base.gno; set { if (base.gno != value) { base.gno = value; UpdateSid(); RaisePropertyChanged(nameof(gno)); } } }

        private void UpdateSid()
        {
            sid = XIdManager.Instance.GenerateSid(base.cno, DateTime.Now, base.sno, base.gno, base.dir, base.type);
            gid = XIdManager.Instance.GenerateGid(base.cno, DateTime.Now, base.sno, base.gno);
            
            RaisePropertyChanged(nameof(sid));
            RaisePropertyChanged(nameof(gid));
        }

        public void ParseSid()
        {
            if (string.IsNullOrEmpty(sid) || !XIdManager.Instance.IsValidSid(sid)) return;

            var parts = sid.Split('-');
            if (parts.Length < 6) return;
            
            try
            {
                base.cno = int.Parse(parts[0]);
                _yymmddhh = parts[1];
                base.sno = int.Parse(parts[2]);
                base.gno = int.Parse(parts[3]);
                base.dir = int.Parse(parts[4]);
                base.type = int.Parse(parts[5]);
                
                RefreshAll();
            }
            catch { }
        }

        // --- Trading Parameters (String Mappings for ComboBox) ---
        public new string symbol { get => base.symbol; set { if (base.symbol != value) { base.symbol = value; RaisePropertyChanged(nameof(symbol)); } } }

        public new int dir { get => base.dir; set { if (base.dir != value) { base.dir = value; UpdateSid(); RaisePropertyChanged(nameof(dir)); RaisePropertyChanged(nameof(SelectedDir)); } } }
        public string SelectedDir 
        { 
            get => base.dir switch { 1 => "1:BUY", 2 => "2:SELL", _ => $"{base.dir}:UNK" };
            set { if (!string.IsNullOrEmpty(value) && int.TryParse(value.Split(':')[0], out int d)) { this.dir = d; } } 
        }

        public new int type { get => base.type; set { if (base.type != value) { base.type = value; UpdateSid(); RaisePropertyChanged(nameof(type)); RaisePropertyChanged(nameof(SelectedType)); } } }
        public string SelectedType 
        { 
            get => base.type switch { 1 => "1:TRL", 2 => "2:LIMIT", 3 => "3:STOP", 9 => "9:MARKET", _ => $"{base.type}:UNK" };
            set { if (!string.IsNullOrEmpty(value) && int.TryParse(value.Split(':')[0], out int t)) { this.type = t; } }
        }

        public int lot_type { get; set; } = 1; // Default: Fixed Lot
        public string SelectedLotType 
        { 
            get => lot_type switch { 1 => "1:FIXED", 2 => "2:MULT", _ => $"{lot_type}:UNK" };
            set { if (!string.IsNullOrEmpty(value) && int.TryParse(value.Split(':')[0], out int v)) { lot_type = v; RaisePropertyChanged(nameof(lot_type)); RaisePropertyChanged(nameof(SelectedLotType)); } } 
        }

        public new double price_signal { get => base.price_signal; set { if (base.price_signal != value) { base.price_signal = value; RaisePropertyChanged(nameof(price_signal)); } } }
        public new double lot { get => base.lot; set { if (base.lot != value) { base.lot = value; RaisePropertyChanged(nameof(lot)); } } }

        // --- Status ComboBox Mappings ---
        public new int xa_entry { get => base.xa_entry; set { if (base.xa_entry != value) { base.xa_entry = value; RaisePropertyChanged(nameof(xa_entry)); RaisePropertyChanged(nameof(SelectedXAEntry)); } } }
        public string SelectedXAEntry
        {
            get => base.xa_entry switch { 0 => "0:RAW", 1 => "1:ACTIVE", _ => $"{base.xa_entry}:UNK" };
            set { if (!string.IsNullOrEmpty(value) && int.TryParse(value.Split(':')[0], out int v)) { this.xa_entry = v; } }
        }

        public new int xa_exit { get => base.xa_exit; set { if (base.xa_exit != value) { base.xa_exit = value; RaisePropertyChanged(nameof(xa_exit)); RaisePropertyChanged(nameof(SelectedXAExit)); } } }
        public string SelectedXAExit
        {
            get => base.xa_exit switch { 0 => "0:READY", 1 => "1:ACTIVE", 2 => "2:COMP", 3 => "3:ARCHIVE", _ => $"{base.xa_exit}:UNK" };
            set { if (!string.IsNullOrEmpty(value) && int.TryParse(value.Split(':')[0], out int v)) { this.xa_exit = v; } }
        }

        public new int xe_status { get => base.xe_status; set { if (base.xe_status != value) { base.xe_status = value; RaisePropertyChanged(nameof(xe_status)); RaisePropertyChanged(nameof(SelectedXEStatus)); } } }
        public string SelectedXEStatus
        {
            get => (XCode.EaStatus)base.xe_status switch { 
                XCode.EaStatus.Ready => "0:READY", 
                XCode.EaStatus.PendingReq => "1:PENDING_REQ", 
                XCode.EaStatus.InTransit => "2:IN_TRANSIT", 
                XCode.EaStatus.PendingPlaced => "5:PENDING_PLACED", 
                XCode.EaStatus.Executed => "10:EXECUTED", 
                XCode.EaStatus.Closed_Signal => "20:CLOSED_SIG", 
                XCode.EaStatus.Closed_SL => "21:CLOSED_SL", 
                XCode.EaStatus.Closed_TP => "22:CLOSED_TP", 
                XCode.EaStatus.Closed_Manual => "24:CLOSED_MANUAL", 
                XCode.EaStatus.Error => "99:ERROR", 
                _ => $"{base.xe_status}:UNK" 
            };
            set { if (!string.IsNullOrEmpty(value) && int.TryParse(value.Split(':')[0], out int v)) { this.xe_status = v; } }
        }

        public new double te_start { get => base.te_start; set { if (base.te_start != value) { base.te_start = value; RaisePropertyChanged(nameof(te_start)); } } }
        public new double te_limit { get => base.te_limit; set { if (base.te_limit != value) { base.te_limit = value; RaisePropertyChanged(nameof(te_limit)); } } }
        public new double te_step { get => base.te_step; set { if (base.te_step != value) { base.te_step = value; RaisePropertyChanged(nameof(te_step)); } } }
        public new int ts_start { get => base.ts_start; set { if (base.ts_start != value) { base.ts_start = value; RaisePropertyChanged(nameof(ts_start)); } } }
        public new int ts_step { get => base.ts_step; set { if (base.ts_step != value) { base.ts_step = value; RaisePropertyChanged(nameof(ts_step)); } } }
        public new double sl { get => base.sl; set { if (base.sl != value) { base.sl = value; RaisePropertyChanged(nameof(sl)); } } }
        public new double tp { get => base.tp; set { if (base.tp != value) { base.tp = value; RaisePropertyChanged(nameof(tp)); } } }

        // --- Status & UI ---
        public new string xe_status_msg { get => base.xe_status_msg; set { if (base.xe_status_msg != value) { base.xe_status_msg = value; RaisePropertyChanged(nameof(xe_status_msg)); } } }
        public new double price { get => base.price; set { if (base.price != value) { base.price = value; RaisePropertyChanged(nameof(price)); } } }
        
        private bool _isHighlight;
        public new bool isHighlight { get => _isHighlight; set { if (_isHighlight != value) { _isHighlight = value; RaisePropertyChanged(nameof(isHighlight)); } } }

        private bool _isSelected;
        public bool IsSelected { get => _isSelected; set { if (_isSelected != value) { _isSelected = value; RaisePropertyChanged(nameof(IsSelected)); } } }

        private string _generatedMessage = string.Empty;
        public string GeneratedMessage
        {
            get => _generatedMessage;
            set { if (_generatedMessage != value) { _generatedMessage = value; RaisePropertyChanged(nameof(GeneratedMessage)); } }
        }

        public static BindableXSignal FromModel(XTA.Models.XSignal model)
        {
            var bindable = new BindableXSignal();
            XTA.Models.XSignal.UpdateFromBase(bindable, model);
            bindable.ParseSid();
            return bindable;
        }
    }
}
