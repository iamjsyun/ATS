using System.IO;
using System.Threading.Tasks;
using ATSA.YouTube.Models;

namespace ATSA.YouTube.Services
{
    public interface IOcrEngineService
    {
        Task<string> ExtractTextAsync(MemoryStream stream, RoiConfig roi);
    }
}
