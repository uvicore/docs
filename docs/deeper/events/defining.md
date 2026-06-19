---
title: Defining Events
---

# Defining Your Own Events

You may define an event in two ways, and both are first class citizens.

1. As a **class** that holds a strictly defined payload (via its constructor).
2. As a simple **string** with a loosely defined dictionary payload.

Reach for a class when you own the event and want a discoverable, well typed
interface.  Reach for a string when you want something quick, or when you are
firing a great many similar events dynamically (the way the ORM does, one per
model).

---

## Class Based Events

A class based event gives you a stricter, self-documenting interface, and it
binds itself into the [IoC Container](../ioc.md).  That binding is what lets you
discover every class based event in your app with `./uvicore event list`, as
long as the module has been imported (which happens naturally when it is
referenced from your package provider).

The real benefit of an event class is that the constructor *defines and enforces*
the payload.  An event class performs **no work** of its own, it is simply a
typed container for the data you hand to its listeners.  Event classes are
conventionally stored in the `events` directory of your package.

```python title="events/post.py"
import uvicore
from uvicore.events import Event
from acme.wiki.models import Post

@uvicore.event()
class Created(Event):
    """A wiki Post was created."""

    # Events are either synchronous or asynchronous.  Defaults to False (sync).
    is_async = True

    def __init__(self, post: Post):
        self.post = post
```

A few things are happening here:

- **`@uvicore.event()`** binds the class into the IoC as an `event` so it shows
  up in `./uvicore event list`.
- **`is_async`** declares whether the event should be dispatched synchronously or
  asynchronously.  It defaults to `False`.  See [Dispatching Events](dispatching.md).
- **The docstring** becomes the event's `description`, and the fully qualified
  class path (here `acme.wiki.events.post.Created`) becomes its `name`, both
  visible from the CLI.
- **The constructor** is your payload contract.  Whatever you assign to `self`
  (like `self.post`) is exactly what your handlers receive on the `event` object.

---

## String Based Events

String based events are not declared ahead of time, which makes them quicker to
fire but harder to discover, so a package's string events live in its
documentation rather than in `./uvicore event list`.

The string can be anything you like, but the best practice is to name it as if it
*were* a real event class one day, for example `acme.wiki.events.post.Created`.
If you later promote it to an actual class at that same module path, every
existing listener keeps working unchanged, because the dispatcher will find the
matching class and instantiate it for you (passing your payload dictionary as
`**kwargs` to the constructor).

The framework itself uses string based events extensively in the ORM, where one
dynamic event is fired per model on every insert, save and delete:

```python title="uvicore/orm/model.py (simplified)"
event_name = 'uvicore.orm-{' + self.__class__.modelfqn + '}-BeforeInsert'
await uvicore.events.codispatch(event_name, {'model': self})
```

!!! note "See the code on GitHub"
    Browse [model.py](https://github.com/uvicore/framework/blob/master/uvicore/orm/model.py)
    and search for `_before_insert` to see the full set of model events.  They are
    all catalogued for you in [Built-in Events](builtin.md#orm-model-events).
