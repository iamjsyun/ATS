using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using XTA.Models;

namespace ATSA.UI.Models
{
    /// <summary>
    /// XTA.XSignalGroup을 UI용으로 확장한 클래스 (아코디언 제어용)
    /// </summary>
    public class BindableSignalGroup : INotifyPropertyChanged
    {
        public event PropertyChangedEventHandler? PropertyChanged;
        protected virtual void OnPropertyChanged([CallerMemberName] string? propertyName = null) => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));

        private XSignalGroup _coreGroup;
        public XSignalGroup CoreGroup => _coreGroup;

        private BindableXSignal _masterSignal;
        public BindableXSignal MasterSignal
        {
            get => _masterSignal;
            set { _masterSignal = value; OnPropertyChanged(); }
        }

        public ObservableCollection<BindableXSignal> GridSignals { get; } = new ObservableCollection<BindableXSignal>();
        public ObservableCollection<BindableXSignal> HedgeSignals { get; } = new ObservableCollection<BindableXSignal>();
        public ObservableCollection<BindableXSignal> PendingSignals { get; } = new ObservableCollection<BindableXSignal>();

        private bool _isExpanded = true;
        public bool IsExpanded
        {
            get => _isExpanded;
            set { _isExpanded = value; OnPropertyChanged(); }
        }

        public string GroupGid => _coreGroup.GroupGid;

        public BindableSignalGroup(XSignalGroup coreGroup)
        {
            _coreGroup = coreGroup;
            _masterSignal = BindableXSignal.FromModel(coreGroup.MasterSignal);
            
            foreach (var s in coreGroup.GridSignals) GridSignals.Add(BindableXSignal.FromModel(s));
            foreach (var s in coreGroup.HedgeSignals) HedgeSignals.Add(BindableXSignal.FromModel(s));
            foreach (var s in coreGroup.PendingSignals) PendingSignals.Add(BindableXSignal.FromModel(s));
        }
    }
}
