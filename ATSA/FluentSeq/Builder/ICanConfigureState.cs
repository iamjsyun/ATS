namespace FluentSeq.Builder;

/// <summary>
/// Can configure a state
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public interface ICanConfigureState<TState> where TState : notnull
{
    /// <summary>
    /// Creates a new State
    /// </summary>
    /// <param name="state">The name of the state</param>
    /// <param name="description">Optional description of the state</param>
    /// <returns>A StateBuilder</returns>
    IStateBuilder<TState> ConfigureState(TState state, string description = "");
}