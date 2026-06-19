---
title: Events
---

# Event System

Uvicore ships with an elegant observer (pub/sub) implementation that lets you
*listen* to things that happen inside the framework, inside the packages you
depend on, and inside your own code.  When something noteworthy occurs you
*dispatch* an event, and every listener that registered interest in it springs
into action.

Events are one of the best tools you have for keeping a project loosely coupled.
A single event can have many listeners that know nothing about each other.  When
a wiki post is created, for example, one listener might email the watchers,
another might post to Slack, and a third might warm a cache, all without the code
that created the post knowing any of them exist.

This is the `O` in `S.O.L.I.D` in action, code that is **open for extension but
closed for modification**.  By firing events at the interesting moments in your
code, you let other developers (and your future self) hook in new behavior
without ever touching the original.  It is a kindness worth doing early, so
sprinkle events throughout your packages from the start.

---

## What's Inside

- **[Defining Events](defining.md)** - Create strict, discoverable class events or quick string events.
- **[Dispatching Events](dispatching.md)** - Fire your events synchronously or asynchronously.
- **[Listening to Events](listening.md)** - Subscribe handlers, with priorities, wildcards and bulk subscriptions.
- **[Handling Events](handling.md)** - Write the callbacks, functions, classes and subscriptions that do the work.
- **[Built-in Events](builtin.md)** - The lifecycle, HTTP, console and ORM events Uvicore fires for you.

---

## Highlights

- **Sync and async** - Events are flagged synchronous or asynchronous and dispatched accordingly.
- **Priorities** - Order your listeners with a simple `priority` (default `50`, lower runs first).
- **Wildcards** - Listen to whole families of events like `uvicore.foundation.events.*`.
- **Subscriptions** - Group many listeners and their handlers into a single tidy class.

!!! tip
    Class based events register themselves into the [IoC Container](../ioc.md),
    so you can discover everything that is listenable at any time with
    `./uvicore event list`.  See [Built-in Events](builtin.md#inspecting-events-cli)
    for the full set of inspection commands.
