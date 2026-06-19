---
title: Redis
---

# Redis

Uvicore ships with a simple, async **Redis service** — a lightweight connection helper and passthrough to the official [redis-py](https://redis.readthedocs.io/) async client.  Define your Redis servers once in config and the service hands you a ready-to-use async client for any of them, pooling and reusing each connection behind the scenes.

This is **not** the [Cache](cache.md) system.  Caching is a higher-level key/value abstraction that *uses* a Redis connection as one of its backends.  The Redis service documented here gives you the raw client so you can run *any* Redis command — strings, hashes, lists, sets, pub/sub, streams, scripting and more.

!!! note "See The Code on Github"
    - [Redis Service](https://github.com/uvicore/framework/blob/master/uvicore/redis/redis.py)
    - [Redis Provider](https://github.com/uvicore/framework/blob/master/uvicore/redis/package/provider.py)

---

## Configuration

Redis connections are defined in your package's `config/package.py` under the top-level `redis` key.  Apps created from the [Uvicore Installer](../getting-started/installation.md) already include this block — usually with two connections, one general-purpose and one dedicated to caching.

```python
    # --------------------------------------------------------------------------
    # Redis Connections
    # --------------------------------------------------------------------------
    'redis': {
        'default': env('REDIS_DEFAULT', 'wiki'),
        'connections': {
            'wiki': {
                'host': env('REDIS_WIKI_HOST', '127.0.0.1'),
                'port': env.int('REDIS_WIKI_PORT', 6379),
                'database': env.int('REDIS_WIKI_DB', 0),
                'password': env('REDIS_WIKI_PASSWORD', None),
            },
            'cache': {
                'host': env('REDIS_CACHE_HOST', '127.0.0.1'),
                'port': env.int('REDIS_CACHE_PORT', 6379),
                'database': env.int('REDIS_CACHE_DB', 2),
                'password': env('REDIS_CACHE_PASSWORD', None),
            },
        },
    },
```

Each connection is a named entry with `host`, `port`, `database` (the Redis logical database number) and an optional `password`.  The `default` key names the connection used whenever you don't ask for one explicitly.

As always, every value is `.env` overridable so the same code runs in dev, staging and production untouched:
```
REDIS_WIKI_HOST=127.0.0.1
REDIS_WIKI_PORT=6379
REDIS_WIKI_DB=0
```

Behind the scenes the service builds a standard connection URL from these parts (`redis://host:port/database`, with `?password=` appended when a password is set).

!!! tip
    Multiple packages can each define their own `redis` connections.  Uvicore deep-merges them all at boot, so an app that depends on other Uvicore packages ends up with every connection available under one service.

---

## Connecting

Grab the service with a simple import, then `await .connect()` to get an async Redis client:
```python
from uvicore.redis import Redis

# Connect to the default connection (the 'default' from your config)
redis = await Redis.connect()

# Or connect to a specific named connection
cache_redis = await Redis.connect('cache')
```

As with most things in Uvicore, the service is bound in the [IoC Container](ioc.md), so if you prefer you can resolve the very same singleton with `uvicore.ioc.make()` instead of the import:
```python
import uvicore

# 'redis' (or 'Redis') is the registered alias for the service
redis = await uvicore.ioc.make('redis').connect()
```

`Redis.connect()` returns a live [redis-py](https://redis.readthedocs.io/) **async client** (`redis.asyncio.Redis`).  Everything from here on is plain redis-py — every command the client supports is available to you.

!!! note
    `connect()` is lazy and pooled.  The first call to a connection opens the pool; every later call for that same connection returns the *same* client instance, so it is cheap to call `await Redis.connect()` wherever you need it rather than passing the client around.

---

## Using the client

Because the service is a thin passthrough, you are talking directly to redis-py.  A few common examples:

```python
from uvicore.redis import Redis
redis = await Redis.connect()

# Strings
await redis.set('greeting', 'hello')
await redis.get('greeting')                     # b'hello'
await redis.setex('session:123', 600, 'abc')    # value with a 600s TTL

# Counters
await redis.incr('page:views')
await redis.incrby('page:views', 10)

# Expiry
await redis.expire('greeting', 60)              # expire in 60 seconds
await redis.ttl('greeting')                     # seconds remaining

# Hashes
await redis.hset('user:1', mapping={'name': 'Matthew', 'role': 'admin'})
await redis.hgetall('user:1')                   # {b'name': b'Matthew', b'role': b'admin'}

# Lists
await redis.rpush('queue', 'job1', 'job2')
await redis.lrange('queue', 0, -1)              # [b'job1', b'job2']

# Sets
await redis.sadd('tags', 'linux', 'mac')
await redis.smembers('tags')                    # {b'linux', b'mac'}

# Delete and existence
await redis.delete('greeting')
await redis.exists('user:1')                    # 1
```

!!! tip
    By default redis-py returns **bytes**, not strings (e.g. `b'hello'`).  Decode with `.decode()` when you need a string, or store and retrieve your own serialized format (JSON, pickle, etc.).  For the full command reference see the [redis-py command docs](https://redis.readthedocs.io/en/stable/commands.html).

---

## Multiple Connections

Define as many connections as you like — different servers, different logical databases, different credentials.  Each one is isolated:

```python
from uvicore.redis import Redis

wiki = await Redis.connect('wiki')      # database 0
cache = await Redis.connect('cache')    # database 2

await wiki.set('key', 'value')
await cache.exists('key')               # 0 - different database, not visible here
```

### Inspecting Connections

The service also exposes its configuration so you can introspect what is wired up:
```python
from uvicore.redis import Redis

Redis.default                   # 'wiki' - the default connection name
Redis.connections               # Dict of all connection configs by name
Redis.connection('cache')       # the 'cache' connection config (host, port, database, url...)
Redis.connection()              # the default connection's config
Redis.engines                   # Dict of currently-connected pools, keyed by URL
```

Asking for a connection that doesn't exist raises an exception:
```python
Redis.connection('nope')        # Exception: Redis connection nope not found
```

---

## Relationship to Cache

The [Cache](cache.md) system and this Redis service are related but distinct:

- **Redis service** (this page) — low-level.  You get the raw async client and run any Redis command directly.
- **Cache** — high-level key/value API (`get`/`put`/`remember`/`forget`...) with TTLs, key prefixing and pluggable backends.  Its `redis` backend simply *uses* one of the Redis `connections` you defined here (the `cache` connection in the examples above).

Reach for **Cache** when you want simple, expiring key/value storage that could live in Redis *or* in-app memory.  Reach for the **Redis service** when you need Redis-specific features — pub/sub, streams, sorted sets, atomic counters, Lua scripting — or you simply want full control over the client.

---

!!! tip "Redis tips"
    - Get the service with `from uvicore.redis import Redis`, then `await Redis.connect()` for the default connection or `await Redis.connect('name')` for a specific one.  You can also resolve it from the [IoC](ioc.md) with `uvicore.ioc.make('redis')`.
    - `connect()` is pooled — the same client is reused per connection, so call it freely.
    - Define connections in `config/package.py` under `redis`, and override host/port/db/password per environment via `.env`.
    - The client is plain [redis-py](https://redis.readthedocs.io/) async — values come back as bytes, so `.decode()` when you need strings.
    - Need simple expiring key/value storage instead of raw Redis?  Use the [Cache](cache.md) system.
