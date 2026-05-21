namespace FluentSeq.Builder;

/// <summary>
/// Provides methods to enhance a state builder with actions
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public interface ICanConfigureActions<TState> where TState : notnull
{
    /// <summary>
    /// Adds an action to be executed when the state is exited.
    /// Multiple actions can be chained and will be executed in the order they are defined.
    /// </summary>
    /// <param name="action">The action to be executed</param>
    IStateBuilder<TState> OnExit(Action action);

    /// <summary>
    /// Adds an action to be executed when the state is entered.
    /// Multiple actions can be chained and will be executed in the order they are defined.
    /// </summary>
    /// <param name="action">The action to be executed</param>
    IStateBuilder<TState> OnEntry(Action action);

    /// <summary>
    /// Adds an action to be executed repeatedly while the sequence's current state is this state.
    /// Multiple actions can be chained and will be executed in the order they are defined.
    /// </summary>
    /// <param name="action">The action to be executed</param>
    IStateBuilder<TState> WhileInState(Action action);
}