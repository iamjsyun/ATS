using DevExpress.Mvvm;
using System.Windows.Input;

namespace ATSA.UI.Main
{
    public class MainViewModel : ViewModelBase
    {
        private object _currentView = null!;
        public object CurrentView
        {
            get => _currentView;
            set => SetProperty(ref _currentView, value, nameof(CurrentView));
        }

        public ICommand ShowDashboardCommand { get; }
        public ICommand ShowDataManagerCommand { get; }
        public ICommand ShowSettingsCommand { get; }

        public MainViewModel()
        {
            ShowSettingsCommand = new DelegateCommand(() =>
            {
                CurrentView = new Settings.SettingsViewModel();
            });

            ShowDashboardCommand = new DelegateCommand(() => 
            {
                System.Diagnostics.Debug.WriteLine("[MainVM] ShowDashboardCommand executed.");
                CurrentView = new Dashboard.DashboardViewModel();
            });

            ShowDataManagerCommand = new DelegateCommand(() => 
            {
                System.Diagnostics.Debug.WriteLine("[MainVM] ShowDataManagerCommand executed.");
                try 
                {
                    var viewModel = new DataManager.DataManagerViewModel(null);
                    System.Diagnostics.Debug.WriteLine("[MainVM] DataManagerViewModel created successfully.");
                    CurrentView = viewModel;
                    System.Diagnostics.Debug.WriteLine("[MainVM] CurrentView updated to DataManagerViewModel.");
                }
                catch (System.Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine($"[MainVM] Error creating DataManagerViewModel: {ex}");
                    System.Windows.MessageBox.Show($"DataManager 화면 전환 실패:\n{ex.Message}\n\n{ex.StackTrace}", "Error", System.Windows.MessageBoxButton.OK, System.Windows.MessageBoxImage.Error);
                    try {
                        XTA.Core.XContext.Instance.Parameter.nlog.Error(ex, "[MainVM] Failed to switch to DataManagerView.");
                    } catch { /* nlog might not be ready */ }
                }
            });

            // 초기 화면: 대시보드
            CurrentView = new Dashboard.DashboardViewModel();
        }
    }
}
