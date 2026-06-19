---
title: Digging Deeper
---

# Digging Deeper

You have built routes, models and CLI commands.  Now it is time to dig into the powerful internals that make Uvicore tick.

This section covers the deeper, cross-cutting features of the framework.  None of it is required reading to be productive with Uvicore, but understanding these concepts is what takes you from *using* Uvicore to truly *mastering* it.

---

## What's Inside

- **[Events](events/index.md)** - Decouple your application with a powerful sync and async event system.
- **[Modular Concept](modular.md)** - Every app is a module and every module is an app.  No "shell" required.
- **[Package Provider](provider.md)** - The bootstrap heart of every package, inspired by Laravel's Service Providers.
- **[IoC Container](ioc.md)** - Inversion of Control.  Override *anything*, even Uvicore's own core.
- **[Jobs](jobs.md)** - Encapsulate a unit of work and dispatch it sync or async.
- **[Templating](templating.md)** - Render Jinja templates anywhere, not just in Web views.
- **[HTTP Client](http-client.md)** - A shared async `aiohttp` client for outbound HTTP calls.
- **[Cache](cache.md)** - Pluggable key/value caching with Redis and in-memory backends.
- **[Redis](redis.md)** - A simple async connection helper and passthrough to the raw Redis client.
- **[Mail](mail.md)** - A fluent, chainable mailer with swappable drivers.
- **[SuperDict](superdict.md)** - The dot-notation, deep-mergeable dictionary that powers all of Uvicore's config.

!!! tip
    Most of these features are powered by the [IoC Container](ioc.md) and configured through the [Package Provider](provider.md).  Start there and the rest will click into place.
