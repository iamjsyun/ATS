namespace FluentSeq.Validation;

using Extensions;
using FluentValidation;

/// <summary>
/// The sequence configuration validator.
/// </summary>
public sealed class SequenceConfigurationValidator<TState> : AbstractValidator<ISequenceBuilder<TState>> where TState : notnull
{
    /// <summary>
    /// Initializes a new instance of the <see cref="SequenceConfigurationValidator{TState}"/> class.
    /// </summary>
    public SequenceConfigurationValidator()
    {
        ValidatorOptions.Global.LanguageManager.Enabled = false;

        AddRulesForMinimumStateCount();
        AddRulesForInitialState();
        AddRulesForStateTrigger();
        AddRulesForTriggerWhenInStates();
    }

    private void AddRulesForMinimumStateCount() =>
        RuleFor(builder => builder.Builder().RegisteredStates.Count)
            .GreaterThan(1)
            .WithMessage("The sequence must have more than one state.");

    private void AddRulesForInitialState()
    {
        RuleFor(builder => builder.Builder().Options.InitialState).NotNull();

        RuleFor(builder => builder.Builder().Options.InitialState)
            .Must((builder, initialState) => initialState != null && initialState.ToString()?.Length > 0)
            .WithMessage("The InitialState must not be empty.");

        RuleFor(builder => builder.Builder().RegisteredStates)
            .Must((builder, registeredStates) => registeredStates.Contains(builder.Options.InitialState))
            .WithMessage("The InitialState must be configured.");
    }

    private void AddRulesForStateTrigger() =>
        RuleForEach(builder => builder.Builder().RegisteredStates)
            .Must((builder, state) => builder.Builder().NoValidationRequiredFor(state.State) || state.Trigger.Count > 0)
            .WithMessage((_, state) => $"The state {state.State} must have at least one trigger.");

    private void AddRulesForTriggerWhenInStates() =>
        RuleForEach(builder => builder.Builder().StateBuilders
                .SelectMany(x => x.State.Trigger)
                .SelectMany(x => x.WhenInStates)
                .Select(x => x.State).Distinct())
            .Must((builder, state) => builder.Builder().RegisteredStates.Select(x => x.State).Contains(state))
            .OverridePropertyName("MyState")
            .WithMessage((_, state) =>
                $"In a WhenInStates(...)-configuration the State '{state}' is specified, but this State was never configured. " +
                $"Is it a typo or did you forget to configure this State?");
}