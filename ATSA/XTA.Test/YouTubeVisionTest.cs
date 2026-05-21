using System;
using System.Collections.Generic;
using System.Linq;
using Xunit;
using XTA.Channels.YouTubeVision;
using XTA.Models;
using XTA.XData.Models;
using XTA.Core;

namespace XTA.Test
{
    public class YouTubeVisionTest
    {
        private readonly XParameter _param;

        public YouTubeVisionTest()
        {
            _param = new XParameter();
        }

        [Fact]
        public void TC_YV_01_Interpret_Basic_Buy()
        {
            // Arrange
            var info = new XChannelInfo(0, 2001, "YouTube_CH1", "TRADE");
            var interpreter = new YouTubeVision(_param, info);
            
            var xdo = new XDataObject
            {
                CNO = 2001,
                Text = "SIGNAL: BUY ENTRY AT 2345.67 LOT: 0.1 SNO: 1",
                Timestamp = DateTime.Now,
                MsgId = 123
            };

            // Act
            var signals = interpreter.Interpret(xdo);

            // Assert
            Assert.NotEmpty(signals);
            var s = signals[0];
            Assert.Equal(XCode.BUY, s.dir);
            Assert.Equal(2345.67, s.price_signal);
            Assert.Equal(0.1, s.lot);
            Assert.Equal(1, s.sno);
            Assert.Equal(XCode.XA_ACTIVE, s.xa_entry);
        }

        [Fact]
        public void TC_YV_02_Interpret_Basic_Sell()
        {
            // Arrange
            var info = new XChannelInfo(0, 2001, "YouTube_CH1", "TRADE");
            var interpreter = new YouTubeVision(_param, info);
            
            var xdo = new XDataObject
            {
                CNO = 2001,
                Text = "SELL AT 2350.00 VOL: 0.05 REV: 2",
                Timestamp = DateTime.Now,
                MsgId = 124
            };

            // Act
            var signals = interpreter.Interpret(xdo);

            // Assert
            Assert.NotEmpty(signals);
            var s = signals[0];
            Assert.Equal(XCode.SELL, s.dir);
            Assert.Equal(2350.00, s.price_signal);
            Assert.Equal(0.05, s.lot);
            Assert.Equal(2, s.sno);
        }

        [Fact]
        public void TC_YV_03_Interpret_Close()
        {
            // Arrange
            var info = new XChannelInfo(0, 2001, "YouTube_CH1", "TRADE");
            var interpreter = new YouTubeVision(_param, info);
            
            var xdo = new XDataObject
            {
                CNO = 2001,
                Text = "EXIT CLOSE TP SL 2340.00 15차",
                Timestamp = DateTime.Now,
                MsgId = 125
            };

            // Act
            var signals = interpreter.Interpret(xdo);

            // Assert
            Assert.NotEmpty(signals);
            var s = signals[0];
            Assert.Equal(XCode.CLOSE, s.cmd);
            Assert.Equal(15, s.sno);
            Assert.Equal(XCode.XA_ACTIVE, s.xa_exit);
        }
    }
}
