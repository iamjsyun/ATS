using System.Collections.Generic;
using System.Threading.Tasks;
using XTA.XData.Models;

namespace XTA.XData.Interfaces
{
    public interface ISignalRepository
    {
        string DbPath { get; }
        Task<XSignal?> GetSignalBySidAsync(string sid);
        Task<List<XSignal>> GetSignalsByCnoAsync(int cno, int count = 500);
        Task SaveSignalAsync(XSignal signal);
        Task SaveSignalImmediateAsync(XSignal signal, bool force = false);
        Task UpdateSignalStatusAsync(string sid, int xeStatus, string xeStatusMsg);
        Task UpdateXaStatusAsync(string sid, int xaStatus);
        Task UpdateXaEntryAsync(string sid, int xaEntry);
        Task<int> SaveRawSignalAsync(XSignal signal, string rawText);
        Task DeleteSignalAsync(string sid);
        Task DeleteAllSignalsAsync();
        Task<List<XSignal>> GetAllActiveSignalsAsync();
        Task<List<XSignal>> FindActiveSignalsBySnoAsync(int cno, int sno);
        Task<XSignal?> FindAnySignalBySnoAsync(int cno, int sno);
        Task<List<XSignal>> GetClosedSignalsAsync();
        Task<List<XSignal>> GetErrorSignalsAsync();
        }

    public interface IChannelOptionRepository
    {
        Task<XChannelOption?> GetOptionAsync(int cno);
        Task SaveOptionAsync(XChannelOption option);
        Task<List<XChannelOption>> GetAllOptionsAsync();
    }

    public interface IGridProfileRepository
    {
        Task<XGridProfile?> GetGridProfileAsync(int cno, int dir, int gno);
        Task<List<XGridProfile>> GetGridProfilesAsync(int cno, int dir);
        Task SaveGridProfileAsync(XGridProfile profile);
    }
}
