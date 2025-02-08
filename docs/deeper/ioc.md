# IoC

Uvicore has a custom Inversion of Control (IoC) container that it uses to register all important classes into a singleton object (the container).  Uvicore does this by using `decorators` atop each of the services.

Once these services are registered with the `IoC`, then can be swapped out by your applications config on-demand.  This means you can overwrite everything in Uvicore, even the frameworks core foundational components!

