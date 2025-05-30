import Foundation


/// Enumerates the possible error states that can happen during App Initialization.
@frozen
public enum AppInitializationError: Error {
    
    /// A circular dependency was found among a set of ``AppInitializer``s
    /// and initialization could not be completed.
    /// For more information see <doc:ManagingDependencies>.
    ///
    /// - Parameters:
    ///   - dependency: The (first) initializer that was found to be repeted when resolving
    ///   the dependency tree.
    case circularDependency(_ dependecy: AppInitializer.Type)
    
    /// An ``AppInitializer`` regisetered with the ``InitManager`` listed a dependecy
    /// on another initializer that has not been registered.
    ///
    /// This often happens when you create a new ``AppInitializer`` and forget to add
    /// it to the list of Initializers passed to the  ``InitManager`` when it is created.
    ///
    /// - Parameters:
    ///   - dependency: The ``AppInitializer`` that is missing from the ``InitManager``'s
    ///   list of registered dependencies.
    case missingDependency(_ dependency: AppInitializer.Type)
    
    /// An error was thrown during execution of a specific ``AppInitializer``. This is usually
    /// due to an error you have thrown in your code that is executed by the
    /// ``AppInitializer``. ``AppInitializer/run()`` method.
    ///
    /// - Parameters:
    ///   - dependency: The ``AppInitializer`` in which the error was thrown.
    ///   - error: The actual `Error` that was thrown.
    case initializerFailed(_ dependency: AppInitializer.Type, error: Error)
}
