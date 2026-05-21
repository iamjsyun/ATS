using DevExpress.Mvvm;
using System.ComponentModel;

namespace ATSA.UI.Models
{
    public class XChannelStatus : BindableBase
    {
        public int CNO { get; set; }
        public string Name { get; set; } = "";

        // BUY Stats
        public int BuyOrderCount { get; set; }
        public double BuyOrderLot { get; set; }
        public int BuyPositionCount { get; set; }
        public double BuyPositionLot { get; set; }
        public double BuyTotalLot => BuyOrderLot + BuyPositionLot;

        // SELL Stats
        public int SellOrderCount { get; set; }
        public double SellOrderLot { get; set; }
        public int SellPositionCount { get; set; }
        public double SellPositionLot { get; set; }
        public double SellTotalLot => SellOrderLot + SellPositionLot;

        public int TotalBuyCount => BuyOrderCount + BuyPositionCount;
        public int TotalSellCount => SellOrderCount + SellPositionCount;
        public int TotalAllCount => TotalBuyCount + TotalSellCount;

        public void RefreshAll() => RaisePropertiesChanged();
    }
}
