
import Foundation
import Combine
import SwiftUI

/// Manages App Initialization by executing a set of ``AppInitializer``s at appropriate
/// times during the application lifecycle.
///
/// ## Detailed Documentation
/// For detailed information and examples, see the <doc:InitializationManager> documentation.
///
/// ## Overview
/// As its name implies, the `InitManager` is responsible for managing app initialization.
/// You pass it a set of ``AppInitializer`` instances, and call its methods to execute
/// subsets of those instances at the appropriate time during the  application lifecycle.
/// During execution, the `InitManager` will resolve and execute dependencies, as well
/// as track and expose the current ``InitializationState``.
///
/// You should create a single `InitManager` instance for your application,  and resiter
/// **ALL** of your ``AppInitializer`` instances with it.  Then call it's public
/// api methods to execute the right sets of ``AppInitializer``s at the appropriate time.
///
/// ```swift
/// let launchInitializer1 = LaunchInitializer1()
/// let launchInitializer2 = LaunchInitializer2()
/// let activeInitializer = AppActiveInitializer()
///
/// let appInitManager = InitManager([launchInitializer1, launchInitializer2, activeInitializer])
/// ```
@MainActor
public class InitManager: ObservableObject {
        
    private let notificationCenter: NotificationCenter = NotificationCenter.default
    
    /// The set of ``AppInitializer``s that are managed by this `InitManager` instance.
    private let initializers: [AppInitializer]
    
    /// An ``InitEventsDelegate`` for tracking initialization events.
    private let eventsDelegate: AppInitializerEventsDelegate?

    /// A swift `Task` that is used to execute ``AppInitializer``s at app launch.
    /// This property is `nil` until launch initializers are executed the first time.
    private var launchTask: Task<Void, Never>? = nil

    /// A swift `Task` that is used to execute ``AppInitializer``s when the app becomes "active".
    /// This property is `nil` until "active" initializers are executed the first time.
    private var activeTask: Task<Void, Never>? = nil
        
    /// A list of ``AppInitializer``s that have been executed to completion.
    private var completedInitializers: [AppInitializer.Type] = []
        
    /// Creates an `InitManager` instance that is used to manage a set of ``AppInitializer``s.
    ///
    /// Create one instance of this class for your app, and register ALL of your ``AppInitializer`` instances with it.
    /// For more information,  see the <doc:InitializationManager> documentation.
    ///
    /// - Parameters:
    ///  - initializers: The list of ``AppInitializer``s that should be managed by this instance.
    ///  - eventsDelegate: An ``AppInitializerEventsDelegate`` that should be notified when initialization events take place.
    public init(_ initializers: [AppInitializer], eventsDelegate: AppInitializerEventsDelegate? = nil) {
        self.initializers = initializers
        self.eventsDelegate = eventsDelegate
        
        onAppLaunch()
        
        #if os(iOS)
            notificationCenter.addObserver(self, selector: #selector(onAppActive), name: UIApplication.willEnterForegroundNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(onAppInactive), name: UIApplication.willResignActiveNotification, object: nil)
        #endif
    }
    
    /// Get notified in your App when ``InitializerPriority/appLaunch`` initializers complete successfully or fail with an error.
    ///
    /// This property tracks the aggregate state of ``InitializerPriority/appLaunch`` initializers, which are executed
    /// once when an instance of this class is created. It's initial value is ``InitializationState/pending``,
    /// and it will be updated when the `InitManager` finishes running the set of Launch initializers.
    private lazy var launchSubject = CurrentValueSubject<InitializationState, Never>(.pending)
    public lazy var launchState = launchSubject.eraseToAnyPublisher()
   
    /// Get notified in your App when ``InitializerPriority/appActive`` initializers complete successfully or fail with an error.
    ///
    /// This property tracks the aggregate state of ``InitializerPriority/appActive`` initializers, which are executed
    /// each time your app enters the foreground. It's initial value is ``InitializationState/pending``.
    /// and it will be updated when the `InitManager` finishes running the set of App Active initializers.
    /// Each time the app enters the foreground this value will be set to ``InitializationState/pending``,
    /// and updated again when the set of App Active initializers completes.
    private lazy var activeSubject = CurrentValueSubject<InitializationState, Never>(.pending)
    public lazy var activeState = activeSubject.eraseToAnyPublisher()

    
    /// Coalesces the `launchState` and `activeState` into a single observable state.
    ///
    /// The `launchState` and `activeState` track the current state of individual subsets
    /// of ``AppInitializer``s.  This value combines both of those into a single overall app initialization
    /// state. This value will only be ``InitializationState/complete`` when both the launch AND active
    /// initliazers have completed successfully. If either set has failed, then this value will also be ``InitializationState/failed(error:)``.
    /// Likewise, if either set has not completed, or has not finished running, then this value will be ``InitializationState/pending``.
    public var state: AnyPublisher<InitializationState, Never> {
        return launchState.combineLatest(activeState) { launchState, activeState  in
            switch (launchState, activeState) {
                case(.failed(_), _):
                    return launchState
                case(_, .failed(_)):
                    return activeState
                case (.complete, .complete):
                    return InitializationState.complete
                default:
                    return InitializationState.pending
            }
        }.eraseToAnyPublisher()
    }
    
    /// Executes all registered ``AppInitializer``s that have an ``InitializerPriority/appLaunch`` priority.
    ///
    /// This method starts a `Task` and executes all ``AppInitializer``s that have an ``InitializerPriority/appLaunch`` priority.
    /// It also updates the `launchState` appropriately before, during, and after the Task runs.
    ///
    /// Call this method as early as possible during the launch of your app to ensure that all tasks that should be executed once at app launch
    /// are completed as quickly as possible.
    public func onAppLaunch() {
        launchTask = Task {
            do {
                launchSubject.send(.pending)
                eventsDelegate?.appLaunchStarted()
                defer {
                    eventsDelegate?.appLaunchCompleted(result: launchSubject.value)
                }
                try await initialize(initializers.filter(by: .appLaunch))
                launchSubject.send(.complete)
            } catch {
                launchSubject.send(.failed(error: error))
            }
        }
    }
            
    /// Executes all registered ``AppInitializer``s that have an ``InitializerPriority/appActive`` priority.
    ///
    /// This method starts a `Task` and executes all ``AppInitializer``s that have an ``InitializerPriority/appActive`` priority.
    /// It also updates the `activeState` appropriately before, during, and after the Task runs.
    ///
    /// Call this method any time your app becomes "active". Likewise, you should call ``onAppInactive()`` to cancel the `Task` that this method
    /// launches when your app leaves the "active" phase.  In a swiftUI app, consider using the `onScenePhaseChange(to:)`` method instead
    /// of calling this method directly. For more information, see the <doc:InitializationManager#Performing-initializations-When-Your-App-is-Active> documentation.
    @objc
    public func onAppActive() {
        activeTask = Task {
            do {
                activeSubject.send(.pending)
                // don't run active intiailizers until launch initializers are done
                await launchTask?.value
                
                if case .failed = launchSubject.value {
                    activeSubject.send(launchSubject.value)
                    return
                }
                eventsDelegate?.appActiveStarted()
                defer {
                    eventsDelegate?.appActiveCompleted(result: activeSubject.value)
                }

                let activeInitializers = initializers.filter(by: .appActive)
                
                // Remove the active initiailzers from the completed initializers list,
                // so that they will get reinitialized.
                let activeInitializerTypes = activeInitializers.map { $0.initializerType }
                completedInitializers.removeAll { completedInitializer in
                    activeInitializerTypes.contains(completedInitializer)
                }

                try await initialize(activeInitializers)
                
                activeSubject.send(.complete)
            } catch {
                activeSubject.send(.failed(error: error))
            }
        }
    }
    
    /// Cancels any ``AppInitializer``s with an ``InitializerPriority/appActive`` priority that are currently running.
    ///
    /// Call this method any time your app leaves the "active" scene phase to cancel any running Initializers.  In a swiftUI app, consider using the `onScenePhaseChange(to:)`` method instead
    /// of calling this method directly. For more information, see the <doc:InitializationManager#Performing-initializations-When-Your-App-is-Active> documentation.
    @objc
    public func onAppInactive() {
        guard let task = activeTask, task.isCancelled == false else { return }
        task.cancel()
        eventsDelegate?.appActiveCompleted(result: activeSubject.value)
    }
    
    /// Calculate dependencies and run a set of initializers.
    ///
    /// This method is called by the ``onAppActive()`` and ``onAppLaunch()`` methods to run initializers.
    private func initialize(_ initializers: [AppInitializer]) async throws {
        for initializer in initializers {
            if Task.isCancelled { break }
        
            // Need a variable so that we can pass a mutable value to the recursive initialization routine.
            var currentlyInitializing: Array<AppInitializer> = []
            try await runInitializer(initializer, initializing: &currentlyInitializing)
        }
    }
        
    /// Run a single initializer
    ///
    /// This method will resolve dependencies for the passed in initializer, make sure they are (or have already been) executed to completion,
    /// and then run the passed in initializer.
    ///
    /// - Parameters:
    ///   - initializer: The ``AppInitializer`` that should be exectued.
    ///   - initializing: An Array of ``AppInitializer`` that contains a list of all initializers that are currently being executed.
    ///           When calling this method, pass an empty array to this parameter. It is used for recursion to detect and prevent circular dependency references.
    private func runInitializer(_ initializer: AppInitializer, initializing: inout Array<AppInitializer>) async throws {
        // Prevent Circular Dependencies
        guard (!initializing.contains(initializer)) else {
            throw AppInitializationError.circularDependency(initializer.initializerType)
        }
        
        // Don't run this initializer if it's already in the "completed" list.
        guard(!completedInitializers.contains(initializer.initializerType)) else {
            eventsDelegate?.initializerSkipped()
            return
        }
        
        initializing.append(initializer)
        try await processDependencies(initializer.dependencies, initializing: &initializing)
        do  {
            if (!Task.isCancelled) {
                eventsDelegate?.initializerExecuted()
                try await initializer.run()
            }
        } catch {
            throw AppInitializationError.initializerFailed(initializer.initializerType, error: error)
        }
        initializing.remove(initializer)
        completedInitializers.append(initializer.initializerType)
    }
    
    /// Process a set of dependencies and make sure each one is executed, including any child dependencies.
    private func processDependencies(_ dependencies: [AppInitializer.Type], initializing: inout Array<AppInitializer>) async throws {
        for dependency in dependencies {
            if Task.isCancelled { break }
            
            guard let initializer = (initializers.first { $0.initializerType == dependency }) else {
                throw AppInitializationError.missingDependency(dependency)
            }
                        
            try await runInitializer(initializer, initializing: &initializing)
        }
    }
}

