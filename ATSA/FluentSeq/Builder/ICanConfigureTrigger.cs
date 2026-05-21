namespace FluentSeq.Builder;

/// <summary>
/// Provides methods to enhance a state builder with trigger
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public interface ICanConfigureTrigger<TState> where TState : notnull
{
    /// <summary>
    /// The sequence can be forced to this state when the state is triggered by a function
    /// </summary>
    /// <param name="triggeredByFunc">The trigger-function</param>
    ITriggerBuilder<TState> TriggeredBy(Func<bool> triggeredByFunc);

    /// <summary>
    /// The sequence can be forced to this state when the current state of the sequence is the specified state for the specified time
    /// </summary>
    /// <param name="state">The condition of the current state of the sequence</param>
    /// <param name="dwellTime">For how long the sequence must be in this state before the trigger gets valid</param>
    ITriggerBuilder<TState> TriggeredByState(TState state, Func<TimeSpan> dwellTime);
}