using System.Windows;

namespace ATSA.UI.Services
{
    public interface IDialogService
    {
        void ShowInfo(string message, string title = "Information");
        void ShowError(string message, string title = "Error");
        bool Confirm(string message, string title = "Confirm");
        string? Prompt(string message, string title = "Input Required");
    }

    public class DefaultDialogService : IDialogService
    {
        public void ShowInfo(string message, string title = "Information")
        {
            MessageBox.Show(message, title, MessageBoxButton.OK, MessageBoxImage.Information);
        }

        public void ShowError(string message, string title = "Error")
        {
            MessageBox.Show(message, title, MessageBoxButton.OK, MessageBoxImage.Error);
        }

        public bool Confirm(string message, string title = "Confirm")
        {
            return MessageBox.Show(message, title, MessageBoxButton.YesNo, MessageBoxImage.Question) == MessageBoxResult.Yes;
        }

        public string? Prompt(string message, string title = "Input Required")
        {
            string? result = null;
            var window = new Window
            {
                Title = title,
                Width = 400,
                Height = 150,
                WindowStartupLocation = WindowStartupLocation.CenterScreen,
                ResizeMode = ResizeMode.NoResize,
                Topmost = true,
                Content = new System.Windows.Controls.StackPanel
                {
                    Margin = new Thickness(20),
                    Children =
                    {
                        new System.Windows.Controls.TextBlock { Text = message, Margin = new Thickness(0, 0, 0, 10) },
                        new System.Windows.Controls.TextBox { Name = "InputTextBox" },
                        new System.Windows.Controls.Button
                        {
                            Content = "OK",
                            IsDefault = true,
                            Margin = new Thickness(0, 10, 0, 0),
                            Width = 80,
                            HorizontalAlignment = HorizontalAlignment.Right
                        }
                    }
                }
            };

            var stackPanel = (System.Windows.Controls.StackPanel)window.Content;
            var textBox = (System.Windows.Controls.TextBox)stackPanel.Children[1];
            var button = (System.Windows.Controls.Button)stackPanel.Children[2];

            button.Click += (s, e) =>
            {
                result = textBox.Text;
                window.DialogResult = true;
                window.Close();
            };

            window.ShowDialog();
            return result;
        }
    }
}
