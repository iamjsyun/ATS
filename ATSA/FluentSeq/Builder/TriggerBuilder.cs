namespace FluentSeq.Builder;

using Core;

/// <summary>
/// Provides methods for further describing a trigger
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public class TriggerBuilder<TState> : ITriggerBuilder<TState> where TState : notnull
{
    private readonly ConfigureActions<TState> _actions;
    private readonly ConfigureTrigger<TState> _trigger;

    /// <summary>
    /// Provides methods to parametrize a trigger
    /// </summary>
    public TriggerBuilder(IStateBuilder<TState> stateBuilder, Func<bool> triggeredByFunc)
    {
        RootSequenceBuilder = stateBuilder.Builder();
        RootStateBuilder    = stateBuilder.RootStateBuilder;
        Trigger             = new Trigger<TState>(RootStateBuilder, triggeredByFunc);
        _actions            = new ConfigureActions<TState>(RootStateBuilder);
        _trigger            = new ConfigureTrigger<TState>(RootStateBuilder);
    }

    /// <summary>
    /// The root SequenceBuilder
    /// </summary>
    private ISequenceBuilder<TState> RootSequenceBuilder { get; }

    private StateBuilder<TState> RootStateBuilder { get; }


    /// <inheritdoc />
    public Trigger<TState> Trigger { get; }


    /// <inheritdoc />
    public ITriggerBuilder<TState> TriggeredBy(Func<bool> triggeredByFunc) =>
        _trigger.TriggeredBy(triggeredByFunc);

    /// <inheritdoc />
    public ITriggerBuilder<TState> TriggeredByState(TState state, Func<TimeSpan> dwellTime) =>
        _trigger.TriggeredByState(state, dwellTime);


    /// <inheritdoc />
    public ITriggerBuilder<TState> WhenInState(TState state)
    {
        Trigger.WhenInStates.Add(new TriggerCondition<TState>(state));
        return this;
    }

    /// <inheritdoc />
    public ITriggerBuilder<TState> WhenInState(TState state, Func<TimeSpan> dwellTime)
    {
        Trigger.WhenInStates.Add(new TriggerCondition<TState>(state, dwellTime));
        return this;
    }

    /// <inheritdoc />
    public ITriggerBuilder<TState> WhenInStates(params TState[] states)
    {
        var triggerConditions = states.Select(state => new TriggerCondition<TState>(state));
        Trigger.WhenInStates.AddRange(triggerConditions);
        return this;
    }

    /// <inheritdoc />
    public ITriggerBuilder<TState> WhenInStatesStartingWith(string statePrefix)
    {
        Builder().RegisteredStates
            .Where(x => x.State.ToString()?.StartsWith(statePrefix) ?? false).ToList()
                .ForEach(x => WhenInState(x.State));
        return this;
    }


    // fex
    // public ITriggerBuilder<TState> WhenStateIsInCondition(Func<TState, bool> predicate)
    // {
    //     var matchingStates = Builder().RegisteredStates
    //         .Where(x => predicate(x.State))
    //         .Select(x => new TriggerCondition<TState>(x.State));
    //
    //     Trigger.WhenInStates.AddRange(matchingStates);
    //     return this;
    // }

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