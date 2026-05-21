namespace FluentSeq.Exceptions;

/// <summary>
/// An exception that is thrown when a state with the same name has already been configured.
/// </summary>
public class DuplicateStateException : Exception
{
    /// <summary>
    /// Creates a new instance of the <see cref="DuplicateStateException"/> class.
    /// </summary>
    /// <param name="stateName"></param>
    public DuplicateStateException(string stateName)
        : base($"A state with the name '{stateName}' has already been configured.")
    {
    }
}