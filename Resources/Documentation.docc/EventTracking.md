# Tracking Initialization Events

Track initialization events in your application for logging and analytics

## Overview

The ``AppInitializerEventsDelegate`` protocol provides a way to monitor and track events that occur during the app initialization process. This is particularly useful for logging initialization metrics, debugging issues, or integrating with analytics services like Firebase.

All methods in ``AppInitializerEventsDelegate`` are optional. You only need to implement the methods for events you want to track, making it flexible to match your specific tracking needs. For example, you might only care about failure events, in which case you would only implement `initializerDidFail(_:error:)` and ignore the other events.

By implementing this delegate, you can capture important events such as:
- When initializers start and complete their work
- How long initialization tasks take
- When initialization failures occur
- Which initializers are running at any given time

### Implementing the Events Delegate

To track initialization events, create a class that implements the ``AppInitializerEventsDelegate`` protocol and provide it to your ``InitManager`` instance. Remember, you only need to implement the methods for events you want to track.

```swift
class InitializationEventTracker: AppInitializerEventsDelegate {
    // Only tracking start and failure events
    func initializerDidStart(_ initializer: AppInitializer) {
        Analytics.logEvent("initialization_started", parameters: [
            "initializer_name": initializer.name,
            "priority": initializer.priority.rawValue
        ])
    }
    
    func initializerDidFail(_ initializer: AppInitializer, error: Error) {
        Analytics.logEvent("initialization_failed", parameters: [
            "initializer_name": initializer.name,
            "error_description": error.localizedDescription
        ])
    }
    
    // initializerDidComplete is not implemented since we don't need to track completion events
}
```

### Registering Your Events Delegate

Connect your events delegate to the InitManager when you create it:

```swift
let eventTracker = InitializationEventTracker()
let initManager = InitManager(
    initializers: [
        EventManagerInitializer(),
        FeatureTogglesInitializer()
    ],
    eventsDelegate: eventTracker
)
```

#### Local Logging Example

Here's an example of implementing the delegate for local debugging. This implementation
tracks the progress of each individual initializer.

```swift
class DebugEventTracker: AppInitializerEventsDelegate {
    func initializerDidStart(_ initializer: AppInitializer) {
        print("📱 Starting initialization: \(initializer.name)")
    }
    
    func initializerDidComplete(_ initializer: AppInitializer) {
        print("✅ Completed initialization: \(initializer.name)")
    }
    
    func initializerDidFail(_ initializer: AppInitializer, error: Error) {
        print("❌ Failed initialization: \(initializer.name)")
        print("Error: \(error.localizedDescription)")
    }
}
```

#### Firebase Analytics Example

For production analytics tracking with Firebase, you might want to track only specific initializtion events. 
Here's an example that focuses on tracking failures and completions while ignoring start events:

```swift
class FirebaseEventTracker: AppInitializerEventsDelegate {
    func initializerDidComplete(_ initializer: AppInitializer) {
        Analytics.logEvent("app_init_complete", parameters: [
            AnalyticsParameterItemName: initializer.name,
            "priority": initializer.priority.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func initializerDidFail(_ initializer: AppInitializer, error: Error) {
        Analytics.logEvent("app_init_error", parameters: [
            AnalyticsParameterItemName: initializer.name,
            "error_type": String(describing: type(of: error)),
            "error_message": error.localizedDescription,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // initializerDidStart is not implemented since we don't need to track start events
}
```
