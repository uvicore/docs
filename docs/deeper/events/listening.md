# Listening to Events


Registering and then dispatching events does nothing if there is no one listening.
Listeners define callbacks that are executed when an event is dispatched.

The best place to register your event listeners is in your package provider `register()` method which has a shortcut of `self.events`

!!! tip
    Your event `.listen(), .listener(), .handle(), .handler() and .call()` are all alias of each other.  Use whichever verbiage makes the most sense to you.


### :material-pound: Listening to Class Based Events

```python
from acme.wiki.events.post import Created as OnPostCreated

@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:

        # Register event listeners

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

### :material-pound: Listening to String Based Events


**From within your Provider**

Your package provider already has `self.events` available to you!


```python
from acme.wiki.events.post import Created as OnPostCreated

@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:

        # Register event listeners

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


### :material-pound: Listening to Multiple Events

**Listen to multiple events**

```python
from acme.wiki.events.post import Created as OnPostCreated

@uvicore.provider()
class Wiki(Provider):

    def register(self) -> None:

        # Register event listeners

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


### :material-pound: Listening to wildcard events

```python
from acme.wiki.events.post import Created as OnPostCreated

@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:

        # Register event listeners

        # Use a local method (function) as the callback
        self.events.listen('uvicore.foundation.events.*', self.NotifyUsers)

        # Use a listener class as the callback
        self.events.listen('uvicore.foundation.events.*', 'acme.wiki.listeners.NotifyUsers')

        # The * wildcard also works in the middle of an event name
        self.events.listen('acme.wiki.models.*.Deleted', self.LogDeletions)
```


### :material-pound: Registering a subscriber

A subscription is an all-in-one class which listens to one or more events and
also contains the handlers for each event.  Notice we are not defining the
event to listen to here.  We simply define the subscription class.  See
[Handling Events](#handling-events) for what these classes look like.
```python
# From service provider register() method
self.events.subscribe('acme.wiki.listeners.HttpEventSubscription')
```
