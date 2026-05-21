namespace FluentSeq.Extensions;

using Builder;

/// <summary>
/// ExtensionMethods for the SequenceBuilder.
/// </summary>
public static class SequenceBuilderExtensions
{
    /// <summary>
    /// The complete validation of the sequence configuration will be disabled temporarily.
    /// Use this if you want this for test purpose only.
    /// Later on you can find the usage of the DisableValidationTemporarily method very easy.
    /// </summary>
    /// <param name="builder">The sequence builder</param>
    public static ISequenceBuilder<TState> DisableValidationTemporarily<TState>(this ISequenceBuilder<TState> builder) 
        where TState : notnull =>
        builder.Builder().DisableValidation();


    /// <summary>
    /// Returns true if validation for state is required.
    /// </summary>
    /// <param name="builder">The sequence builder</param>
    /// <param name="state">The specified state</param>
    public static bool ValidationRequiredFor<TState>(this ISequenceBuilder<TState> builder , TState state)
        where TState : notnull =>
        !builder.Builder().Options.DisableValidation &&
        !builder.Builder().Options.DisableValidationForStates.Contains(state);


    /// <summary>
    /// Returns true if no validation for state is required.
    /// </summary>
    /// <param name="builder">The sequence builder</param>
    /// <param name="state">The specified state</param>
    public static bool NoValidationRequiredFor<TState>(this ISequenceBuilder<TState> builder , TState state)
        where TState : notnull =>
        !builder.Builder().ValidationRequiredFor(state);
}