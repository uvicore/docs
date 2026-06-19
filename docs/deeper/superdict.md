---
title: SuperDict
---

# SuperDict

Uvicore ships with a supercharged dictionary type that powers its entire configuration system.  We affectionately call it the **SuperDict**.

It is a drop-in replacement for Python's built-in `dict` that adds dot-notation access, deep merging, freezing and a handful of other niceties.  Every config in Uvicore, your `config/app.py`, every connection, every route definition, is a SuperDict under the hood.  That is what makes Uvicore's [config overriding](../getting-started/configuration.md) and [modular](modular.md) merging feel so effortless.

---

## Importing

The SuperDict types live in `uvicore.typing`.  There is a standard `Dict` and an `OrderedDict`.

```python
from uvicore.typing import Dict, OrderedDict

config = Dict({
    'name': 'Acme Wiki',
    'database': {
        'default': 'wiki',
    },
})
```

!!! tip
    Use `uvicore.typing.Dict` and `OrderedDict` throughout your app instead of the built-in `dict`.  They behave like a normal `dict` everywhere a `dict` is expected, but give you all the powers below.

---

## Dot Notation

Read and write deeply nested values with a single dotted key, no more chains of `['...']['...']` or `KeyError` surprises.

```python
# Read a nested value
config.dotget('database.default')          # 'wiki'

# Missing keys return None instead of raising
config.dotget('database.missing.deep')     # None

# Write a nested value, auto-creating intermediate dicts
config.dotset('database.connections.wiki.host', '127.0.0.1')
```

You can also use plain attribute access, missing keys auto-create nested SuperDicts rather than raising:

```python
config.database.default                    # 'wiki'
config.cache.stores.redis.seconds = 600    # just works
```

---

## Deep Merging

This is the feature that makes Uvicore's config system tick.  `merge()` recursively combines dictionaries with **override wins** semantics, while `defaults()` is the reverse, it only fills in keys that are *missing*.

```python
base = Dict({
    'name': 'Acme',
    'http': {'prefix': '', 'debug': False},
})

# merge() - incoming values win
base.merge({'http': {'debug': True}})
# {'name': 'Acme', 'http': {'prefix': '', 'debug': True}}

# defaults() - only fills what is absent, existing values are kept
base.defaults({'http': {'prefix': '/api'}, 'timezone': 'UTC'})
# prefix stays '', timezone is added
```

Deep merging is exactly how a [host app overrides a library package's config](modular.md), the host's values are merged *over* the package's, key by key, no matter how deeply nested.

---

## Other Helpers

```python
# A deep, independent copy
clone = config.clone()

# Convert back to plain python dicts (recursively)
plain = config.to_dict()

# Freeze to make read-only (and unfreeze)
config.freeze()
config.unfreeze()
```

The `|` operator also merges, mirroring Python's modern dict union:

```python
combined = dict_a | dict_b
```

---

## Where You'll See It

You generally won't construct SuperDicts by hand very often, Uvicore does it for you.  But you *will* interact with them constantly:

- `uvicore.config` is one giant merged SuperDict of every package's config.
- `self.package.config` inside a [Provider](provider.md) is your package's slice of it.
- Database `connections`, HTTP `routes` and more are all SuperDicts.

```python
import uvicore

# Reach any config value with dot notation
prefix = uvicore.config.dotget('app.api.prefix')
debug  = uvicore.config.app.debug
```
