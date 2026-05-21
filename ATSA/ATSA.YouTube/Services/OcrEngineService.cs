using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Threading.Tasks;
using System.Runtime.InteropServices.WindowsRuntime;
using Windows.Graphics.Imaging;
using Windows.Media.Ocr;
using Windows.Storage.Streams;
using ATSA.YouTube.Models;
using XTA.Models;

/*
using Tesseract;
*/

namespace ATSA.YouTube.Services
{
    public class OcrEngineService : IOcrEngineService
    {
        private readonly OcrEngine _engine;
        private readonly XOcrSettings _settings;

        /*
        private readonly TesseractEngine _tessEngine;
        */

        public OcrEngineService(XOcrSettings settings)
        {
            _settings = settings;

            // Windows.Media.Ocr 초기화
            _engine = OcrEngine.TryCreateFromLanguage(new Windows.Globalization.Language(_settings.Language));
            if (_engine == null)
            {
                // 지원되지 않는 언어일 경우 기본 언어(en-US) 시도
                _engine = OcrEngine.TryCreateFromLanguage(new Windows.Globalization.Language("en-US"));
            }

            /*
            // Tesseract 초기화 (주석 처리)
            if (!Directory.Exists(_settings.DataPath)) Directory.CreateDirectory(_settings.DataPath);
            _tessEngine = new TesseractEngine(_settings.DataPath, _settings.Language, EngineMode.Default);
            if (!string.IsNullOrEmpty(_settings.Whitelist)) _tessEngine.SetVariable("tessedit_char_whitelist", _settings.Whitelist);
            */
        }

        public async Task<string> ExtractTextAsync(MemoryStream stream, RoiConfig roi)
        {
            try
            {
                stream.Position = 0;
                using (var bitmap = new Bitmap(stream))
                {
                    // ROI 영역 유효성 검사 및 보정
                    int x = Math.Max(0, Math.Min(roi.X, bitmap.Width - 1));
                    int y = Math.Max(0, Math.Min(roi.Y, bitmap.Height - 1));
                    int width = Math.Min(roi.Width, bitmap.Width - x);
                    int height = Math.Min(roi.Height, bitmap.Height - y);

                    if (width <= 0 || height <= 0) return string.Empty;

                    using (var roiBitmap = bitmap.Clone(new Rectangle(x, y, width, height), bitmap.PixelFormat))
                    {
                        // [Windows.Media.Ocr 방식]
                        using (var ms = new MemoryStream())
                        {
                            roiBitmap.Save(ms, ImageFormat.Bmp);
                            ms.Position = 0;
                            
                            var decoder = await BitmapDecoder.CreateAsync(ms.AsRandomAccessStream());
                            var softwareBitmap = await decoder.GetSoftwareBitmapAsync();
                            
                            var result = await _engine.RecognizeAsync(softwareBitmap);
                            return result.Text?.Trim() ?? string.Empty;
                        }

                        /*
                        // [Tesseract 방식 - 주석 처리]
                        using (var img = PixConverter.ToPix(roiBitmap))
                        {
                            using (var page = _tessEngine.Process(img, (PageSegMode)_settings.PageSegMode))
                            {
                                return page.GetText()?.Trim() ?? string.Empty;
                            }
                        }
                        */
                    }
                }
            }
            catch
            {
                return string.Empty;
            }
        }
    }
}
