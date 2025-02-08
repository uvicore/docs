# Events


---

Notes on 0.2.7
Fixed event system
need to update docs
no more event,payload, just event:Dict or event:Class
talk about listen decorator
async __call__ does work
talk about priority, default 50 etc...
---





Uvicore provides an observer (pub/sub) implementation allowing you to listen
(subscribe) to events that occur in the framework and in your own packages.

Events are a great way to decouple various aspects of your project.  A single
event can have many listeners that need not depend on each other.  For example,
each time a wiki post is created you may wish to send an email or slack
notification to all watchers of the post.

Events allow for the `O` in `S.O.L.I.D` which mean code is Open for extension but closed for modification.  You can extend functionality to existing code (that fires events) without touching the code itself.  Be sure to add event to your code at the beginning to allow other developers to listen to those events and extend their own functionality with their own handlers!

Events are dispatched throughout the framework and many other packages.  When an
event is dispatched all defined listeners will be called in order they were
added.  Listeners define the event(s) to watch and the event handlers (callbacks)
to fire when then event is dispatched.  Handlers can be methods, classes or
even bulk listening/handling `subscriptions`.


## :material-pound: Defining Your Own Events


You may define events in two ways.

1. With a Class that holds a strictly defined payload (via the constructor)
2. As a simple string with a loosely defined dictionary payload.


### :material-pound: :material-pound: Class Based Events

Class based events not only provide a stricter interface, but they also bind themselves to the [IoC](/deeper/ioc/) allowing you to view all Class based events using the `./uvicore event list` CLI as long as that file has been `imported` in your packages provider.

The benifits of an event class are that you can force the payload requirements
using the class `__init__()` constructor.  An event class performs NO work.  It
is simply a data container for the payload itself.  Event classes are typically
stored in the `events` directory of your package.

```python
# events/post.py
import uvicore
from uvicore.events import Event
from acme.wiki.models import Post

@uvicore.event()
class Created(Event):

    # Events are either synchronous or asynchronous
    is_async = True

    def __init__(self, post: Post):
        self.post = post
```


### :material-pound: :material-pound: String Based Events


String based events are not known ahead of time, so they are harder to discover.  Read the package developers documentation to learn about the events they may fire.

The event strings can be whatever you like, however it is best practice to name the string as if it were going to be an actual event class someday.  For example `acme.wiki.events.post.Created`. If at some point you want to create the actual class, all existing listeners that use that string will not need to be changed as the system looks for a class of the same name to instantiate.

Examples of string based events can be found in the ORM Model

!!! note "See The Code on Github"
    - [model.py](https://github.com/uvicore/framework/blob/master/uvicore/orm/model.py)
    - Search for 'def _before_insert' to see examples of:
        - `event_name = 'uvicore.orm-{' +  self.__class__.modelfqn + '}-BeforeInsert'`
        - `await uvicore.events.codispatch(event_name, {'model': self})`



## :material-pound: Dispatching Events

You can fire off (dispatch) an event in a few different ways.  Where
you fire off the event is up to your own code.  With the Wiki events
example above the proper place may be in your controller, model or job that
Creates and Deletes wiki posts.  Wherever the location, firing off an event
is simple.

!!! note
    Events are defined as either synchronous or asynchronous.
    Uvicore provides the synchronous `diaptch()` method and the asynchronous `codispatch()` method.


### :material-pound: :material-pound: Dispatch Class Based Events

Dispatch using `events.dispatch()` or `events.codispatch()`

```python
from uvicore import events
from acme.wiki.events import Created

# Using the events.dispatch() method to pass in the class instance
events.dispatch(Created(post))
await events.codispatch(Created(post))
```

Dispatch using the instantiated class `.dispatch()` or `.codispatch()` methods

```python
# Or by using the event classes build-in .dispatch() method
Created(post).dispatch()
await Created(post).codispatch()
```

Dispatch using string dot notation.  Since we defined the Class in the same path, Uvicore will detect the class and Instantiate it with the Dictionary payload as **kwargs into the constructor!
```python
# Or by using the event classes build-in .dispatch() method
events.dispatch('acme.wiki.events.post.Created', {'post': post})
await events.codispatch('acme.wiki.events.post.Created', {'post': post})
```


### :material-pound: :material-pound: Dispatch String Based Events

String based events work with or without a matching event class.

You can simply have an event named `xyz` and dispatch it with `events.dispatch('xyz', {'payload1': 'test'})`

If however you name your class like so `acme.wiki.events.post.Created` AND there happens to be an event Class with the same python module path, that event class will be used. It will be Instantiated, and the dictionary will be passed to the constructor as **kwargs.


```python
from uvicore import events
events.dispatch('acme.wiki.events.post.Created', {'post': post})
await events.codispatch('acme.wiki.events.post.Created', {'post': post})
```





## :material-pound: Listening to Events

Registering and then dispatching events does nothing if there is no one listening.
Listeners define callbacks that are executed when an event is dispatched.

The best place to register your event listeners is in your package provider `register()` method which has a shortcut of `self.events`

!!! tip
    Your event `.listen(), .listener(), .handle(), .handler() and .call()` are all alias of each other.  Use whichever verbiage makes the most sense to you.


### :material-pound: :material-pound: Listening to Class Based Events

```python
from acme.wiki.events.post import Created as OnPostCreated

@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:
        # Use a callback.
        # .listen(), .listener(), .handle(), .handler() and .call() are all aliases
        OnPostCreated.listen(self.NotifyUsers)
        OnPostCreated.listener(self.NotifyUsers)
        OnPostCreated.handle(self.NotifyUsers)
        OnPostCreated.handler(self.NotifyUsers)
        OnPostCreated.call(self.NotifyUsers)

        # Use a string based handler which Uvicore will instantiate for you
        OnPostCreated.listen('acme.wiki.listeners.NotifyUsers')
        # Or call it the handler folder
        OnPostCreated.handler('acme.wiki.handlers.NotifyUsers')

```

### :material-pound: :material-pound: Listening to String Based Events


**From within your Provider**

Your package provider already has `self.events` available to you!


```python
from acme.wiki.events.post import Created as OnPostCreated

@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:
        # Use a local method (function) as the callback
        self.events.listen('acme.wiki.post.Created', self.NotifyUsers)

        # Use a listener class as the callback
        self.events.listen('acme.wiki.post.Created', 'acme.wiki.listeners.NotifyUsers')
```

**From anywhere in Code**

If not in your package provider, you can simply use `uvicore.events` or `from uvicore import events` etc...

```python
from uvicore import events
events.listen('acme.wiki.post.Created', self.my_handler)
events.subscribe('acme.wiki.listeners.HttpEventSubscription')
```


!!! info
    For string based handlers, the `acme.wiki.listeners.NotifyUsers` class is defined as a
    string in dot notation.  The event system will automatically instantiate
    and call the class `handle()` method during dispatch.


### :material-pound: :material-pound: Listening to Multiple Events

**Listen to multiple events**

```python
from acme.wiki.events.post import Created as OnPostCreated

@uvicore.provider()
class Wiki(Provider):

    def register(self) -> None:
        # Use a local method (function) as the callback
        self.events.listen([
            'acme.wiki.post.Created',
            'acme.wiki.post.Deleted',
        ], self.NotifyUsers)

        # Use a string based handler
        self.events.listen([
            'acme.wiki.post.Created',
            'acme.wiki.post.Deleted',
        ], 'acme.wiki.listeners.NotifyUsers')
```


### :material-pound: :material-pound: Listening to wildcard events

```python
from acme.wiki.events.post import Created as OnPostCreated

@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:
        # Use a local method (function) as the callback
        self.events.listen('uvicore.foundation.events.*', self.NotifyUsers)

        # Use a listener class as the callback
        self.events.listen('uvicore.foundation.events.*', 'acme.wiki.listeners.NotifyUsers')

        # The * wildcard also works in the middle of an event name
        self.events.listen('acme.wiki.models.*.Deleted', self.LogDeletions)
```


### :material-pound: :material-pound: Registering a subscriber

A subscription is an all-in-one class which listens to one or more events and
also contains the handlers for each event.  Notice we are not defining the
event to listen to here.  We simply define the subscription class.  See
[Handling Events](#handling-events) for what these classes look like.
```python
# From service provider register() method
self.events.subscribe('acme.wiki.listeners.HttpEventSubscription')
```


## :material-pound: Handling Events

Handlers are callbacks that are dispatched when an event fires.  Handlers are
defined using `.listen(), .listener(), .handle(), .handler() .call() or .subscribe()` methods as noted in
[Listening To Events](#listening-to-events).

Handlers can be basic python methods (functions) or dedicated handler classes.

All handlers receive an `event: Dict` and `payload: Any`.  The `event`
dictionary is the metadata for an event that was defined by the developer
during the event registration.  If the event listener is a class, the payload
will be an instance of that class with properties of all constructor parameters.
If the event listener is just a string, the payload is a `namedtuple` of
parameters.


### :material-pound: :material-pound: Callable Handlers

Basically anything in python that is callable.

```python
# Handler Example
def my_handler(event: Dict, payload: Any) -> None:
    # Do work when this event is dispatched.

# Listener Example which calls the handler
from acme.wiki.events.post import Created as OnPostCreated
OnPostCreated.listen(my_handler)
```

You can evn use a Class with a magic `__call__` method on it..that class is technically now "callable"!

```python
# Handler Example
from uvicore.events import Handler
from acme.wiki.events.post import Created as OnPostCreated
class MyHandler(handler):
    def __call__(self, event: OnPostCreated)
    # Do work when this event is dispatched.

# Listener Example which calls the handler
OnPostCreated.listen(MyHandler)
```


### :material-pound: :material-pound: Class Handler

A good practice is to make yourself a `handlers` folder with handler classes.  The `handle()` method will be called when the even is fired.


```python
from typing import Dict, Any
from uvicore.events.handler import Handler

class NotifyUser(Handler):

    def handle(self, event: Dict, payload: Any):
        # Instance variable self.app is also available to you
        # Do work when this event is dispatched.
```


### :material-pound: :material-pound: Subscription Handler

Subscriptions are a great way to listen and handle multiple events from a single
file.

```python
from typing import Dict, Any
from uvicore.contracts import Dispatcher

class AppEventSubscription:

    def app_registered(self, event: Dict, payload: Any):
        #  Do something when then the framework is done registering all providers

    def app_booted(self, event: Dict, payload: Any):
        #  Do something when then the framework is done booting all providers

    def post_created(self, event: Dict, payload: Any):
        #  Do something when a wiki post is created

    def subscribe(self, events: Dispatcher):
        # A subscription is an all in one class that can both listen AND handle
        # one or more events in a single place.
        events.listen('uvicore.foundation.events.app.Registered', self.app_registered)
        events.listen('uvicore.foundation.events.app.Booted', self.app_booted)
        events.listen('acme.wiki.post.Created', self.post_created)
```
