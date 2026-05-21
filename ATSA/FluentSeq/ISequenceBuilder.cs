namespace FluentSeq;

using Builder;
using Core;

/// <summary>
/// Provides methods to configure a sequence
/// </summary>
/// <typeparam name="TState">The type of the state</typeparam>
public interface ISequenceBuilder<TState> : IHasSequenceBuilder<TState>, ICanConfigureState<TState> where TState : notnull
{
    internal HashSet<StateBuilder<TState>> StateBuilders { get; }


    /// <summary>
    /// Returns a list of all registered states
    /// </summary>
    SeqStateCollection<TState> RegisteredStates { get; }

    /// <summary>
    /// The options for building a sequence
    /// </summary>
    SequenceOptions<TState> Options { get; }


    /// <summary>
    /// Finally builds the configured sequence
    /// </summary>
    /// <returns>A complete sequence that could be executed</returns>
    ISequence<TState> Build();



    /// <summary>
    /// Activates debug logging
    /// </summary>
    /// <param name="logger">The logger</param>
    ISequenceBuilder<TState> ActivateDebugLogging(NLog.ILogger? logger);


    /// <summary>
    /// The complete validation of the sequence configuration will be disabled
    /// </summary>
    ISequenceBuilder<TState> DisableValidation();

    /// <summary>
    /// The validation for the specified states within the sequence configuration will be disabled
    /// </summary>
    ISequenceBuilder<TState> DisableValidationForStates(params TState[] states);

    /// <summary>
    /// An Action that will be executed when the state of the sequence changes
    /// </summary>
    ISequenceBuilder<TState> OnStateChanged(Action onStateChangedAction);

    /// <summary>
    /// An Action that will be executed when the state of the sequence changes
    /// The enableFunc will be used to determine if the action should be executed
    /// </summary>
    ISequenceBuilder<TState> OnStateChanged(Action onStateChangedAction, Func<bool> enableFunc);
}