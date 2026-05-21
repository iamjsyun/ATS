namespace FluentSeq.Core;

/// <summary>
/// The trigger condition
/// </summary>
/// <typeparam name="TState">The state</typeparam>
public class TriggerCondition<TState>(TState state, Func<TimeSpan>? dwellTime = null) where TState : notnull
{
    /// <summary>
    /// The state
    /// </summary>
    public TState State { get; } = state;

    /// <summary>
    /// The sequence must be in the state for this specified time before the trigger is activated
    /// </summary>
    public Func<TimeSpan>? DwellTime { get; } = dwellTime;


    /// <summary>
    /// The Sequence triggers the trigger (current state and dwellTime)
    /// </summary>
    /// <param name="sequence">The sequence</param>
    /// <returns>Returns true when all trigger conditions are fulfilled</returns>
    public bool IsTriggered(ISequence<TState> sequence)
    {
        var result = sequence.CurrentState?.Equals(State) ?? false;

        return !result || DwellTime is null
            ? result
            : sequence.CurrentStateElapsed(DwellTime());
    }
}