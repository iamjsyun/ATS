namespace FluentSeq.Core;

/// <summary>
/// Describes a state
/// </summary>
public class SeqState<TState> where TState : notnull
{
    /// <summary>
    /// Describes a state
    /// </summary>
    /// <param name="state">The state</param>
    /// <param name="description">The description of the state</param>
    public SeqState(TState state, string description = "")
    {
        State = state;
        Name  = state?.ToString() ?? Guid.NewGuid().ToString();
        Description = description;
    }

    /// <summary>
    /// The state
    /// </summary>
    public TState State { get; }

    /// <summary>
    /// The name of the state
    /// </summary>
    public string Name { get; }

    /// <summary>
    /// The description of the state
    /// </summary>
    public string Description { get; }

    /// <summary>
    /// The last time the state was activated
    /// </summary>
    public DateTime LastActivated { get; private set; } = DateTime.Now;


    /// <summary>
    /// Gets a list of trigger for this state
    /// </summary>
    public List<Trigger<TState>> Trigger { get; } = new();

    /// <summary>
    /// Gets the list of actions to be executed when the state is exited.
    /// </summary>
    public List<Action> ExitActions { get; } = new();

    /// <summary>
    /// Gets the list of actions to be executed when the state is entered.
    /// </summary>
    public List<Action> EntryActions { get; } = new();

    /// <summary>
    /// Gets the list of actions to be executed repeatedly while the sequence's current state is this state.
    /// </summary>
    public List<Action> WhileInStateActions { get; } = new();


    /// <summary>
    /// The duration of the current state
    /// </summary>
    public TimeSpan Duration => DateTime.Now - LastActivated;


    /// <inheritdoc />
    public override string ToString() =>
        $"{Name} {Description} | has action(s): {EntryActions.Count > 0}";

    /// <inheritdoc />
    public override bool Equals(object? obj) =>
        obj is SeqState<TState> state && Name.Equals(state.Name);

    /// <inheritdoc />
    public override int GetHashCode() =>
        Name.GetHashCode();


    /// <summary>
    /// The state has elapsed the specified duration
    /// </summary>
    public bool Elapsed(TimeSpan duration) => Duration >= duration;


    /// <summary>
    /// Sets the state as the current state
    /// </summary>
    public void SetAsCurrentState()
    {
        LastActivated = DateTime.Now;
    }
}