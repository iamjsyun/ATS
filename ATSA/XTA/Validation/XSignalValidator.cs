using FluentValidation;
using XTA.XData.Models;

namespace XTA.Validation
{
    public class XSignalValidator : AbstractValidator<XSignal>
    {
        public XSignalValidator()
        {
            // 공통 필수값
            RuleFor(x => x.cno).GreaterThan(0).WithMessage("CNO는 필수입니다.");
            RuleFor(x => x.symbol).NotEmpty().WithMessage("심볼은 필수입니다.");

            // [청산 상태 검증] xa_exit가 활성화된 경우
            When(x => x.xa_exit > 0, () =>
            {
                RuleFor(x => x.sno).GreaterThanOrEqualTo(0).WithMessage("청산 시 SNO 정보는 필수입니다.");
                RuleFor(x => x.sid).NotEmpty().WithMessage("청산 시 SID는 필수입니다.");
            });

            // [진입 상태 검증] xa_entry가 활성화된 경우
            When(x => x.xa_entry > 0, () =>
            {
                RuleFor(x => x.price_signal).GreaterThan(0).WithMessage("진입 신호 가격은 0보다 커야 합니다.");
                RuleFor(x => x.lot).GreaterThan(0).WithMessage("랏은 0보다 커야 합니다.");
                RuleFor(x => x.dir).Must(d => d == 1 || d == 2).WithMessage("방향은 1(BUY) 또는 2(SELL)여야 합니다.");
            });
        }
    }
}
