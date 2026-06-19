# Upgrade 0.2 to 0.3

## Database Driver vs Dialect

Prior to 0.3, the `driver` and `dialect` were reversed. Meaning the `driver` was actually the `dialect`, and the `dialect` was actually the `driver`.  An oversight on initial Uvicore 0.1 development.

Edit your `config/database.py` and ensure it looks something like this

```python
# ...
'backend': 'sqlalchemy',
'dialect': env('DB_WIKI_DIALECT', 'mysql'),
'driver': env('DB_WIKI_DRIVER', 'aiomysql'),
# ...
```

## Deprecated db Methods

The following `uvicore.db` methods were deprecated as connections are automatic
- `db.connect()`
- `db.disconnect()`
- `db.databases()`
- `db.database()`


## Return of db.execute() now a sa.CursorResult

The return of `db.execute()` is now a `sa.CursorResult`

- To get single inserted PK - `result.inserted_primary_key`
- To get bulk inserted PK lists (not supported by MySQL) - `result.inserted_primary_key_rows`
- Getting columns from query results changed from `results[0].keys()` to `results[0]._mapping.keys`


## SQLAlchemy 2.0 select() Changes

All `sa.select()` does not use [] anymore, but infinite args



## SQLAlchemy 2.0 RowProxy is now a Row

RowProxy is no longer a “proxy”; is now called Row and behaves like an enhanced named tuple

See https://docs.sqlalchemy.org/en/20/changelog/migration_14.html#change-4710-core

This no longer works, as row is now a tuple
```python
# Errors with 'tuple indices must be integers or slices, not str'
for row in results:
    my_list[row['key']] = dict(row._mapping)
```

Instead use
```python
for row in results:
    my_list[row.key] = dict(row._mapping)
```

