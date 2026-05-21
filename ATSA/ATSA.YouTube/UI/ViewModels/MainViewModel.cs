using ATSA.YouTube.UI.UCtrls.UCWebView.ViewModels;
using ATSA.YouTube.Models;
using DevExpress.Mvvm;
using System.Collections.ObjectModel;
using System.Linq;
using System.Windows.Input;
using XTA.Core;

namespace ATSA.YouTube.UI.ViewModels
{
    public class MainViewModel : BindableBase
    {
        public ObservableCollection<UCWebViewModel> Channels { get; } = new();

        public object? CurrentView { get; private set; }

        public ICommand SelectChannelCommand { get; }

        public MainViewModel()
        {
            SelectChannelCommand = new DelegateCommand<UCWebViewModel>(OnSelectChannel);

            // [v9.0] XContext의 설정정보에서 YouTube 채널만 필터링하여 로드
            var config = XContext.Instance.Parameter.Config;
            if (config != null)
            {
                var youtubeChannels = config.Channels.Where(c => c.SourceType == "YouTube").ToList();
                foreach (var ch in youtubeChannels)
                {
                    var vm = new UCWebViewModel
                    {
                        ChannelConfig = ch,
                        ChannelName = ch.Name,
                        Url = ch.YouTube?.Url ?? "https://www.youtube.com",
                        CaptureInterval = ch.YouTube?.IntervalMs ?? 3000
                    };

                    // [v9.5] YouTube.ROI CSV 파싱 (X,Y,W,H)
                    string? roiCsv = ch.YouTube?.ROI;
                    
                    if (!string.IsNullOrEmpty(roiCsv))
                    {
                        var parts = roiCsv.Split(',').Select(p => p.Trim()).ToList();
                        if (parts.Count == 4 && 
                            int.TryParse(parts[0], out int x) && int.TryParse(parts[1], out int y) &&
                            int.TryParse(parts[2], out int w) && int.TryParse(parts[3], out int h))
                        {
                            vm.CurrentRoi = new RoiConfig { X = x, Y = y, Width = w, Height = h };
                        }
                    }
                    else
                    {
                        // Fallback
                        vm.CurrentRoi = new RoiConfig { X = 0, Y = 0, Width = 800, Height = 400 };
                    }

                    Channels.Add(vm);
                }
            }

            // 채널이 없을 경우 기본 채널 하나 추가
            if (Channels.Count == 0)
            {
                Channels.Add(new UCWebViewModel { ChannelName = "No Config", Url = "about:blank" });
            }

            CurrentView = Channels[0];
        }

        private void OnSelectChannel(UCWebViewModel channel)
        {
            if (channel != null)
            {
                CurrentView = channel;
            }
        }
    }
}
