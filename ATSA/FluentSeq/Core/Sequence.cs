namespace FluentSeq.Core;

using IegTools.Extensions;
using NLog;

/// <summary>
/// A sequence that could be executed
/// </summary>
/// <typeparam name="TState">Type of the state (string, enum, int...)</typeparam>
public class Sequence<TState> : ISequence<TState> where TState : notnull
{
    /// <summary>
    /// A sequence that could be executed
    /// </summary>
    public Sequence(SequenceOptions<TState> options, SeqStateCollection<TState> registeredStates)
    {
        Options          = options;
        Logger           = options.Logger;
        RegisteredStates = registeredStates;
        SetState(options.InitialState);
    }

    /// <inheritdoc />
    public ILogger? Logger { get; }

    /// <inheritdoc />
    public SequenceOptions<TState> Options { get; }

    /// <inheritdoc />
    public SeqStateCollection<TState> RegisteredStates { get; }

    /// <inheritdoc />
    public TState CurrentState { get; private set; } = default!;


    /// <inheritdoc />
    public TState? PreviousState { get; private set; }


    /// <inheritdoc />
    public TimeSpan CurrentStateDuration() => GetSeqState(CurrentState!)?.Duration ?? TimeSpan.Zero;

    /// <inheritdoc />
    public bool CurrentStateElapsed(TimeSpan duration) => GetSeqState(CurrentState!)?.Elapsed(duration) ?? false;


    /// <inheritdoc />
    public bool IsInState(TState state) =>
        CurrentState!.Equals(state);

    /// <inheritdoc />
    public bool IsInStates(params TState[] states) =>
        states.Contains(CurrentState!);

    /// <inheritdoc />
    public async Task<ISequence<TState>> RunAsync() =>
        await Task.Run(Run).ConfigureAwait(false);


    /// <inheritdoc />
    public ISequence<TState> Run()
    {
        foreach (var state in RegisteredStates)
        {
            if (state.Trigger.Any(x => x.IsTriggered(this)))
            {
                Logger?.Debug("Triggered state change to {State}", state.State);
                SetState(state.State);

                // if the first state is triggered, break the loop
                break;
            }
        }

        GetSeqState(CurrentState!)?.WhileInStateActions.ForEach(x => x());

        return this;
    }


    /// <inheritdoc />
    private TState? _lastLoggedPrevious;
    private TState? _lastLoggedCurrent;
    private int _repeatCount;

    /// <summary>
    /// Forces the sequence into a specific state, bypassing triggers.
    /// </summary>
    /// <param name="state">The state to transition to.</param>
    /// <returns>The sequence instance.</returns>
    public ISequence<TState> SetState(TState state)
    {
        PreviousState = CurrentState;
        CurrentState  = state;

        if (CurrentStateHasChanged())
        {
            if (PreviousState?.Equals(_lastLoggedPrevious) == true && CurrentState?.Equals(_lastLoggedCurrent) == true)
            {
                _repeatCount++;
            }
            else
            {
                _lastLoggedPrevious = PreviousState;
                _lastLoggedCurrent = CurrentState;
                _repeatCount = 0;
            }

            if (_repeatCount < 5)
            {
                if (PreviousState == null || PreviousState.ToString() == "NULL")
                    Logger?.Trace("State changed from {PreviousState} to {CurrentState}", PreviousState, CurrentState);
                else
                    Logger?.Info("State changed from {PreviousState} to {CurrentState}", PreviousState, CurrentState);
            }
            else if (_repeatCount == 5)
            {
                Logger?.Info("... 상태 변경 로그 반복 생략 (반복 횟수 초과) ...");
            }

            GetSeqState(CurrentState!)?.SetAsCurrentState();
        }
        // ... (이후 동일)
        if (CurrentStateHasChanged() && RegisteredStates.HasItems())
        {
            callAllExitActions(PreviousState);
            callAllEntryActions(CurrentState);
        }

        if (CurrentStateHasChanged())
            invokeStateChangedAction();

        return this;

        void callAllExitActions(TState? theState)
        {
            if (theState == null) return;
            GetSeqState(theState!)?.ExitActions.ForEach(x => x());
        }

        void callAllEntryActions(TState? theState)
        {
            if (theState == null) return;
            GetSeqState(theState!)?.EntryActions.ForEach(x => x());
        }

        void invokeStateChangedAction()
        {
            if (Options.OnStateChangedAction.HasValue && Options.OnStateChangedAction.Value.enableFunc())
                Options.OnStateChangedAction.Value.onStateChangedAction();
        }
    }

    private SeqState<TState>? GetSeqState(TState state) =>
        RegisteredStates.GetSeqState(state);

    private bool CurrentStateHasChanged() =>
        !CurrentState?.Equals(PreviousState) ?? false;


    /// <inheritdoc />
    public ISequence<TState> SetState(TState state, Func<bool> condition) =>
        condition() ? SetState(state) : this;
}