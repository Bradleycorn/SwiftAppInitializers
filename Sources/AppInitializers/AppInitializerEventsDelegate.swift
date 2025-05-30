import Foundation

/// A delegate that is used by the `InitManager` to notifiy the
/// application of events that take place during initialization.
///
/// An application can provide an implementation of this protocol
/// to the `InitManager` so that it can take action when various initialization
/// events happen. Often this is used to track analytics and do performance traces.
public protocol AppInitializerEventsDelegate {
    /// Called when the routine to run initializers with an `InitializerPriority/appLaunch` priorty
    /// has been started.
    func appLaunchStarted()
    
    
    /// Called when the  routine to run nitializers with an `InitializerPriority/appLaunch` priorty
    /// has finished.
    ///
    /// - Parameters:
    ///   - result: An `InitializationState` that indicates the current status of the launch initializers.
    func appLaunchCompleted(result: InitializationState)
    
    /// Called when he routine to run initializers with an `InitializerPriority/appActive` priorty
    /// has been started.
    func appActiveStarted()

    /// Called when the  routine to run nitializers with an `InitializerPriority/appActive` priorty
    /// has finished.
    ///
    /// - Parameters:
    ///   - result: An `InitializationState` that indicates the current status of the active initializers.
    func appActiveCompleted(result: InitializationState)

    
    /// Called when an initializer is skipped during an initialization routine.
    func initializerSkipped()
    
    /// Called when an initializer is executed during an initialization routine.
    func initializerExecuted()
}

// An extension to provide empty default implementations so that consuming
// applications don't have to provide handlers for events they do not care about.
extension AppInitializerEventsDelegate {
    public func appLaunchStarted() {}
    public func appLaunchCompleted(result: InitializationState) {}
    
    public func appActiveStarted() {}
    public func appActiveCompleted(result: InitializationState) {}

    public func initializerSkipped() {}
    public func initializerExecuted() {}
}
