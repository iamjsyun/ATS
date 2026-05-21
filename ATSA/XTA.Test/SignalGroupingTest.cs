using System;
using System.Collections.Generic;
using System.Linq;
using XTA.Models;
using XTA.Services;
using XTA.XData.Models;
using Xunit;

namespace XTA.Test
{
    public class SignalGroupingTest
    {
        [Fact]
        public void Test_Signal_Grouping_Logic()
        {
            // Arrange
            var service = new XSignalService();
            var signals = new List<XTA.Models.XSignal>
            {
                new XTA.Models.XSignal { sid = "1001-26051601-01-00-1-1", gid = "1001-26051601-01-00", cno = 1001, sno = 1, gno = 0, type = XCode.TYPE_MARKET },
                new XTA.Models.XSignal { sid = "1001-26051601-01-01-1-2", gid = "1001-26051601-01-00", cno = 1001, sno = 1, gno = 1, type = XCode.TYPE_LIMIT },
                new XTA.Models.XSignal { sid = "1001-26051601-01-02-1-2", gid = "1001-26051601-01-00", cno = 1001, sno = 1, gno = 2, type = XCode.TYPE_LIMIT },
                new XTA.Models.XSignal { sid = "2001-26051601-02-00-1-1", gid = "2001-26051601-02-00", cno = 2001, sno = 2, gno = 0, type = XCode.TYPE_MARKET }
            };

            // Act
            var grouped = service.GroupSignals(signals);

            // Assert
            Assert.Equal(2, grouped.Count);
            
            var group1 = grouped.First(g => g.GroupGid == "1001-26051601-01-00");
            Assert.Equal(0, group1.MasterSignal.gno);
            Assert.Equal(2, group1.GridSignals.Count);
            Assert.Empty(group1.HedgeSignals);
            Assert.Empty(group1.PendingSignals);

            var group2 = grouped.First(g => g.GroupGid == "2001-26051601-02-00");
            Assert.Equal(0, group2.MasterSignal.gno);
            Assert.Empty(group2.GridSignals);
        }

        [Fact]
        public void Test_Signal_Grouping_Categorization()
        {
            // Arrange
            var service = new XSignalService();
            var signals = new List<XTA.Models.XSignal>
            {
                new XTA.Models.XSignal { sid = "M", gid = "G1", gno = 0, type = XCode.TYPE_MARKET },
                new XTA.Models.XSignal { sid = "G1", gid = "G1", gno = 1, type = XCode.TYPE_LIMIT },
                new XTA.Models.XSignal { sid = "H1", gid = "G1", gno = 5, type = XCode.TYPE_MARKET, xe_status = (int)XCode.EaStatus.Executed },
                new XTA.Models.XSignal { sid = "P1", gid = "G1", gno = 6, type = XCode.TYPE_MARKET, xe_status = (int)XCode.EaStatus.Ready }
            };

            // Act
            var grouped = service.GroupSignals(signals);
            var group = grouped.First();

            // Assert
            Assert.Single(group.GridSignals);
            Assert.Single(group.PendingSignals);
            Assert.Single(group.HedgeSignals);
            Assert.Equal("H1", group.HedgeSignals[0].sid);
            Assert.Equal("P1", group.PendingSignals[0].sid);
        }
    }
}
