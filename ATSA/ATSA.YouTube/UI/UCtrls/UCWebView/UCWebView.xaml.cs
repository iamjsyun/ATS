using System.Windows.Controls;
using ATSA.YouTube.UI.UCtrls.UCWebView.ViewModels;
using ATSA.YouTube.Services;
using XTA.Models;
using XTA.Core;
using System.Windows;

namespace ATSA.YouTube.UI.UCtrls.UCWebView
{
    public partial class UCWebView : UserControl
    {
        public UCWebView()
        {
            InitializeComponent();
            this.Loaded += UCWebView_Loaded;
        }

        private void UCWebView_Loaded(object sender, RoutedEventArgs e)
        {
            if (this.DataContext is UCWebViewModel vm)
            {
                // [v9.0] UI 컨트롤 의존 서비스는 직접 생성, 로직 서비스는 XContext에서 획득
                var streamSvc = new LiveStreamService(this.WebView);
                var ocrSvc = XContext.Instance.GetService<IOcrEngineService>();
                
                if (ocrSvc != null)
                {
                    vm.SetServices(streamSvc, ocrSvc);
                }
            }
        }
    }
}
