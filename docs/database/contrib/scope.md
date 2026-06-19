# Proper Scope

!!! warning
    This section is for contributing developers of the uvicore source code. Or for folks who just wish to learn how uvicore works under the hood!


## SQLAlchemy Engine

According to the SQLAlchemy Core documentation, the `engine` (from `create_engine`) should be a global/singleton object created just once for a particular database server/connection.

This is achieved in Uvicore because the [Db](https://github.com/uvicore/framework/blob/master/uvicore/database/db.py) module is bound as a `singleton` in the [IoC](../../deeper/ioc.md)

After uvicore is fully booted, all packages DB connections are organized and sync or async engines are created for them and stored in the DB singleton and accessible at `uvicore.db.engines`!



## SQLAlchemy Metadata

According to the SQLAlchemy Core documentation, each unique connections `Metadata` should also be a global/singleton object.

This is achieved in Uvicore similar to the `engine` above.  The DB module is a singleton and on boot, creates unique `Metadata` objects for each unique connection accessible at `uvicore.db.metadatas`.  As each SQLAlchemy `table` is created from your packages, they are associated with the proper `Metadata` automatically.


## SQLAlchemy Connect and Results

According to the SQLAlchemy Core documentation, each query [engine] connection and the `Results` of that query should be scoped inside the `connect` block.  This means the SQLAlchemy `Results` object is not returned from the execution method directly.

Uvicore handles this in all of the helper execution classes inside [db.py](https://github.com/uvicore/framework/blob/master/uvicore/database/db.py) (all, fetchall, first, fetchone, one, one_or_none, scalars, scalar, scalar_one, scalar_one_or_none etc...).  The only exception to this rule is the generic `db.execute()` method which does return the `sa.CursorResult` directly as it is up to the caller to handle results and scope properly.

All of this means SQLAlchemy's `.connect() or .begin()` is scoped to just the query execution itself.  There is no need to manually open or close a connection.

