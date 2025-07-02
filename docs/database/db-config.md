# DB Configuration

Database configuration is defined in your package's `config/database.py` file.

Within this file you may specify none, one or more database connections using various backends, dialects and drivers.

Due to the nature of Uvicore's [Configuration System](/getting-started/configuration/) any consumer of your package can tweak your package's connection strings within their own app.  They may prefer `aiomysql` vs `pymysql` and even add a prefix to all database tables.


---


## :material-pound: Dependencies

Uvicore utilizes the async [SQLAlchemy Core 2.0](https://docs.sqlalchemy.org/en/20/core/) for most database connections and therefore supports all databases, dialects and drivers that SQLAlchemy does!

When running the [Uvicore Installer](/getting-started/installation/), if you answered `Yes` to installing Database tools, then Uvicore already comes [SQLAlchemy Core 2.0](https://docs.sqlalchemy.org/en/20/core/) and a few common DBAL libraries like `aiomysql`, `aiosqlite` and `asyncpg`.


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
    'dependencies': OrderedDict({
        # ...
        'uvicore.database': {
            'provider': 'uvicore.database.services.Database',
        },
        # Optional if you will be using Uvicore's ORM!
        # 'uvicore.orm': {
        #     'provider': 'uvicore.orm.package.provider.Orm',
        # },
        #
    }),
```

Notice the ORM dependency does not need to be defined.  Uvicore can use a raw query builder level database access layer without an ORM.


---


## :material-pound:  Connection Strings

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


## :material-pound: Backends, Drivers and Dialects

Uvicore's database config section is geared towards SQLAlchemy.  But there is nothing stopping you from adding other connection properties that may be useful to your specific driver (mongodb, snowflake etc...).

The 3 main properties that dictate the backend and drivers to use are

- A `backend` specifies the primary abstraction library.  Uvicore defaults to the `sqlalchemy` backend.  In the future Uvicore may support other backends.
- A `dialect` is passed to SQLAlchemy to denote the type of database such as `mysql`, `sqlite`, `postgres`.
- A `driver` is the DBAL used by SQLAlchemy to talk to the database, such as `aiomysql`, `aiosqlite`, `asyncpg` and `pymysql`.

For the default `sqlalchemy` backend, you may use any compatible dialect defined here [https://docs.sqlalchemy.org/en/20/dialects/](https://docs.sqlalchemy.org/en/20/dialects/) As for SQLAlchemy drivers, there are many for each dialect which are also referenced in the link above.

If you were to use a 3rd party dialect like `snowflake-sqlalchemy` you may utilize the `url` property to specify the exact connection URL directly.  Or you can use the [IoC](/deeper/ioc/) and provide an override for the entire `uvicore.database.db.Db` class and overload the `init()` method!


---


## :material-pound: View from CLI

From the [Uvicore CLI](/cli/), you can see all deeply merged connection strings for your app and any Uvicore package dependencies that use the DB by running
```bash
./uvicore db connections
```
