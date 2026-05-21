namespace FluentSeq.Builder;

using Core;

/// <summary>
/// Provides methods for further describing a state
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public interface IStateBuilder<TState>: IHasSequenceBuilder<TState>, ICanConfigureState<TState>, ICanConfigureActions<TState>, ICanConfigureTrigger<TState>
    where TState : notnull
{
    /// <summary>
    /// The state that the builder should parameterize
    /// </summary>
    SeqState<TState> State { get; }

    /// <summary>
    /// The root state builder
    /// </summary>
    StateBuilder<TState> RootStateBuilder { get; }
}