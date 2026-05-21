namespace FluentSeq.Builder;

using Core;

/// <summary>
/// Provides methods for further describing a state
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public class StateBuilder<TState> : IStateBuilder<TState> where TState : notnull
{
    private readonly ConfigureActions<TState> _actions;
    private readonly ConfigureTrigger<TState> _trigger;

    /// <summary>
    /// Provides methods for further describing a state
    /// </summary>
    public StateBuilder(ISequenceBuilder<TState> sequenceBuilder, TState state, string description)
    {
        RootSequenceBuilder = sequenceBuilder.Builder();
        RootStateBuilder    = this;
        State               = new SeqState<TState>(state, description);
        _actions            = new ConfigureActions<TState>(RootStateBuilder);
        _trigger            = new ConfigureTrigger<TState>(RootStateBuilder);
    }


    /// <summary>
    /// The root SequenceBuilder
    /// </summary>
    private ISequenceBuilder<TState> RootSequenceBuilder { get; }

    /// <inheritdoc />
    public StateBuilder<TState> RootStateBuilder { get; }

    /// <inheritdoc />
    public SeqState<TState> State { get; }


    /// <inheritdoc />
    public override string ToString() =>
        $"StateBuilder for State: {State.Name} {State.Description}";


    /// <inheritdoc />
    public override bool Equals(object? obj) =>
        obj is StateBuilder<TState> stateBuilder && State.Equals(stateBuilder.State);

    /// <inheritdoc />
    public override int GetHashCode() =>
        State.Name.GetHashCode();


    /// <inheritdoc />
    public ITriggerBuilder<TState> TriggeredBy(Func<bool> triggeredByFunc) =>
        _trigger.TriggeredBy(triggeredByFunc);

    /// <inheritdoc />
    public ITriggerBuilder<TState> TriggeredByState(TState state, Func<TimeSpan> dwellTime) =>
        _trigger.TriggeredByState(state, dwellTime);


    /// <inheritdoc />
    public IStateBuilder<TState> OnExit(Action action) =>
        _actions.OnExit(action);

    /// <inheritdoc />
    public IStateBuilder<TState> OnEntry(Action action) =>
        _actions.OnEntry(action);

    /// <inheritdoc />
    public IStateBuilder<TState> WhileInState(Action action) =>
        _actions.WhileInState(action);


    /// <inheritdoc />
    public ISequenceBuilder<TState> Builder() =>
        RootSequenceBuilder;

    /// <inheritdoc />
    public IStateBuilder<TState> ConfigureState(TState state, string description = "") =>
        Builder().ConfigureState(state, description);
}