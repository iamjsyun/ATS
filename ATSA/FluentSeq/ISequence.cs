namespace FluentSeq;

using Core;
using NLog;

/// <summary>
/// Interface for a sequence
/// </summary>
public interface ISequence<TState> where TState : notnull
{
    /// <summary>
    /// The logger
    /// </summary>
    ILogger? Logger { get; }

    /// <summary>
    /// The sequence options
    /// </summary>
    SequenceOptions<TState> Options { get; }

    /// <summary>
    /// All States that are registered for this sequence
    /// </summary>
    SeqStateCollection<TState> RegisteredStates { get; } 


    /// <summary>
    /// The current state of the sequence
    /// </summary>
    TState CurrentState { get; }

    /// <summary>
    /// The previous state of the sequence
    /// </summary>
    TState? PreviousState { get; }


    /// <summary>
    /// The duration of the current state
    /// </summary>
    TimeSpan CurrentStateDuration();

    /// <summary>
    /// The current state has elapsed the specified duration
    /// </summary>
    bool CurrentStateElapsed(TimeSpan duration);

    /// <summary>
    /// Checks if the current state of the sequence matches the specified state.
    /// </summary>
    /// <param name="state">The state to check against the current state.</param>
    /// <returns>True if the current state matches the specified state; otherwise, false.</returns>
    bool IsInState(TState state);

    /// <summary>
    /// Checks if the current state of the sequence matches any of the specified states.
    /// </summary>
    /// <param name="states">The states to check against the current state.</param>
    /// <returns>True if the current state matches any of the specified states; otherwise, false.</returns>
    bool IsInStates(params TState[] states);


    /// <summary>
    /// Runs the sequence asynchronous
    /// </summary>
    Task<ISequence<TState>> RunAsync();

    /// <summary>
    /// Run the sequence
    /// </summary>
    ISequence<TState> Run();


    /// <summary>
    /// CurrentState will be set to the state immediately and unconditional.
    /// The execution of the sequence will continue.
    /// </summary>
    /// <param name="state">The state that will be set</param>
    ISequence<TState> SetState(TState state);

    /// <summary>
    /// If the constraint is fulfilled the CurrentState will be set to the state immediately
    /// and the execution of the sequence will continue.
    /// </summary>
    /// <param name="state">The state that should be set</param>
    /// <param name="condition">The condition that must be fulfilled that the sequence is set to the defined state</param>
    ISequence<TState> SetState(TState state, Func<bool> condition);
}