namespace FluentSeq.Builder;

using Core;

/// <summary>
/// Provides methods for further describing a trigger
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public interface ITriggerBuilder<TState>: IHasSequenceBuilder<TState>, ICanConfigureState<TState>, ICanConfigureActions<TState>, ICanConfigureTrigger<TState>
    where TState : notnull
{
    /// <summary>
    /// Returns the trigger the builder is for
    /// </summary>
    Trigger<TState> Trigger { get; }


    /// <summary>
    /// Describes what CurrentState the sequence can be for the trigger to be valid.
    /// </summary>
    /// <param name="state">The condition of the current state of the sequence</param>
    ITriggerBuilder<TState> WhenInState(TState state);

    /// <summary>
    /// Describes what CurrentState the sequence must be and for how long for the trigger to be valid.
    /// </summary>
    /// <param name="state">The condition of the current state of the sequence</param>
    /// <param name="dwellTime">For how long the sequence must be in this state before the trigger gets valid</param>
    ITriggerBuilder<TState> WhenInState(TState state, Func<TimeSpan> dwellTime);

    /// <summary>
    /// Describes what CurrentStates the sequence can be for the trigger to be valid.
    /// </summary>
    /// <param name="states">The condition of the current states of the sequence</param>
    ITriggerBuilder<TState> WhenInStates(params TState[] states);

    /// <summary>
    /// Describes what current states the sequence can be in for the trigger to be valid,
    /// based on a prefix match with the state names.
    /// </summary>
    /// <param name="statePrefix">The condition of the current states-prefix of the sequence</param>
    ITriggerBuilder<TState> WhenInStatesStartingWith(string statePrefix);
}
