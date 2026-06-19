---
title: Listening to Events
---

# Listening to Events

Registering and dispatching events accomplishes nothing if no one is listening.
A **listener** ties an event to a handler (a callback) that runs when the event
is dispatched.

The best place to register your listeners is your package provider's
`register()` method, which conveniently exposes the dispatcher as `self.events`.

!!! tip
    The listener methods `listen()`, `listener()`, `handle()`, `handler()` and
    `call()` are all aliases of one another.  Use whichever verbiage reads best to
    you.  (Note that `subscribe()` is *not* an alias, it registers a bulk
    [subscription](#registering-a-subscriber) instead.)

---

## Listening to Class Based Events

A class based event carries its own listener methods, so you register a handler
right off the event class:

```python
from acme.wiki.events.post import Created as OnPostCreated

@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:

        # Use a callback.  listen / listener / handle / handler / call are aliases.
        OnPostCreated.listen(self.notify_users)

        # Or hand it a string path to a handler class, Uvicore will import and
        # instantiate it for you.
        OnPostCreated.listen('acme.wiki.handlers.NotifyUsers')
```

See [Handling Events](handling.md) for what `self.notify_users` and the
`NotifyUsers` class actually look like.

---

## Listening to String Based Events

**From within your provider** you already have `self.events` available:

```python
@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:

        # A local method (function) as the callback
        self.events.listen('acme.wiki.post.Created', self.notify_users)

        # A handler class (string path) as the callback
        self.events.listen('acme.wiki.post.Created', 'acme.wiki.handlers.NotifyUsers')
```

**From anywhere else in your code**, use the `uvicore.events` global:

```python
from uvicore import events
events.listen('acme.wiki.post.Created', my_handler)
```

!!! info
    When you pass a string path like `acme.wiki.handlers.NotifyUsers`, the event
    system imports it, instantiates the class, and calls the instance during
    dispatch.  That means your handler class needs a `__call__()` method, see
    [Class Handlers](handling.md#class-handlers).

---

## Listening with the Decorator

`listen()` (and all its aliases) doubles as a **decorator** when you don't pass a
handler.  This is the cleanest way to wire up a standalone function, and it works
with a single event or a list:

```python
import uvicore

@uvicore.events.handle([
    'uvicore.console.events.command.Startup',
    'uvicore.console.events.command.PytestStartup',
    'uvicore.http.events.server.Startup',
])
async def on_startup(event):
    # Spin up a shared resource once the app starts
    ...
```

This decorator form is exactly how the framework's own packages (like the HTTP
client) bootstrap shared resources on startup and tear them down on shutdown.

---

## Setting a Priority

Every listener method accepts a keyword `priority` (default `50`).  Listeners run
sorted by priority **ascending**, so **lower numbers run first**:

```python
# Bootstrap the console late, after most other services have booted
AppEvents.Booted.listen(bootstrap.Console, priority=90)
```

---

## Listening to Multiple Events

Pass a list to register one handler against several events at once:

```python
@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:

        self.events.listen([
            'acme.wiki.post.Created',
            'acme.wiki.post.Deleted',
        ], self.notify_users)
```

---

## Listening to Wildcard Events

Use a `*` to listen to a whole family of events.  Wildcards are matched as a
regular expression search against each dispatched event name, so they work at the
end *or* in the middle of a name:

```python
@uvicore.provider()
class Wiki(Provider):
    def register(self) -> None:

        # Every foundation event
        self.events.listen('uvicore.foundation.events.*', self.notify_users)

        # The * also works in the middle of a name
        self.events.listen('acme.wiki.models.*.Deleted', self.log_deletions)
```

---

## Registering a Subscriber

A **subscription** is an all-in-one class that both lists the events to watch
*and* holds the handlers for each.  Notice you do not name the event here, the
subscription declares its own interests internally.  See
[Handling Events](handling.md#subscriptions) for the class itself.

```python
# From your service provider's register() method
self.events.subscribe('acme.wiki.listeners.HttpEventSubscription')
```
