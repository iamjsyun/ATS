using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace ATSA.UI.Converters
{
    /// <summary>
    /// [v9.7] xa_entry, xa_exit 인텐트 상태를 색상 배지로 변환하는 컨버터
    /// </summary>
    public class IntentToColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is int intent)
            {
                switch (intent)
                {
                    case 0: return new SolidColorBrush(Color.FromRgb(158, 158, 158)); // Gray (RAW/READY)
                    case 1: return new SolidColorBrush(Color.FromRgb(33, 150, 243));  // Blue (ACTIVE)
                    case 2: return new SolidColorBrush(Color.FromRgb(76, 175, 80));  // Green (COMPLETED)
                    case 3: return new SolidColorBrush(Color.FromRgb(117, 117, 117)); // Dark Gray (ARCHIVE)
                    default: return Brushes.Transparent;
                }
            }
            return Brushes.Transparent;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
