# DB Configuration

Database configuration is defined in your package's `config/database.py` file.

Within this file you may specify none, one or more database connections using various backends, dialects and drivers.

Due to the nature of Uvicore's [Configuration System](../getting-started/configuration.md) any consumer of your package can tweak your package's connection strings within their own app.  They may prefer `aiomysql` vs `pymysql` and even add a prefix to all database tables.


---


## Dependencies

Uvicore utilizes the async [SQLAlchemy Core 2.0](https://docs.sqlalchemy.org/en/20/core/) for most database connections and therefore supports all databases, dialects and drivers that SQLAlchemy does!

When running the [Uvicore Installer](../getting-started/installation.md), if you answered `Yes` to installing Database tools, then Uvicore already comes [SQLAlchemy Core 2.0](https://docs.sqlalchemy.org/en/20/core/) and a few common DBAL libraries like `aiomysql`, `aiosqlite` and `asyncpg`.


If you answered `No` to Database tools and would like to add them manually...

Ensure you have installed the `database` extras from the framework.
```
# Poetry pyproject.toml
uvicore = {version = "0.3.*", extras = ["database", "redis", "web"]}

# Pipenv Pipfile
uvicore = {version = "==0.3.*", extras = ["database", "redis", "web"]}

# requirements.txt
uvicore[database,redis,web] == 0.3.*
```

After the database extras have been installed you must update your `config/dependencies.py` `dependencies` to include the `uvicore.database` provider
```python
dependencies = OrderedDict({
    # ...
    'uvicore.database': {
        'provider': 'uvicore.database.package.provider.Database',
    },
    # Optional if you will be using Uvicore's ORM!
    # 'uvicore.orm': {
    #     'provider': 'uvicore.orm.package.provider.Orm',
    # },
    # ...
})
```

Notice the ORM dependency does not need to be defined.  Uvicore can use a raw query builder level database access layer without an ORM.


---


##  Connection Strings

Uvicore uses your package's `config/database.py` to store connection strings.


!!! tip
    When defining connections be sure to wrap all values in `env()` so users can overwrite the values from their own `.env` and help keep secrets out of git!

```python

config = {
    # ...
    'database': {
        'default': env('DATABASE_DEFAULT', 'wiki'),
        'connections': {
            # SQLite Example
            # 'wiki': {
            #     'backend': env('DB_WIKI_BACKEND', 'sqlalchemy'),
            #     'dialect': env('DB_WIKI_DIALECT', 'sqlite'),
            #     'driver': env('DB_WIKI_DRIVER', 'aiosqlite'),
            #     'database': env('DB_WIKI_DB', ':memory:'),
            #     'prefix': env('DB_WIKI_PREFIX', None),
            #     # If 'url' is defined using sqlalchemy backend,
            #     # it will be used instead of deriving one from the properties above.
            #     'url': '',
            # },

            # MySQL Example
            'wiki': {
                'backend': 'sqlalchemy',
                'dialect': env('DB_WIKI_DIALECT', 'mysql'),
                'driver': env('DB_WIKI_DRIVER', 'aiomysql'),
                'host': env('DB_WIKI_HOST', '127.0.0.1'),
                'port': env.int('DB_WIKI_PORT', 3306),
                'database': env('DB_WIKI_DB', 'appstub'),
                'username': env('DB_WIKI_USER', 'root'),
                'password': env('DB_WIKI_PASSWORD', 'techie'),
                'prefix': env('DB_WIKI_PREFIX', None),
                'url': '',
                # If 'url' is defined using sqlalchemy backend,
                # it will be used instead of deriving one from the properties above.
                # All options passed directly as **kwargs to the backends connect, create_pool,
                # create_engine or other backend specific create methods
                # Example enable SSL using pymysql driver
                # 'options': {
                #     'ssl_ca': '/etc/ssl/certs/ca-certificates.crt',
                # },
                # Example enable SSL using aiomysql driver
                # 'options': {
                #     'ssl': True
                # }
            },
        },
    },
    # ...
}
```
The `options` dictionary are values passed directly to the `driver` creation.  In the case of SQLAlchemy, this would be the `connect_args` parameter of `create_engine()`


---


## Connection Pooling

Each connection may define an optional `pool` dictionary.  Where `options` configures the **driver**
(`connect_args`), `pool` configures the **engine's connection pool** — the `pool_*` arguments of
SQLAlchemy's `create_engine()`.

```python
config = {
    # ...
    'database': {
        'connections': {
            'wiki': {
                'backend': 'sqlalchemy',
                'dialect': env('DB_WIKI_DIALECT', 'mysql'),
                # ...
                'pool': {
                    'pre_ping': env.bool('DB_WIKI_POOL_PRE_PING', True),
                    'recycle': env.int('DB_WIKI_POOL_RECYCLE', 3600),
                    'size': env.int('DB_WIKI_POOL_SIZE', 5),
                    'max_overflow': env.int('DB_WIKI_POOL_MAX_OVERFLOW', 10),
                },
            },
        },
    },
    # ...
}
```

| `pool` key | SQLAlchemy kwarg | Default | Purpose |
|---|---|---|---|
| `pre_ping` | `pool_pre_ping` | `True` | Test a pooled connection with a lightweight ping before handing it to your code.  Recovers transparently from a connection the server closed while it sat idle. |
| `recycle` | `pool_recycle` | unset (never) | Discard and rebuild a connection older than N seconds.  The blunt-instrument answer to any server-side idle/lifetime limit. |
| `size` | `pool_size` | unset (SQLAlchemy's 5) | Connections kept open in the pool. |
| `max_overflow` | `max_overflow` | unset (SQLAlchemy's 10) | Extra connections allowed beyond `size` under load. |
| `timeout` | `pool_timeout` | unset (SQLAlchemy's 30) | Seconds to wait for a connection before giving up. |
| `use_lifo` | `pool_use_lifo` | unset (`False`) | Reuse the most-recently-returned connection, letting idle ones age out. |
| `reset_on_return` | `pool_reset_on_return` | unset (`'rollback'`) | What to do to a connection on return to the pool. |

The keys are deliberately **unprefixed** — the block is already called `pool`, and SQLAlchemy's own
argument names are inconsistent about it (`pool_size` but `max_overflow`).  An unrecognized key
**raises** at bootstrap rather than being ignored, so a `pool_recycle` typo cannot look configured
and silently do nothing.

!!! tip
    Only `pre_ping` is defaulted.  `size` and `max_overflow` are **rejected outright** by
    SQLAlchemy's `StaticPool` and `NullPool` — which is what a `sqlite` `':memory:'` connection
    gets — so a framework-level default would break the simplest connection there is.  Set them
    only on a real server connection.


---


## Backends, Drivers and Dialects

Uvicore's database config section is geared towards SQLAlchemy.  But there is nothing stopping you from adding other connection properties that may be useful to your specific driver (mongodb, snowflake etc...).

The 3 main properties that dictate the backend and drivers to use are

- A `backend` specifies the primary abstraction library.  Uvicore defaults to the `sqlalchemy` backend.  In the future Uvicore may support other backends.
- A `dialect` is passed to SQLAlchemy to denote the type of database such as `mysql`, `sqlite`, `postgres`.
- A `driver` is the DBAL used by SQLAlchemy to talk to the database, such as `aiomysql`, `aiosqlite`, `asyncpg` and `pymysql`.

For the default `sqlalchemy` backend, you may use any compatible dialect defined here [https://docs.sqlalchemy.org/en/20/dialects/](https://docs.sqlalchemy.org/en/20/dialects/) As for SQLAlchemy drivers, there are many for each dialect which are also referenced in the link above.

`snowflake` is supported as a first-class dialect (see [Snowflake](#snowflake) below) even though its driver is third-party.  For any other 3rd party dialect you may utilize the `url` property to specify the exact connection URL directly.  Or you can use the [IoC](../deeper/ioc.md) and provide an override for the entire `uvicore.database.db.Db` class and overload the `init()` method!


---


## Engine Lifecycle

Uvicore builds one SQLAlchemy engine (connection pool) per unique server+database during bootstrap, shared by every connection that points at the same place.

- **Shutdown is automatic.**  When the CLI command, HTTP server or pytest run ends, Uvicore disposes every engine (closing all pooled driver connections) via the framework's `Shutdown` events.  Without this, async driver connections (aiomysql, asyncpg...) would be garbage collected after the event loop closes and spew `RuntimeError: Event loop is closed` tracebacks on exit.
- **Re-initialization is safe.**  Advanced apps that call `uvicore.db.init()` again at runtime (for example to switch a snowflake warehouse, which requires a new engine URL) will not leak: an engine whose URL is unchanged is reused as-is, and a replaced engine is properly disposed rather than orphaned.  Its SQLAlchemy `MetaData` (and all tables registered on it) is preserved.
- **Manual disconnect.**  You can dispose engines yourself with `await uvicore.db.disconnect(connection='wiki')`, by `metakey=`, or everything with `await uvicore.db.disconnect(all_dbs=True)`.


---


## Snowflake

Snowflake connections use the `snowflake` dialect with the third-party
[snowflake-sqlalchemy](https://github.com/snowflakedb/snowflake-sqlalchemy) driver (which you install
yourself — it is not part of Uvicore's `database` extra).  Instead of `host`/`port`, a Snowflake
connection takes `account`, `warehouse` and `role`:

```python
config = {
    # ...
    'database': {
        'connections': {
            'wiki': {
                'backend': 'sqlalchemy',
                'dialect': 'snowflake',
                'account': env('DB_WIKI_ACCOUNT', ''),
                'database': env('DB_WIKI_DATABASE', ''),
                'schema': env('DB_WIKI_SCHEMA', ''),
                'warehouse': env('DB_WIKI_WAREHOUSE', ''),
                'role': env('DB_WIKI_ROLE', ''),
                'username': env('DB_WIKI_USERNAME', ''),
                'password': env('DB_WIKI_PASSWORD', ''),
                'options': {
                    # Key-pair auth: the DER base64 of your .pem, all on one line
                    'private_key': env('DB_WIKI_PRIVATE_KEY', ''),
                },
            },
        },
    },
    # ...
}
```

### Long-running processes and the 4-hour token

A Snowflake session holds two tokens: a **session** token (~1 hour) and a **master** token
(~4 hours).  The Snowflake connector renews the first by itself but **not** the second — on master
token expiry it merely records a flag that nothing acts on, and key-pair auth has no
re-authentication path at all.  So any process that outlives the master token starts failing every
query with:

```
390114 (08001): Authentication token has expired.  The user must authenticate again.
```

Uvicore handles this for you, in two layers, on every `snowflake` connection:

1. **The session is kept alive.**  Uvicore defaults the connect options to
   `client_session_keep_alive` (a background heartbeat that refreshes the master token before it can
   expire) with a `client_session_keep_alive_heartbeat_frequency` of `900` seconds.  A heartbeat is a
   token-only REST call — it runs no query and consumes **no warehouse credits**.

2. **A token that dies anyway no longer poisons the pool.**  `snowflake-sqlalchemy` defines no
   `is_disconnect()`, so SQLAlchemy would classify an expired token as an ordinary query error,
   return the dead connection to the pool and hand it straight back out — every subsequent query
   failing identically until the *process* was restarted.  Uvicore teaches the engine that the
   terminal token codes (`390110`, `390113`, `390114`, `390115`) are **disconnects**, so the pool is
   invalidated and the next query re-authenticates.  The statement that hit the dead token still
   raises; retry it and it succeeds.

   `390112` (session expired) is deliberately **not** in that list — the connector renews that one
   itself, and treating it as a disconnect would discard a pool that was about to heal.

Both are defaults, not requirements.  Set either connect option explicitly to override it — for a
short-lived CLI that has no use for a heartbeat, for instance:

```python
'options': {
    'private_key': env('DB_WIKI_PRIVATE_KEY', ''),
    'client_session_keep_alive': False,
},
```

!!! tip
    Snowflake enforces a `MAX_CONCURRENCY_LEVEL` **per warehouse** (8 by default, and *not* raised
    by using a bigger warehouse).  If several processes share one warehouse, cap each one's
    [pool](#connection-pooling) `size` so they cannot collectively queue behind that ceiling.


---


## PlanetScale

PlanetScale is a sharded MySQL built on [Vitess](https://vitess.io/), so it uses the ordinary `mysql`
dialect with a MySQL driver such as `aiomysql`.  Two `options` keys are effectively mandatory:

```python
'options': {
    'ssl': True,          # PlanetScale requires SSL
    'autocommit': True,   # required as of PlanetScale's 2026-09-01 Vitess change
}
```

Vitess previously reported the **wrong** autocommit value in the connection handshake, so
pymysql/aiomysql connections ran autocommit-ON despite the driver intending OFF.  Now that Vitess
reports it correctly those connections become `autocommit=False`, leaving an implicit transaction
open that Vitess aborts after 20 seconds.  Setting `'autocommit': True` preserves the behavior a
PlanetScale connection already had.

!!! warning "Only on PlanetScale connections"
    `autocommit` is **not** the driver default — pymysql and aiomysql both default to
    `autocommit=False`.  Forcing it True on an ordinary MySQL/MariaDB/Aurora connection silently
    disables rollback (an `INSERT` followed by `rollback()` stays committed), so scope it to the
    connections that actually point at Vitess.

See the [PlanetScale recipe](recipes/planetscale.md) for the full connection example and both of
PlanetScale's suggested fixes.


---


## View from CLI

From the [Uvicore CLI](../cli/index.md), you can see all deeply merged connection strings for your app and any Uvicore package dependencies that use the DB by running
```bash
./uvicore db connections
```
