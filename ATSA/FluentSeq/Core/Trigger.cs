namespace FluentSeq.Core;

using Builder;

/// <summary>
/// Describes a trigger, how a state can be set as current state
/// </summary>
/// <typeparam name="TState"></typeparam>
public class Trigger<TState> where TState : notnull
{
    // private readonly IStateBuilder<TState> _stateBuilder;

    /// <summary>
    /// Initializes a new instance of the <see cref="Trigger{TState}"/> class.
    /// </summary>
    /// <param name="stateBuilder">The root of this trigger builder</param>
    /// <param name="triggeredByFunc">The function that triggers the state change</param>
    public Trigger(IStateBuilder<TState> stateBuilder, Func<bool> triggeredByFunc)
    {
        // _stateBuilder   = stateBuilder;
        TriggeredByFunc = triggeredByFunc;
    }


    /// <summary>
    /// Gets the function that triggers the state change
    /// </summary>
    public Func<bool> TriggeredByFunc { get; }

    /// <summary>
    /// Gets a list of states in which the sequence can be for the trigger to be valid.
    /// </summary>
    public List<TriggerCondition<TState>> WhenInStates { get; } = new();

    /// <summary>
    /// The Sequence triggers the trigger (current state...)
    /// </summary>
    /// <param name="sequence">The sequence</param>
    /// <returns>Returns true when all trigger conditions are fulfilled</returns>
    public bool IsTriggered(ISequence<TState> sequence)
    {
        var result = TriggeredByFunc();

        return !result || WhenInStates.Count == 0
            ? result
            : WhenInStates.Any(x => x.IsTriggered(sequence));
    }
}