#  Managing Dependencies
Executing App Initializers in the proper sequence

## Overview

As your app grows and you create several App Initializers, you will likely need
to ensure that some initializers executed in a specific order. This is accmomplished
by establishing dependencies when you are <doc:DefiningInitializers#Setting-Order-of-Execution>.

> tip: You only need to specifiy dependencies for an ``AppInitializer`` if it cannot complete without
some other Initializer(s) being completed first. 

For example, you might define an initializer that fetches some data from an API and stores it locally, 
and a second initializer that passes some of that data as a parameter in another API call. When defining 
the second initializer, you should list the first initializer in the ``AppInitializer/dependencies`` 
array. When your initializers are executed, the ``InitManager`` will resolve the dependency and make 
sure that the first initializer is executed to completion before the second initializer is executed. 

### Listing Dependencies

When <doc:DefiningInitializers>, you need to list the immediate dependencies that an Initializer has
on other Initializers. However, The ``InitManager`` is designed to intelligently resolve those dependencies
and execute intitializers in the proper order. There's no need for you to keep track of child dependencies, 
or manage large dependency trees, etc. In nearly all cases, you only need to list
the immediate dependencies of your Initializer, you can list them any order, and you do not need to worry
about the ``InitializerPriority`` of dependencies either. 

The only thing you do have to consider, is avoding <doc:#Circular-Dependencies>.


### Dependencies and Initializer Priority

As explained in <doc:DefiningInitializers>, each Initializer has a priority, and the ``InitManager``
runs initializers in groups based on their priority. For example, all ``InitializerPriority/appLaunch``
initializers are run to completion before ``InitializerPriority/appActive`` initializers are executed.

> Tip: When defining an ``AppInitializer`` and listing it's dependencies, you do not need to be concerned with
the ``InitializerPriority`` of the dependencies. It

If you define an ``InitializerPriority/appLaunch`` initializer that has a dependency on an
``InitializerPriority/appActive`` initializer, the ``InitManager`` will resolve the dependency and run
the ``InitializerPriority/appActive`` dependency during App Launch. However, when the App Active `Task`
is executed, your initializer with ``InitializerPriority/appActive`` priority will be executed again. 

> Warning: If an initializer with ``InitializerPriority/appLaunch`` priorty declares a dependency on
an initializer with ``InitializerPriority/appActive``, the ``InitializerPriority/appActive`` initializer
will get executed twice at app startup, once during the "launch" `Task` (to satisfy the dependency), and
again during the "app active" `Task`. 

### Defining Multiple Dependencies

In some cases, a single ``AppInitializer`` might need to wait for several other initializers to complete
before it executes. In this case, list all of the dependencies that the initializer requires in its
``AppInitializer/dependencies`` list. 

> Tip: When listing multiple dependencies, you do not need to list them in any particular order. 
The ``InitManager`` will resolve them properly, regardless of the order in which they are listed. 

#### Nested Dependencies
Sometimes, a dependency that you declare might have it's own (child) dependencies. You do not need to list
the "child dependencies" in your Initializer.

For example, Initializer B lists a dependency on Initializer A. Now you are defining a new Initializer C, 
and it has a dependency on Initializer B. So:
```
C -> B -> A
```
When defining Initializer C and listing its dependencies, you should _only_ add Initializer B to the list.
The ``InitManager`` will take care of resolving the child dependency and executing the initializers in the 
proper order (A, then B, then C).

> Tip: When defining an Initializer, you only need to list its immediate dependencies. The ``InitManager``
will resolve any nested dependencies on its own and execute them in the proper order.

#### Circular Dependencies

The ``InitManager`` will intelligently resolve all dependencies among your initializers and execute them
in the proper order. However, it cannot properly resolve a circular dependency and it is your responsibility
to avoid this situation. 

> Warning: If the ``InitManager`` detects a circular dependency, initialization will fail with
``AppInitializationError/circularDependency(_:)`` error.

For example, You have three Intializers A, B, and C. When defining your initializers, Initializer C lists 
a dependency on Initializer B. Initializer B lists a dependency on Initializer A. Now you decide that 
Initializer A should wait for Initializer C to complete before it executes, so you update Initializer A to list
a dependency on Initializer C. Now you have created a circular Dependency. 

```
C -> B -> A
 ↖________/
```

In this situtation, the ``InitManager`` cannot determine which initialzer to execute first. The initialization
state will be set to ``InitializationState/failed(error:)`` with a ``AppInitializationError/circularDependency(_:)``
error. 
