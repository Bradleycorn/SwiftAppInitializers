#  Error Handling
Taking action when initialization fails

## Overview

If an error occurs during App Initialization, you very likely will want to know about
it so that you can alert the user and take appropriate action. 

All errors are caught internally by the ``InitManager``. 
When an error occurs, the ``InitManager`` will catch it internally, stop execution of 
all App Initializers, and set the appropriate Initialization State value 
to ``InitializationState/failed(error:)``. When <doc:MonitoringState> in your app,
you can react to a failed initialization state and take a appropriate action.


App Initializers are executed in sequence, one at a time. When any error is thrown during 
execution of an Initializer the initialization `Task` will stop immediately, and no further 
Initializers will be executed.

If an Error occurs while executing the App Launch Initializers, not 
only will will the launch `Task` stop, but the `Task` for App Active Initializers
will also never be executed. The App Active intiailizers are only ever executed
after the App Launch Initializers are completed successfully.

If an Error occurs while executing the App Active Initializers, the `Task`
will stop immediately, and the Active State will be updated to indicate the failure.
However, if the app becomes "active" again (for example, if the user puts
your app into the background to use another app, and then returns to it later), the 
App Active `Task` will get executed again, and each initializer with ``InitializerPriority/appActive`` priority
initializer will be run again. 

> Warning: Each time your app becomes "active", The InitManager will attempt
to execute all ``InitializerPriority/appActive`` initializers, even if they threw an error
on a previous attempt. 

### Failed Initialization Error Types
Initialization can fail for a variety of reasons. 
The ``InitializationState/failed(error:)`` initialization state will contain an ``AppInitializationError``
that you can use to get information about:
- Why the initialization failed.
- Which ``AppInitializer`` caused the failure.
- The underlying `Error` that was thrown. 

See ``AppInitializationError`` for more information about the types of errors that can happen during
initialization.

