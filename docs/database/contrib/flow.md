# Bootstrap Sequence

!!! warning
    This section is for developers who whish to contribute to Uvicore source code. To understand how this module works under the hood!

## :material-pound: Flow

- Uvicore is booted and raises the [AppEvents.Booted](https://github.com/uvicore/framework/blob/master/uvicore/foundation/events/app.py) event
- [database/package/provider.py](https://github.com/uvicore/framework/blob/master/uvicore/database/package/provider.py)
    - Handles the event with `AppEvents.Booted.listen(bootstrap.Database)`
- [database/package/bootstrap.py](https://github.com/uvicore/framework/blob/master/uvicore/database/package/bootstrap.py) `__call__` method
    - Builds `Dict()` of all packages with `database` connections
    - Builds `List` of all packages models
    - Builds `List` of all packages tables
    - Then calls `uvicore.db.init(app_default or last_default, connections)`
        - Found in `uvicore/database/db.py`
- [database/db.py](https://github.com/uvicore/framework/blob/master/uvicore/database/db.py) `init()` method
    - Fills out each connection detail + SA URL
    - Creates SQLAlchemy sync or async engines
        - Stored in `self._engines` accessible at `uvicore.db.engines`
        - Using `create_async_engine(conn_url, connect_args=connection.options)`
        - Or `sa.create_engine(conn_url, connect_args=connection.options, pool_pre_ping=True)`
        - No `engine.connect()` takes place until an actual query is made, then it is closed.
    - Creates SQLAlchemy metadata
        - Stored in `self._metadatas` accessible at `uvicore.db.metadatas`
        - All tables defined in a users package are linked tot his connection specific metadata by [database/table.py](https://github.com/uvicore/framework/blob/master/uvicore/database/table.py) which is inherited from each users table definition.
- Back in `uvicore/database/package/bootstrap.py` after `db init()`
    - Dynamically Import all `model` modules defined by all packages
    - Dynamically Import all `table` modules defined by all packages
        - When these tables are imported, they bind themselves to proper SQLAlchemy MetaData (`db.metadatas`) because of their [database/table.py](https://github.com/uvicore/framework/blob/master/uvicore/database/table.py) inheritance!
