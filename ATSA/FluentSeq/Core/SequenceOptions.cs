namespace FluentSeq.Core;

using NLog;

/// <summary>
/// The sequence configuration
/// </summary>
public class SequenceOptions<TState>
{
    /// <summary>
    /// The logger
    /// </summary>
    public ILogger? Logger { get; set; }


    /// <summary>
    /// The complete validation of the sequence configuration will be disabled
    /// </summary>
    public bool DisableValidation { get; set; }

    /// <summary>
    /// The validation for the specified states within the sequence configuration will be disabled
    /// </summary>
    public IEnumerable<TState> DisableValidationForStates { get; set; } = [];


    /// <summary>
    /// The state the sequence will start from
    /// </summary>
    public TState InitialState { get; set; } = default!;

    /// <summary>
    /// An Action that will be executed when the state of the sequence changes
    /// </summary>
    public (Action onStateChangedAction, Func<bool> enableFunc)? OnStateChangedAction { get; set; }
}