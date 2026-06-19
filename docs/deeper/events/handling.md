---
title: Handling Events
---

# Handling Events

A **handler** is the callback that actually does the work when an event fires.
You attach handlers to events with the listener methods described in
[Listening to Events](listening.md).  A handler can be a plain function, a
callable class, or one of many methods grouped into a
[subscription](#subscriptions).

## The Handler Contract

Every handler receives a **single argument**, the `event`:

```python
def my_handler(event):
    ...
```

What `event` *is* depends on how the event was dispatched:

- **Class based event** - `event` is the event instance itself, so you read the
  payload straight off its constructor attributes (`event.post`).
- **String based event** - `event` is a [SuperDict](../superdict.md) containing
  your payload merged with two extra keys, `event.name` and `event.description`.
  So a payload of `{'post': post}` is reachable as `event.post`, alongside
  `event.name`.

In both cases there is just one parameter to remember.

---

## Callable Handlers

The simplest handler is anything Python considers callable, a function works
perfectly:

```python
from acme.wiki.events.post import Created as OnPostCreated

def my_handler(event):
    # For a class event, the payload lives on the instance
    post = event.post
    # ...do work when this event is dispatched

OnPostCreated.listen(my_handler)
```

Async handlers are just as welcome, dispatch them with `codispatch()` /
`dispatch_async()`:

```python
async def my_handler(event):
    await send_email(event.post)

OnPostCreated.listen(my_handler)
```

!!! tip
    Under asynchronous dispatch, Uvicore inspects each handler.  Coroutine
    handlers are `await`ed, and plain synchronous handlers are run in a threadpool
    so they never block the event loop.  You are free to mix both.

---

## Class Handlers

For anything beyond a quick function, a dedicated handler class keeps things
tidy.  Convention is to drop them in a `handlers` folder.  A handler class
inherits from `Handler` and implements `__call__(self, event)`, the instance is
called directly when the event fires:

```python title="handlers/notify_users.py"
from uvicore.events import Handler
from acme.wiki.events.post import Created as OnPostCreated

class NotifyUsers(Handler):

    def __call__(self, event: OnPostCreated):
        # event is the Created instance, so event.post is your payload
        # ...do work when this event is dispatched
        ...
```

Register it by class or by string path, Uvicore instantiates it for you either
way:

```python
OnPostCreated.listen(NotifyUsers)
# or
OnPostCreated.listen('acme.wiki.handlers.NotifyUsers')
```

`__call__` may also be `async def` when the event is dispatched asynchronously.
This is exactly the pattern the framework uses internally, for example to
bootstrap the database once the application has booted.

---

## Subscriptions

A **subscription** is a single class that both *listens to* one or more events
and *handles* them, a great way to keep a related cluster of listeners in one
file.  Each handler method takes the usual single `event` argument, and the
`subscribe()` method wires everything up:

```python title="listeners/app_event_subscription.py"
from uvicore.contracts import Dispatcher

class AppEventSubscription:

    def app_registered(self, event):
        # Runs once the framework has registered all providers
        ...

    def app_booted(self, event):
        # Runs once the framework has booted all providers
        ...

    def post_created(self, event):
        # Runs whenever a wiki post is created
        ...

    def subscribe(self, events: Dispatcher):
        # Declare which events map to which handlers, all in one place
        events.listen('uvicore.foundation.events.app.Registered', self.app_registered)
        events.listen('uvicore.foundation.events.app.Booted', self.app_booted)
        events.listen('acme.wiki.post.Created', self.post_created)
```

Register the subscription from your provider with `self.events.subscribe(...)`,
as shown in [Registering a Subscriber](listening.md#registering-a-subscriber).
Uvicore imports the class, instantiates it, and calls its `subscribe()` method,
handing it the dispatcher so it can register all of its listeners at once.
