using DevExpress.Mvvm;
using System;
using XTA.Models;

namespace ATSA.UI.Models
{
    /// <summary>
    /// XTA.Models.XTgMessage의 UI 바인딩 버전
    /// </summary>
    public class BindableXTgMessage : BindableBase
    {
        private XTgMessage _model;

        public BindableXTgMessage(XTgMessage model)
        {
            _model = model;
        }

        public int Oid { get => _model.Oid; set { if (_model.Oid != value) { _model.Oid = value; RaisePropertyChanged(); } } }
        public long CID { get => _model.CID; set { if (_model.CID != value) { _model.CID = value; RaisePropertyChanged(); } } }
        public DateTime Time { get => _model.Time; set { if (_model.Time != value) { _model.Time = value; RaisePropertyChanged(); } } }
        public int CNO { get => _model.CNO; set { if (_model.CNO != value) { _model.CNO = value; RaisePropertyChanged(); } } }
        public string Text { get => _model.Text; set { if (_model.Text != value) { _model.Text = value; RaisePropertyChanged(); } } }
        public int Status { get => _model.Status; set { if (_model.Status != value) { _model.Status = value; RaisePropertyChanged(); } } }
        public int RetryCount { get => _model.RetryCount; set { if (_model.RetryCount != value) { _model.RetryCount = value; RaisePropertyChanged(); } } }
        public DateTime CreatedAt { get => _model.CreatedAt; set { if (_model.CreatedAt != value) { _model.CreatedAt = value; RaisePropertyChanged(); } } }

        public XTgMessage ToModel() => _model;

        public static BindableXTgMessage FromModel(XTgMessage model) => new BindableXTgMessage(model);
    }
}
