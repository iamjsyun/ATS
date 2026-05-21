namespace FluentSeq;

using Builder;

/// <summary>
/// This is the root element for FluentSeq
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public class FluentSeq<TState> where TState : notnull
{
    private ISequenceBuilder<TState> _sequenceBuilder = null!;

    /// <summary>
    /// Initializes a new sequence builder with the specified initial state.
    /// </summary>
    /// <param name="initialState">The initial state of the sequence</param>
    /// <returns>A sequence builder to configure the state machine</returns>
    public ISequenceBuilder<TState> Create(TState initialState)
    {
        // BuilderFactory<TState>.CreateSequenceBuilder(initialState);
        _sequenceBuilder = new SequenceBuilder<TState>(initialState);
        return _sequenceBuilder;
    }


    /// <summary>
    /// Configures a sequence with detailed settings using the provided actions.
    /// </summary>
    /// <param name="initialState">The initial state of the sequence</param>
    /// <param name="configurationActions">The actions to configure the sequence</param>
    /// <returns>A sequence builder with the applied configurations</returns>
    public ISequenceBuilder<TState> Configure(TState initialState, Action<ISequenceBuilder<TState>> configurationActions)
    {
        var sequenceBuilder = Create(initialState);
        configurationActions.Invoke(sequenceBuilder);
        return sequenceBuilder;
    }
}