using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;

namespace ATSA.UI.Converters
{
    public class StatusToColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is int status)
            {
                switch (status)
                {
                    case 0: return new SolidColorBrush(Color.FromRgb(158, 158, 158)); // Gray (Ready)
                    case 1: return new SolidColorBrush(Color.FromRgb(33, 150, 243));  // Blue (Pending)
                    case 10: return new SolidColorBrush(Color.FromRgb(76, 175, 80)); // Green (Active/Executed)
                    case 20: 
                    case 21:
                    case 23:
                    case 24: return new SolidColorBrush(Color.FromRgb(117, 117, 117)); // Dark Gray (Closed)
                    case 99: return new SolidColorBrush(Color.FromRgb(244, 67, 54));  // Red (Error)
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
