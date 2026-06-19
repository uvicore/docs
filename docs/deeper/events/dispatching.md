---
title: Dispatching Events
---

# Dispatching Events

Dispatching is how you *fire off* an event so that every registered listener
runs.  Where you dispatch is entirely up to you, with the wiki `Created` event
from [Defining Events](defining.md) the natural home might be your controller,
model or a background job, anywhere a post is actually created.  Wherever it
lives, firing the event is a one liner.

Every event is either **synchronous** or **asynchronous**, and Uvicore gives you
a matching method for each:

- **`dispatch()`** - synchronous, runs listeners in order and returns.
- **`dispatch_async()`** - asynchronous, must be `await`ed.
- **`codispatch()`** - a friendly alias for `dispatch_async()`, also `await`ed.

!!! note
    Choose the method that matches how your event is declared (`is_async`) and
    where you are calling from.  Async dispatch is tolerant, if a listener happens
    to be a plain synchronous function, Uvicore runs it safely in a threadpool so
    it never blocks your event loop.

---

## Dispatching Class Based Events

Pass an **instance** of your event class to `events.dispatch()` (or its async
sibling):

```python
from uvicore import events
from acme.wiki.events.post import Created

# Synchronous
events.dispatch(Created(post))

# Asynchronous
await events.codispatch(Created(post))
```

Or skip the global and use the event instance's own built-in methods, they do
exactly the same thing:

```python
Created(post).dispatch()
await Created(post).codispatch()
```

You can also dispatch by string, even for a class based event.  Because the
class lives at that exact module path, Uvicore detects it, instantiates it, and
passes your dictionary into the constructor as `**kwargs`:

```python
events.dispatch('acme.wiki.events.post.Created', {'post': post})
await events.codispatch('acme.wiki.events.post.Created', {'post': post})
```

---

## Dispatching String Based Events

String based events work with or without a matching event class.

If there is **no** class at that path, that is perfectly fine, the event still
dispatches and every listener still fires:

```python
from uvicore import events
events.dispatch('xyz', {'payload1': 'test'})
```

If there **is** a class at that exact module path (like
`acme.wiki.events.post.Created`), the dispatcher quietly upgrades the call,
instantiating the class and passing your dictionary to its constructor as
`**kwargs`.  This is what makes it painless to start with a string today and
promote it to a class later, your dispatch and listener code never changes:

```python
from uvicore import events
events.dispatch('acme.wiki.events.post.Created', {'post': post})
await events.codispatch('acme.wiki.events.post.Created', {'post': post})
```
