---
title: Modular Concept
---

# Modular Concept

Uvicore is built around one beautifully simple idea:

> **Every app is a module, and every module is an app.**

A Uvicore package can run as an *app* (something that is "running", served over HTTP or executed from the CLI) or be imported as a *library* (something that is "consumed" by another running app).  There is very little difference between the two modes, the only real distinction is *who governs the running config*.

This is the opposite of most frameworks, where a "shell" is required to host your code (think Django's project vs apps, or a Laravel application hosting your packages).  In Uvicore there is no shell.  Your package *is* the app.

---

## Apps vs Libraries

The exact same package can be both, depending on how it is started.

**As an App** (the running application)

When your package is the one being served or executed, its `config/app.py` becomes the *running config*.  It dictates the app name, debug mode, middleware, the web/api prefixes, auth, and which IoC bindings are [overridden](ioc.md).  This is the package at the top of the dependency graph.

**As a Library** (imported by another app)

When another app depends on your package, your `config/app.py` is ignored entirely, only your `config/package.py` is used.  The host app is now in charge.  It can deep-merge and override *your* package's config, disable parts of your provider's registration through the [registers](provider.md#registration-control) gate, and swap your classes through its own [IoC overrides](ioc.md).

!!! note
    This is why Uvicore splits config into two files.  `config/package.py` always applies (app or library).  `config/app.py` only applies when your package is the running application.  See [Configuration](../getting-started/configuration.md) for the full breakdown.

---

## Dependencies

A package declares the other packages it depends on in its `config/package.py` `dependencies` map.  At bootstrap, Uvicore walks this graph recursively to build the full, ordered list of providers to register and boot.

```python
# config/package.py
dependencies = OrderedDict({
    # Foundation is the minimal core and is always required first
    'uvicore.foundation': {
        'provider': 'uvicore.foundation.package.provider.Foundation',
    },

    # Pull in only the core features your package needs
    'uvicore.database': {
        'provider': 'uvicore.database.package.provider.Database',
    },
    'uvicore.http': {
        'provider': 'uvicore.http.package.provider.Http',
    },

    # Depend on another community or first-party package, exactly the same way
    'acme.themes': {
        'provider': 'acme.themes.package.provider.Themes',
    },
})
```

Because depending on another *app* works identically to depending on a *core framework feature*, there is no special "plugin" system to learn.  Composing applications out of smaller applications is just dependencies all the way down.

!!! tip
    **Last definition wins.**  When the dependency graph is resolved, a package declared last overrides an earlier definition while preserving declaration order.  This is precisely how a running app can override a framework package's provider.

---

## Why This Matters

- **Reuse** - Build a feature once as a package and drop it into any number of apps.
- **Override** - A host app can reshape any dependency's config, registration and classes without forking it.
- **Testability** - Each package ships its own provider, config and tests and can run standalone.
- **No lock-in shell** - There is no monolithic framework skeleton your code must live inside.

Everything else in this section, [Providers](provider.md), the [IoC Container](ioc.md) and [Configuration](../getting-started/configuration.md), exists to make this modular model work seamlessly.
