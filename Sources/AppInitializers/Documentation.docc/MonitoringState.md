#  Monitoring Initialization State
Taking action when initialization completes or fails

## Overview

Now that your app is performing initialization, you will likely want to observe the initialization state 
and update your UI accordingly when initialization completes or fails.

the ``InitManager`` exposes the initialization state and you can react to changes in that state to provide
appropriate user experiences. For example, wait until all launch initializers are complete before rendering
your application content, and show a "splash screen" while initializations are running. Or show an overlay
with a "loading spinner" when your app returns from the background until all ``InitializerPriority/appActive``
initializers are complete.

### Initialization States

The ``InitializationState`` enum defines the different states of initialization:
- ``InitializationState/pending``: Initialization is currently running, or has not started yet.
- ``InitializationState/complete``: Initialization has been run and completed successfully.
- ``InitializationState/failed(error:)``: Initialization has been run and failed with the associated `Error`. 

### Observing the Current Initialization State

The ``InitManager`` exposes several Combine Publishers that allow you to monitor and react to changes initialization state. 

- ``InitManager/launchState``: The current state of initializers with the ``InitializerPriority/appLaunch`` priority.
- ``InitManager/activeState``: The current state of initializers with the ``InitializerPriority/appActive`` priority.
- ``InitManager/state``: A composit of the ``InitManager/launchState`` and ``InitManager/activeState``:
  - If _either_ value is ``InitializationState/failed(error:)``, then the composite state will also be ``InitializationState/failed(error:)``
  - if _both_ values are ``InitializationState/complete``, then the composite state will also be ``InitializationState/complete``.
  - Otherwise the composite state will be ``InitializationState/pending`` (because at least one of the active/launch states is pending, and neither of them are failed).

### Reacting to Initialization State Changes

You can use any or all of the state values to control the display of your application content. 

#### Modeling Initialization State

A typical SwiftUI architecure will employ an `ObserveableObject` (or an `@Observable` instance in iOS17+)
to model application state. This model is a good place to consume the ``InitManager``'s state publisher(s),
and expose the current state to the application. 

In this example, an application state model exposes a single application state based on the
composite ``InitManager/state`` publisher.

```swift
class CompositeAppState: ObservableObject {
    private let initManager: InitManager

    @Published
    private(set) var uiState: InitializationState

    init(initManager: InitManager = AppInitModule.shared.initManager()) {
        self.initManager = initManager

        //Assign the initManger's `state` publisher to the uiState property.
        self.initManager.state.assign(to: &$uiState)
    }
}
```

You may wish to react to the ``InitManager/launchState`` and ``InitManager/activeState`` changes independently.
The following model exposes each state as a separate `@Published` property.

```swift
class IndependentAppState: ObservableObject {
    private let initManager: InitManager

    @Published
    private(set) var launchState: InitializationState

    @Published
    private(set) var activeState: InitializationState

    init(initManager: InitManager = AppInitModule.shared.initManager()) {
        self.initManager = initManager

        //Assign the initManger's `launchState` publisher to the launchState property.
        self.initManager.lauchState.assign(to: &$launchState)

        //Assign the initManger's `activeState` publisher to the activeState property.
        self.initManager.activeState.assign(to: &$activeState)
    }
}
```
#### Updating The Application UI

In the following example, the above `CompositeAppState` model is used to show a splash screen 
until all ``AppInitializers`` are complete, and shows an error if initialization fails. 

```swift
@main
struct MyApp: App {

    //Create and observe an AppState() instance
    @ObservedObject
    private var appState = CompositeAppState()
    
    var body: some Scene {
        WindowGroup {

           // Update the UI when the appState.uiState published property changes.
           switch (appState.uiState) {
           case .pending:
               SplashScreen()
           case .failed(let error):
               AppErrorScreen(error)
           case .completed:
               AppContent()
           }
        }
    }
}    
```

The next example uses the `IndependentAppState` eaxampe model
to show a splash screen at app launch and a "loading" modal when the ``InitializerPriority/appActive``
initializers are running.

```swift
@main
struct MyApp: App {
   @StateObject
   private var appState = IndependentAppState()

   var body: some Scene {

    // Create a "one way" binding to the activeState
    // and map it to a Bool to control display of the loading modal
    let showLoadingModal = Binding(
        get: { appState.activeState == .pending }
        set: { _ in } // do nothing. The AppState model controls the state.
    )

    MyAppContent {
         switch (appState.launchState) {
            case .pending:
               SplashScreen()
            case .complete:
               AppContent()
                    .fullScreenCover(isPresented: showLoading) {
                        Text("Please Wait ... ")
                            .interactiveDismissDisabled() // don't allow the user to swipe the cover away
                    }
            case .failed(let error):
               LoadingFailed(reason: error)
          }
      }
   }
}
```

