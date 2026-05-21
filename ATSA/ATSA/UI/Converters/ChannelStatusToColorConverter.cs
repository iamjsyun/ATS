using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;
using ATSA.UI.Models;

namespace ATSA.UI.Converters
{
    public class ChannelStatusToColorConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            if (value is XChannelStatus status)
            {
                if (status.TotalAllCount == 0)
                    return Brushes.White;

                if (status.TotalBuyCount > status.TotalSellCount)
                    return new SolidColorBrush(Color.FromRgb(232, 244, 255)); // Very light blue
                
                if (status.TotalSellCount > status.TotalBuyCount)
                    return new SolidColorBrush(Color.FromRgb(255, 240, 240)); // Very light red
                
                // Equal but > 0
                return new SolidColorBrush(Color.FromRgb(245, 245, 245)); // Light gray
            }

            return Brushes.White;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
