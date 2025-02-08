# Upgrade 0.2 to 0.3

## :material-pound: Database Driver vs Dialect

NO, decided to take the plunge into SQLAlchemy 2.0 instead



## add to sa 2.0 stuff

no longer works, as row is now a tuple
errors with 'tuple indices must be integers or slices, not str'
        for row in results:
            ros[row['key']] = dict(row._mapping)

use row.key instead of row['key']


See https://docs.sqlalchemy.org/en/20/changelog/migration_14.html#change-4710-core
example, use 'id' in row._mapping now instead of 'id' in row




## OLD


The ONLY breaking change from 0.2 to 0.3 was the `config/database.py` database connection configuration.

Prior to 0.3, the `driver` and `dialect` were reversed. Meaning the `driver` was actually the `dialect`, and the `dialect` was actually the `driver`.  An oversight on initial Uvicore 0.1 development.

* :material-auto-fix: FIXME

NOTE, this sync_driver stuff is all wrong, I autodetect now


Along with this we also realized that we need two separate drivers.  One for synchronous connectivity and one for asynchronous connectivity.  This is due to that fact that Uvicore 0.3.0 still uses SQLAlchemy 1.4 which does not support Aync very well for features like create, drop, seed, reseed of the database.

So instead we have REMOVED the new `driver` for
- `sync_driver`
- `async_driver`

So please REVERS `dialect` and create a new `sync/async_driver` config in your `config/database.py` like so:

```python
'connections': {
    # MySQL Example
    'wiki': {
        'dialect': env('DB_WIKI_DIALECT', 'mysql'),
        'sync_driver': env('DB_WIKI_SYNC_DRIVER', 'pymysql'),
        'async_driver': env('DB_WIKI_ASYNC_DRIVER', 'aiomysql'),
        'host': env('DB_WIKI_HOST', '127.0.0.1'),
        'port': env.int('DB_WIKI_PORT', 3306),
        'database': env('DB_WIKI_DB', 'dreml'),
        'username': env('DB_WIKI_USER', 'root'),
        'password': env('DB_WIKI_PASSWORD', 'techie'),
        'prefix': env('DB_WIKI_PREFIX', None),
    },
},
```

Now all create, drop, reseed operations use the synchronous `pymysql`.  And all actual database queries running through `encode/databases` use the asynchronous `aiomysql`
