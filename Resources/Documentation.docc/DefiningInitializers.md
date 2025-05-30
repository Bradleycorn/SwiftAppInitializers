#  Defining App Initializers

Creating tasks to be run at startup

## Overview

An App Initializer represents a single task that your app needs to execute at launch or when the app becomes "active". 
You may define several app initializers to complete various tasks that need to happen at startup. 

App Initializers are the heart of the framework. The ``AppInitializer`` protocol defines a concise set of properties
and methods that work together to define:
- An initialization task to be done.
- _When_ the task should be executed.
- The task's dependencies (any other ``AppInitializer``s that need to be completed first). 

### Creating an AppInitializer

To create an app initializer, define a class that conforms to the ``AppInitializer`` protocol. 

> Important: An AppInitializer should perform a single task only, such as fetching data from an API and storing it in a 
database, or initializing a third party SDK. Avoid writing initializers that perform multiple tasks. It will 
limit your flexibility and control over when tasks happen as your app grows and you need to add additional initializers.
You can use dependencies to ensure your initializer are executed in the proper order.

A complete example looks like this:
```swift
class FavoritesInitializer: AppInitializer {
    private let favoritesRepo: FavoritesRepository

    init(favoritesRepo: FavoritesRepository) {
        self.favoritesRepo = favoritesRepo
    }

    var priority: AppInitializers.InitializerPriority = .appLaunch
    
    var dependencies: Array<any AppInitializers.AppInitializer.Type> = [
        EventManagerInitializer.self, 
        FeatureTogglesInitializer.self
    ]
    
    func run() async throws {
        try await favoritesRepo.fetchUserFavorites()
    }
}

```


#### Setting Initializer Priority
When defining an ``AppInitializer`` you must specify its priority:

```swift
var priority: AppInitializers.InitializerPriority = .appLaunch
```

The priority determines _when_ your initializer task gets executed. The
``InitManager`` executes Initializers as various times during your app's
lifecycle, such as at app launch, or whenever the app becomes "active". 
When you set an ``InitializerPriority`` on your App Initializer,
you are telling the ``InitManager`` at what point during the app lifecycle
the initializer should be executed.

Some app lifecyle phases may be triggered multiple times. For example, when
your app is launched and then enters the foreground, it becomes "active". 
The user may then put your app in the background while using another app, 
and then later bring your app back to the foreground. 
At this point your app re-enters the "active" phase.

Because of this, App Initializers with a priorty that matches one of these
"repeating" phases will get re-executed each time the app enters that phase.

> Tip: At startup, ``InitializerPriority/appActive`` tasks are only executed _after_  all ``InitializerPriority/appLaunch`` tasks are complete.

> Note: It is possible for an Initializer with an
``InitializerPriority/appActive`` priority to be executed during
the app launch phase. See <doc:ManagingDependencies> for more information.

#### Setting Order of Execution

Dependencies control the order of execution when you register multiple initializers. 

```swift
var dependencies: Array<any AppInitializers.AppInitializer.Type> = [
    EventManagerInitializer.self, 
    FeatureTogglesInitializer.self
]
```

Use the ``AppInitializer/dependencies`` to set an Array of any other Initializers that 
should be executed to completion _before_ your initializer gets executed. The order in 
which you list dependencies is not important. The ``InitManager`` will analyze and 
resolve all dependencies and ensure that they get executed in the correct order. 

You also do not need to worry about the priority of initializers that you list
as dependencies. If your initializer is an ``InitializerPriority/appLaunch`` initializer,
you can include a dependency on an Initializer with an ``InitializerPriority/appActive``
priority. The ``InitManager`` will honor your dependency and execute it during the 
app launch cycle.

> Tip: When defining dependencies, you do **not** need to worry about the order in which they are defined
or their priority. The InitManager will manage these details and execute all dependencies in the correct order. See <doc:ManagingDependencies> for more information.

> Warning: When defining deppendenies, be cautious not to create a circular dependency among your initializers. The InitManger will throw an Error if a circular dependency is found. See <doc:ManagingDependencies#Circular-Dependencies> for more information.

#### Defining the Task to be Performed

Implement the ``AppInitializer/run()`` method to define the work that your initializer does:

```swift
func run() async throws {
    try await favoritesRepo.fetchUserFavorites()
}
```

``AppInitializer/run()`` is an `async` method. The ``InitManager`` runs initializers in a Swift Task, allowing you to use 
structure concurrency to perform asynchronous tasks like fetching data from a web API, or updating a local
database. 

> Note: Although initializers are `async`, they are not executed concurrently. The InitManager executes each
initializer to completion before executing the next one. This ensures that dependencies are completed first,
and that errors are properly handled.
