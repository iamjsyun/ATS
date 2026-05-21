namespace FluentSeq.Builder;

/// <summary>
/// Has a SequenceBuilder
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public interface IHasSequenceBuilder<TState> where TState : notnull
{
    /// <summary>
    /// Returns the root SequenceBuilder
    /// </summary>
    ISequenceBuilder<TState> Builder();
}