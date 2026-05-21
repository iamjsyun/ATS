namespace FluentSeq.Core;

/// <summary>
/// A collection of sequence states
/// </summary>
/// <typeparam name="TState">The state type</typeparam>
public class SeqStateCollection<TState> : List<SeqState<TState>> where TState : notnull
{
    /// <inheritdoc />
    public SeqStateCollection(IEnumerable<SeqState<TState>> enumerable) : base(enumerable) { }


    /// <summary>
    /// Returns the sequence-state by the state-key
    /// </summary>
    /// <param name="theState">The state-key</param>
    public SeqState<TState>? GetSeqState(TState theState) =>
        this.FirstOrDefault(x => x?.State?.Equals(theState) ?? false);


    /// <summary>
    /// Returns true if the sequence-states contains a state with the specified state-key
    /// </summary>
    /// <param name="theState">The state-key</param>
    public bool Contains(TState theState) =>
        this.Any(x => x?.State?.Equals(theState) ?? false);
}