using System.IO;
using System.Threading.Tasks;

namespace ATSA.YouTube.Services
{
    public interface ILiveStreamService
    {
        Task LoadStream(string url);
        Task<MemoryStream?> CaptureSnapshotAsync();
    }
}
