---
title: Built-in Events
---

# Built-in Events

Uvicore dispatches a handful of events of its own that you will find useful in
your application.  Listen to any of them exactly as you would your own events,
either off the event class or by its string name.

---

## Foundation Events

These fire during application bootstrap and are **synchronous** (`is_async = False`).

`uvicore.foundation.events.app.Registered` fires once every package service
provider's `register()` method has run.

```python
from uvicore.foundation.events import app as AppEvents
AppEvents.Registered.listen(my_handler)

# or string based
events.listen('uvicore.foundation.events.app.Registered', my_handler)
```

`uvicore.foundation.events.app.Booted` fires once every provider's `boot()`
method has run.  This is the best place to hook in when Uvicore is fully booted
and ready to go.

```python
from uvicore.foundation.events import app as AppEvents
AppEvents.Booted.listen(my_handler)

# or string based
events.listen('uvicore.foundation.events.app.Booted', my_handler)
```

---

## HTTP Server Events

These are **asynchronous** (`is_async = True`) and map to Starlette's server
lifecycle, so dispatch and handle them with `codispatch()` / async handlers.

`uvicore.http.events.server.Startup` fires when the HTTP server starts.

```python
from uvicore.http.events import server as HttpEvents
HttpEvents.Startup.listen(my_handler)

# or string based
events.listen('uvicore.http.events.server.Startup', my_handler)
```

`uvicore.http.events.server.Shutdown` fires when the HTTP server shuts down.

```python
from uvicore.http.events import server as HttpEvents
HttpEvents.Shutdown.listen(my_handler)

# or string based
events.listen('uvicore.http.events.server.Shutdown', my_handler)
```

---

## Console (CLI) Events

These are also **asynchronous** (`is_async = True`).  The console fires `Startup`
before a command runs and `Shutdown` after it completes, with dedicated
`Pytest*` variants for test runs.

```python
from uvicore.console.events import command as ConsoleEvents

# Before / after a console command
ConsoleEvents.Startup.listen(my_handler)
ConsoleEvents.Shutdown.listen(my_handler)

# Before / after a pytest run
ConsoleEvents.PytestStartup.listen(my_handler)
ConsoleEvents.PytestShutdown.listen(my_handler)
```

Their string names are:

- `uvicore.console.events.command.Startup`
- `uvicore.console.events.command.Shutdown`
- `uvicore.console.events.command.PytestStartup`
- `uvicore.console.events.command.PytestShutdown`

!!! info
    The pytest events are dispatched from your own project's
    `./tests/conftest.py`, not from the framework.  Many core packages (like the
    database layer) listen to `PytestStartup` / `PytestShutdown` to connect and
    disconnect resources around your test suite.

---

## ORM Model Events

Every [ORM model](../../database/orm-basics.md) fires a pair of events around
each insert, save and delete.  These are **dynamic string based events**, one set
per model, and all are **asynchronous**.  Their names follow the pattern
`uvicore.orm-{modelfqn}-EventName`, and the payload is always `{'model': self}`,
so your handler reads the record off `event.model`.

| Event | Fires |
| ----- | ----- |
| `uvicore.orm-{modelfqn}-BeforeInsert` | Before a brand new record is inserted |
| `uvicore.orm-{modelfqn}-AfterInsert`  | After a brand new record is inserted |
| `uvicore.orm-{modelfqn}-BeforeSave`   | Before a record is saved (insert or update) |
| `uvicore.orm-{modelfqn}-AfterSave`    | After a record is saved (insert or update) |
| `uvicore.orm-{modelfqn}-BeforeDelete` | Before a record is deleted |
| `uvicore.orm-{modelfqn}-AfterDelete`  | After a record is deleted |

Listen to one model's event by its exact name:

```python
def on_post_saved(event):
    post = event.model
    # ...react to the saved post

events.listen('uvicore.orm-{acme.wiki.models.post.Post}-AfterSave', on_post_saved)
```

Because listener names are matched as regular expressions, you can also watch a
family of model events with a wildcard (see
[wildcard listening](listening.md#listening-to-wildcard-events)):

```python
# React to AfterSave on every model
events.listen('uvicore.orm-.*-AfterSave', on_any_saved)
```

---

## Inspecting Events (CLI)

Because class based events register themselves into the [IoC Container](../ioc.md),
you can explore everything that is listenable straight from the command line:

```bash
# List every class based event defined across all packages
./uvicore event list

# Show the details (description, is_async) for one event
./uvicore event get uvicore.foundation.events.app.Booted

# Show all registered listeners/handlers and the events they watch
./uvicore event listeners
```

!!! tip
    `./uvicore event list` only shows **class based** events, since those are the
    ones bound to the IoC.  Dynamic string based events (like the ORM model events
    above) are documented rather than listed, so reach for `./uvicore event listeners`
    to confirm what is actually wired up at runtime.
