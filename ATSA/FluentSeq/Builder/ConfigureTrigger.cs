namespace FluentSeq.Builder;

/// <summary>
/// A helper class for configuring trigger on a state
/// </summary>
/// <typeparam name="TState"></typeparam>
public class ConfigureTrigger<TState>(IStateBuilder<TState> stateBuilder)
    : ICanConfigureTrigger<TState> where TState : notnull
{

    /// <inheritdoc />
    public ITriggerBuilder<TState> TriggeredBy(Func<bool> triggeredByFunc)
    {
        var triggerBuilder = new TriggerBuilder<TState>(stateBuilder, triggeredByFunc);
        stateBuilder.State.Trigger.Add(triggerBuilder.Trigger);

        return triggerBuilder;
    }

    /// <inheritdoc />
    public ITriggerBuilder<TState> TriggeredByState(TState state, Func<TimeSpan> dwellTime)
    {
        var triggerBuilder = new TriggerBuilder<TState>(stateBuilder, () => true);
        triggerBuilder.WhenInState(state, dwellTime);
        stateBuilder.State.Trigger.Add(triggerBuilder.Trigger);

        return triggerBuilder;
    }
}