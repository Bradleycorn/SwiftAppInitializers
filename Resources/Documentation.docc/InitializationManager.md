#  Executing Initializers

Using an InitManager to perform app initialization

## Overview
Once you have defined a set of initializers, you'll register them with an ``InitManager``. 
The ``InitManager`` will run initializers at the right time, and in the right order automatically, 
and exposes a set of `Publisher`s that you can use to monitor initialization progress and state.

If ``AppInitializer``s are the heart of the Initializers system, then the ``InitManager`` is the brain. 
It, manages dependencies, and executes the right initializers based on their priority at the appropriate time, 
and publishes initialization progress as state. The <doc:MonitoringState> guide shows how to react to changes
in initialization state and update your application's UI.

### Creating an InitManager
Your ``InitManager`` will likely live in your main `App` struct, so that it can execute ``InitializerPriority/appLaunch`` initializers
as soon as your app launches. Create an instance by calling it's primary initializer method. It takes a single argument, an array
of ``AppInitializer``s that it should manage. (You can optionally also pass in a delegate object to get notified when initialization events take place. See <doc:MonitoringState> for more information.)

```swift
let initManager = InitManager([
    EventManagerInitializer(),
    FeatureTogglesInitializer(),
    FavoritesInitializer()
])
```
The passed in array can list initializers in any order. The ``InitManager`` will take care of resolving dependencies and determining execution order.
You also do not need to distinguish between ``InitializerPriority/appLaunch`` and ``InitializerPriority/appActive`` initializers. Pass a single list 
with all of them to the manager's initiallizer.

> Tip: Create a singleton instance of ``InitManager`` in your main `App` struct, and let it manage all of your ``AppInitializer``s. You should not create separate managers for different groups of intializers. 

### App Lifecycle Integration
The ``InitManager`` automatically integrates with your app's lifecycle by observing notifications from the Notification Center. When you create an instance of InitManager, it automatically:

1. Starts the launch initialization process, executing initializers that have ``InitializerPriority/appLaunch`` priority.
2. Registers for notifications to handle app state changes (foreground/background)
3. Executes initializers that have ``InitializerPriority/appActive`` priority when the app enters the foreground
  a. Cancels initialization routines that are currently running if the app leaves the foreground. 
