# ``AppInitializers``

Define and execute initialization tasks at App Startup

## Overview

App Initializers provides a modular solution for performing initialization tasks that need to happen at application 
startup and/or when the app is brought to the foreground after being in the background. You define a set of tasks
to be performed each time your app is launched, or when the app becomes "active". Then you register the tasks with an 
Initialization Manager that the framework provides, and it takes care of the rest!

The framework is best suited for app initialization tasks that need to run on their own without user interaction. 
For example, loading some data from an API, or initializing a third party SDK. In the future it may be 
possible to use Initializers to do work that does require usre interaction, like prommpting to enabe push 
notifications, or prompting to enable location services.



## Topics

### Essentials
- <doc:DefiningInitializers>
- <doc:InitializationManager>
- <doc:MonitoringState>
- <doc:ErrorHandling>
- <doc:ManagingDependencies>

