namespace FluentSeq.Builder;

/// <summary>
/// A helper class for configuring actions on a state
/// </summary>
/// <typeparam name="TState">The state type</typeparam>
public class ConfigureActions<TState>(IStateBuilder<TState> stateBuilder) : ICanConfigureActions<TState> where TState : notnull
    
{
    /// <inheritdoc />
    public IStateBuilder<TState> OnExit(Action action)
    {
        stateBuilder.State.ExitActions.Add(action);
        return stateBuilder;
    }

    /// <inheritdoc />
    public IStateBuilder<TState> OnEntry(Action action)
    {
        stateBuilder.State.EntryActions.Add(action);
        return stateBuilder;
    }

    /// <inheritdoc />
    public IStateBuilder<TState> WhileInState(Action action)
    {
        stateBuilder.State.WhileInStateActions.Add(action);
        return stateBuilder;
    }
}