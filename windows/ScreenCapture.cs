using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace OcrCopy
{
    public sealed class RegionSelector : Form
    {
        [DllImport("user32.dll")]
        private static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);

        private readonly Bitmap desktop;
        private readonly string prompt;
        private Point anchor;
        private Rectangle selection;
        private bool dragging;

        private RegionSelector(Bitmap desktop, Rectangle bounds, string prompt)
        {
            this.desktop = desktop;
            this.prompt = prompt;
            AutoScaleMode = AutoScaleMode.None;
            FormBorderStyle = FormBorderStyle.None;
            StartPosition = FormStartPosition.Manual;
            Bounds = bounds;
            TopMost = true;
            ShowInTaskbar = false;
            KeyPreview = true;
            DoubleBuffered = true;
            Cursor = Cursors.Cross;
        }

        // Freeze the desktop before showing the overlay; the crop never contains the overlay.
        public static bool SaveSelection(string outputPath, string prompt)
        {
            IntPtr previousDpi = IntPtr.Zero;
            try
            {
                previousDpi = SetThreadDpiAwarenessContext(new IntPtr(-4));
                if (previousDpi == IntPtr.Zero)
                    previousDpi = SetThreadDpiAwarenessContext(new IntPtr(-3));

                Rectangle bounds = SystemInformation.VirtualScreen;
                using (Bitmap desktop = new Bitmap(bounds.Width, bounds.Height, PixelFormat.Format32bppArgb))
                {
                    using (Graphics graphics = Graphics.FromImage(desktop))
                        graphics.CopyFromScreen(bounds.Location, Point.Empty, bounds.Size);

                    using (RegionSelector selector = new RegionSelector(desktop, bounds, prompt))
                    {
                        if (selector.ShowDialog() != DialogResult.OK) return false;
                        using (Bitmap crop = desktop.Clone(selector.selection, PixelFormat.Format32bppArgb))
                            crop.Save(outputPath, ImageFormat.Png);
                    }
                }
                return true;
            }
            finally
            {
                if (previousDpi != IntPtr.Zero) SetThreadDpiAwarenessContext(previousDpi);
            }
        }

        protected override void OnShown(EventArgs e)
        {
            base.OnShown(e);
            Activate();
            Focus();
        }

        protected override void OnKeyDown(KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Escape)
            {
                DialogResult = DialogResult.Cancel;
                Close();
            }
            base.OnKeyDown(e);
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            if (e.Button == MouseButtons.Right)
            {
                DialogResult = DialogResult.Cancel;
                Close();
            }
            if (e.Button != MouseButtons.Left) return;
            anchor = e.Location;
            dragging = true;
            Capture = true;
            selection = Rectangle.Empty;
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            if (!dragging) return;
            int x = Math.Max(0, Math.Min(ClientSize.Width, e.X));
            int y = Math.Max(0, Math.Min(ClientSize.Height, e.Y));
            selection = Rectangle.FromLTRB(Math.Min(anchor.X, x), Math.Min(anchor.Y, y),
                Math.Max(anchor.X, x), Math.Max(anchor.Y, y));
            Invalidate();
        }

        protected override void OnMouseUp(MouseEventArgs e)
        {
            base.OnMouseUp(e);
            if (e.Button != MouseButtons.Left || !dragging) return;
            OnMouseMove(e);
            dragging = false;
            Capture = false;
            if (selection.Width >= 3 && selection.Height >= 3)
            {
                DialogResult = DialogResult.OK;
                Close();
            }
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.DrawImageUnscaled(desktop, 0, 0);
            using (Brush shade = new SolidBrush(Color.FromArgb(100, Color.Black)))
                e.Graphics.FillRectangle(shade, ClientRectangle);
            if (selection.Width > 0 && selection.Height > 0)
            {
                e.Graphics.DrawImage(desktop, selection, selection, GraphicsUnit.Pixel);
                using (Pen border = new Pen(Color.DodgerBlue, 2))
                    e.Graphics.DrawRectangle(border, selection);
            }
            Rectangle primary = Screen.PrimaryScreen.Bounds;
            Point hint = new Point(primary.Left - Left + 20, primary.Top - Top + 20);
            Size size = TextRenderer.MeasureText(prompt, SystemFonts.MessageBoxFont);
            e.Graphics.FillRectangle(Brushes.Black, new Rectangle(hint, size));
            TextRenderer.DrawText(e.Graphics, prompt, SystemFonts.MessageBoxFont, hint, Color.White);
        }
    }
}
