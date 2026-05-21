using System.Drawing;

namespace ATSA.YouTube.Models
{
    public class RoiConfig
    {
        public int X { get; set; } = 0;
        public int Y { get; set; } = 0;
        public int Width { get; set; } = 400;
        public int Height { get; set; } = 200;

        public Rectangle ToRectangle() => new Rectangle(X, Y, Width, Height);
    }
}
