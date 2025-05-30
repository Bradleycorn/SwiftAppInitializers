import Foundation


/// A type that defines a routine for performing an app startup task.
///
/// Types that conform to the `AppInitializer` protocol define a single task
/// to be used to initialize the app. In addition to the task, the `AppInitailizer`
/// defines the task's _priority_ as well as any other `AppInitializer` types that
/// this type depends on.
///
/// ## Detailed Documentation
/// For more information, see the <doc:AppInitializers> documentation.
///
/// ## Additional Info
/// This protocol conforms to the `AnyObject` protocol. This enforces reference semantics.
/// Only classes can conform to this protocol, not structs. This is necessary so that we can compare instances.
public protocol AppInitializer: AnyObject {

    /// The ``InitializerPriority`` for this intiailizer.
    ///
    /// ``InitializerPriority`` determines the phase of the app lifecycle when the initializer should be executed.
    /// See <doc:DefiningInitializers#Setting-Initializer-Priority> for more information.
    var priority: InitializerPriority { get }
    
    /// A list of other `AppInitializer`s that this initializer depends on.
    ///
    /// An ``AppInitializer`` should execute a single task. Sometimes app initialization tasks need to be executed in
    /// a specific order. To esure that another ``AppInitializer`` is executed to completion before this initializer is executed.
    /// list it in this initializer's dependencies.
    ///
    /// > Tip: Do not create "artificial" dependencies because it increases the likelihood that you will introduce ciruclar or missing dependency errors.
    /// Only list a dependency when it is _required_, for example when one initializer loads some data and another initializer uses that data and would fail without it.
    var dependencies: Array<AppInitializer.Type> { get }
    
    /// Defines the task/work that should be executed by this `AppInitializer`.
    @MainActor
    func run() async throws
}

extension AppInitializer {
    /// The specifc `Type` of an instance that conforms to the `AppInitializer` protocol.
    var initializerType: AppInitializer.Type {
        type(of: self)
    }    
}

extension Array<AppInitializer> {
    
    /// Filters an Array of ``AppInitializer``s, returning a new array with only the initializers that
    /// have a specific priority.
    ///
    /// - Parameters:
    ///   - priority: The ``InitializerPriority`` that the array should be filtered by.
    /// - Returns: A new Array containing the `AppInitializer` instances from this array
    ///   have a ``AppInitializer/priority`` that matches the passed in ``InitializerPriority``.
    func filter(by priority: InitializerPriority) -> Array<AppInitializer> {
        self.filter { initializer in
            initializer.priority == priority
        }
    }
    
    /// Determine if a specific ``AppInitializer`` instance exists in this Array.
    ///
    /// - Parameters:
    ///   - initializer: An instance of a type that conforms to the app ``AppInitializer`` protocol to look for in this Array.
    ///
    /// - Returns: `True` if the passed in ``AppInitializer`` was found in this Array.
    func contains(_ initailizer: AppInitializer) -> Bool {
        self.contains { $0 === initailizer }
    }

    /// Remove a specific ``AppInitializer`` from this Array.
    ///
    /// - Parameters:
    ///   - item: An instance of a type that conforms to the app ``AppInitializer`` protocol to find and remove from this Array.
    mutating func remove(_ item: AppInitializer) {
        self.removeAll { i in
            i === item
        }
    }
}


extension Array<AppInitializer.Type>  {

    /// Determine if a specific ``AppInitializer`` `Type` exists in this Array.
    ///
    /// - Parameters:
    ///   - type: A `Type` that conforms to the  ``AppInitializer`` protocol to look for in this Array.
    ///
    /// - Returns: `True` if the passed in `Type` was found in this Array.
    func contains(_ type: AppInitializer.Type) -> Bool {
        self.contains { $0 === type }
    }
}
