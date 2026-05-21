using DevExpress.Mvvm;
using DevExpress.Mvvm.DataAnnotations;
using System;
using System.IO;
using System.Text.Json;
using System.Windows;
using XTA.Core;
using XTA.Models;

namespace ATSA.UI.Settings
{
    public class SettingsViewModel : ViewModelBase
    {
        private string _jsonText = string.Empty;
        public string JsonText
        {
            get => _jsonText;
            set => SetProperty(ref _jsonText, value, nameof(JsonText));
        }

        public SettingsViewModel()
        {
            LoadConfig();
        }

        private void LoadConfig()
        {
            try
            {
                string path = XConfig.GetConfigPath();
                if (File.Exists(path))
                {
                    JsonText = File.ReadAllText(path);
                }
                else
                {
                    JsonText = "// ATSA.json not found.";
                }
            }
            catch (Exception ex)
            {
                JsonText = $"Error loading config: {ex.Message}";
            }
        }

        [Command]
        public void SaveAndApply()
        {
            try
            {
                // 1. Validate & Parse
                var options = new JsonSerializerOptions 
                { 
                    ReadCommentHandling = JsonCommentHandling.Skip,
                    AllowTrailingCommas = true,
                    PropertyNameCaseInsensitive = true 
                };

                var newConfig = JsonSerializer.Deserialize<XConfig>(JsonText, options);
                if (newConfig == null) throw new Exception("Deserialization returned null.");

                // 2. Format & Save to File
                var writeOptions = new JsonSerializerOptions { WriteIndented = true };
                string formattedJson = JsonSerializer.Serialize(newConfig, writeOptions);
                
                string path = XConfig.GetConfigPath();
                File.WriteAllText(path, formattedJson);
                
                // Update UI text with formatted version
                JsonText = formattedJson;

                // 3. Hot-Reload into XParameter
                var parameter = XContext.Instance.Parameter;
                lock (parameter)
                {
                    parameter.Config = newConfig;
                }

                XContext.Instance.Parameter.nlog.Info("[CONFIG:HOT-RELOAD] ATSA.json updated and applied to system.");
                MessageBox.Show("설정이 성공적으로 저장되었으며 시스템에 실시간 반영되었습니다.\n(단, DB 경로나 채널 식별자 변경은 앱 재시작이 필요합니다.)", "저장 완료", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                XContext.Instance.Parameter.nlog.Error(ex, "[CONFIG:ERROR] Failed to save/validate ATSA.json");
                MessageBox.Show($"JSON 검증 실패 또는 저장 에러:\n{ex.Message}", "에러", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        [Command]
        public void Reset()
        {
            if (MessageBox.Show("저장하지 않은 변경 사항이 사라집니다. 다시 로드할까요?", "확인", MessageBoxButton.YesNo) == MessageBoxResult.Yes)
            {
                LoadConfig();
            }
        }
    }
}
