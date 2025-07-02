# SQLAlchemy Query Builder

Uvicore provides [3 Layers](/database/#the-3-layers) of database access.  Here we discuss forgoing the [Uvicore ORM](/database/orm-basics/) and the [Uvicore Query Builder](/database/db-queries/) and jump straignt into SQLAlchemy's own Query Builder!

Generally the [ORM](/database/orm-basics/) is the best way to utilize and query your tables.  And if you prefer to skip the ORM, give the [Uvicore Query Builder](/database/db-queries/) a shot.  It's simple and elegant.

However, if you need ultimate SQLAlchemy power, keep reading!

!!! note
    A prerequisite to using SQLAlchemy's Query Builder is to define your [DB Tables](/database/db-tables/).  If you prefer zero table definitions, then [SQLAlchemy RAW SQL](/database/db-sa-raw/) may be for you!


---


## :material-pound: Select
