using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.Wpf;
using System;
using System.IO;
using System.Threading.Tasks;

namespace ATSA.YouTube.Services
{
    public class LiveStreamService : ILiveStreamService
    {
        private readonly WebView2 _webView;

        public LiveStreamService(WebView2 webView)
        {
            _webView = webView;
        }

        public async Task LoadStream(string url)
        {
            if (string.IsNullOrEmpty(url)) return;
            try
            {
                if (_webView.CoreWebView2 == null)
                {
                    await _webView.EnsureCoreWebView2Async();
                }
                _webView.Source = new Uri(url);
            }
            catch { }
        }

        public async Task<MemoryStream?> CaptureSnapshotAsync()
        {
            try
            {
                if (_webView.CoreWebView2 == null)
                {
                    await _webView.EnsureCoreWebView2Async();
                }

                var ms = new MemoryStream();
                await _webView.CoreWebView2!.CapturePreviewAsync(CoreWebView2CapturePreviewImageFormat.Png, ms);
                ms.Position = 0;
                return ms;
            }
            catch
            {
                return null;
            }
        }
    }
}
