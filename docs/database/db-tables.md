# DB Tables

When using the default SQLAlchemy backend, defining your tables as SQLAlchemy tables gives you the ability to use Uvicore's query builder, or SQLAlchemy's query builder.  If you do not define any tables, then RAW SQL may be the only way to interact with your data.

Uvicore provides two methods to define your SQLAlchemy tables.


## :material-pound: Tables as Separate Files

Tables may be stored in separate files located in `database/tables/*`.  You may use the Uvicore schematic generator to create this table automatically, or create it by hand.



```bash
./uvicore gen table --help
./uvicore gen table posts
```

!!! warning "init file"
    Be sure to add your new table to the `database/tables/__init__.py`

The schematic includes many commented examples of how to use the table.  A form of quick inline documentation!

!!! tip
    In general, tables should be plural (posts) while their corresponding ORM model (if you decide to use the ORM) would be singular (post).  This is a convention rather than a rule.

A basic "wiki" `posts` table looks like this
```python
import uvicore
import sqlalchemy as sa
from uvicore.database import Table
from uvicore.support.dumper import dump

# Get related table names with proper prefixes
users = uvicore.db.tablename('auth.users')

@uvicore.table()
class Posts(Table):

    # Actual database table name
    # Plural table names and singular ORM model names are encouraged
    # Do not add a package prefix, leave that to the connection config
    name = 'posts'

    # Connection for this table from your config/database.py file
    connection = 'wiki'

    # SQLAlchemy Table definition
    # This will be converted into an actual SQLAlchemy Table() instance
    # and automatically associated with the proper SQLAlchemy Metadata
    # See https://uvicore.io/database/db-tables/
    # See https://docs.sqlalchemy.org/en/20/core/schema.html
    schema = [
        # Defaults: nullable=True, index=False, unique=False, primary_key=False

        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('unique_slug', sa.String(length=100), unique=True),
        sa.Column('title', sa.String(length=100)),
        sa.Column('body', sa.Text()),
        sa.Column('other', sa.String(length=100), nullable=True),
        sa.Column('creator_id', sa.Integer, sa.ForeignKey(f"{users}.id"), nullable=False),
        sa.Column('owner_id', sa.Integer, sa.ForeignKey(f"{users}.id"), nullable=False),
        sa.Column('created_at', sa.DateTime(), default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    ]

    # Optional SQLAlchemy Table() instance kwargs
    schema_kwargs = {
        # Enable SQLite autoincrements (this is OK even when not using SQLite)
        'sqlite_autoincrement': True,
    }
```

!!! notice
    Notice the `uvicore.db.tablename('auth.users')` above.  This gets the `users` table name from the `auth` package and obeys adding additional table prefixes defined in the configs.  Try not to use table names manually or the prefix config will be ignored!


If you are using the Uvicore [ORM](/database/orm-basics/) (optional), and you are defining your table in a separate file, simply point the `__tableclass__` to the proper table class.

```python
# ...
from acme.wiki.database.tables import posts as table

@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    """Wiki Posts"""

    # Database table definition
    # Optional as some models have no database table
    __tableclass__ = table.Posts

    #...
```


## :material-pound: Tables as Inline ORM

Some folks don't like having the table in separate files from the ORM models.  Uvicore also lets you define the table inline!

If you are using the Uvicore [ORM](/database/orm-basics/) (optional), and you want to define your tables inline instead of in a separate file, you may do so like this:

```python
# ...
from acme.wiki.database.tables import posts as table

# Get related table names with proper prefixes
users = uvicore.db.tablename('auth.users')

@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    """Wiki Posts"""

    # Database table definition
    # Optional as some models have no database table
    __connection__ = 'wiki'
    __tablename__ = 'posts'
    __table__ = [
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('unique_slug', sa.String(length=100), unique=True),
        sa.Column('title', sa.String(length=100)),
    ]
    #...
    # Model fields go here
    # ...
```

See the [ORM](/database/orm-basics/) documentation for more ORM specific details.


---


## :material-pound: Base Table

Notice all tables inherit from the `uvicore.database.Table` base class.  This class turns your simple `schema` table definition defined in `schame` into a full SQLAlchemy Table and attaches that table to the proper connections SQLAlchemy metadata found in `uvicore.db.metadatas`.  It does this using the `__init__(self)` constructor.

Checkout the [database/table.py](https://github.com/uvicore/framework/blob/master/uvicore/database/table.py) file below to see how the Base class build the `sa.Table()`

```python
import uvicore
import sqlalchemy as sa
from abc import ABCMeta
from typing import Dict, List
from uvicore.support.dumper import dd, dump

@uvicore.service()
class Table:

    @property
    def table(self):
        return self.schema

    def __init__(self):
        self.metadata = uvicore.db.metadata(self.connection)
        prefix = uvicore.db.connection(self.connection).prefix
        if prefix is not None:
            self.name = str(prefix) + self.name

        # Only enhance schema if connection string backend is 'sqlalchemy'
        if uvicore.db.connection(self.connection).backend == 'sqlalchemy':
            self.schema = sa.Table(
                self.name,
                self.metadata,
                *self.schema,
                **self.schema_kwargs
            )
```

If you want to modify the actual SQLAlchemy table **after** it is created, simply extend this parent base `__init__(self)` method.  See [#composite-indexes](/database/db-tables/#composite-indexes) below for an example.

!!! note
    Notice that any `schema_kwargs` you defined in your table are passed into the SQLAlchemy Table() method giving you extra control!


---


## :material-pound: Table Examples

Below are some quick examples on some tricky to remember SQLAlchemy table definitions.  For brevity we are only showing the `schema` List.

See [https://docs.sqlalchemy.org/en/20/core/constraints.html](https://docs.sqlalchemy.org/en/20/core/constraints.html) for more complex definitions.


### :material-pound: :material-pound: Multiple Unique Constraints

Most SQL dialects allow for multiple unique constraints.

```python
schema = [
    sa.Column('id', sa.Integer, primary_key=True),

    # Polymorphic Relations
    sa.Column('addressable_type', sa.String(length=50)),
    sa.Column('addressable_id', sa.Integer),
    sa.Column('address_id', sa.Integer, sa.ForeignKey(f"{addresses}.id"), nullable=False),
    sa.UniqueConstraint('addressable_type', 'addressable_id', 'address_id')
    #sa.UniqueConstraint('addressable_type', 'addressable_id', 'address_id', name='uix_1')
]
```


---


### :material-pound: :material-pound: Multiple Primary Keys

Most SQL dialects allow for multiple primary key constraints.  Useful when you won't want an auto incrementing PK but don't have uniqueness of a single field.

```python
schema = [
    sa.Column('price_list_id', sa.Integer, sa.ForeignKey(f"{price_lists}.id"), nullable=False),
    sa.Column('stock_item_id', sa.Integer, sa.ForeignKey(f"{items}.id"), nullable=False),
    sa.Column('value', sa.DECIMAL(precision=8, scale=2)),
    sa.Column('disabled', sa.Boolean(), default=False),
    sa.PrimaryKeyConstraint('price_list_id', 'stock_item_id')
]
```

You may also define multiple primary keys by using the `primary_key=True` parameter twice
```python
sa.Column('price_list_id', sa.Integer, sa.primary_key=True, sa.ForeignKey(f"{price_lists}.id"), nullable=False),
sa.Column('stock_item_id', sa.Integer, sa.primary_key=True, sa.ForeignKey(f"{items}.id"), nullable=False),
```


---


### :material-pound: :material-pound: Multiple Foreign Key Constraints

The `invoices` table has a 2 column primary key constraint

```python
schema = [
    sa.Column("invoice_id", sa.Integer, primary_key=True),
    sa.Column("ref_num", sa.Integer, primary_key=True),
    sa.Column("description", sa.String(60), nullable=False),
]
```

And the `invoice_items` table with dual foreign key constraints

```python
invoices = uvicore.db.tablename('wiki.invoices')
schema = [
    sa.Column('item_id', sa.Integer, primary_key=True),
    sa.Column('item_name', sa.String(60), nullable=False),
    sa.Column('invoice_id', sa.Integer, nullable=False),
    sa.Column('ref_num', sa.Integer, nullable=False),
    sa.ForeignKeyConstraint(
        ['invoice_id', 'ref_num'], [f"{invoices}.invoice_id", f"{invoices}.ref_num"],
        onupdate="CASCADE",
        ondelete="SET NULL",
    )
]
```

---


### :material-pound: :material-pound: Composite Indexes

The base `Table` class is what turns your `schema` property into an actual `sa.Table()`.  That full table is saved back to your Class as `self.schema`.  To add composite indexes to a table you must add it AFTER the actual SQLAlchemy table is created.  To achieve this in Uvicore, simply overwrite the `__init__` and after calling `super()`, modify `self.schema` (which is the actual sa.Table).

```python
import uvicore
import sqlalchemy as sa
from uvicore.database import Table

@uvicore.table()
class Posts(Table):
    name = 'posts'
    connection = 'wiki'
    schema = [
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('unique_slug', sa.String(length=100), unique=True),
        sa.Column('title', sa.String(length=100), index=True),
        sa.Column('val_a', sa.String(length=100), nullable=False),
        sa.Column('val_b', sa.String(length=100), nullable=False),
    ]
    schema_kwargs = {}

    def __init__(self):
        # Call parent from uvicore.database.Table which sets self.schema
        # as the fully built SQLAlchemy Table object.
        super().__init__()

        # Add additional attributes to our SQLAlchemy table
        sa.Index('idx_1', self.schema.c.val_a, self.schema.c.val_b)
```


---


### :material-pound: :material-pound: Cascades

```python
schema = [
    sa.Column('id', sa.Integer, primary_key=True),
    sa.Column(
        'address_id',
        sa.Integer,
        sa.ForeignKey(f"{addresses}.id"),
        nullable=False,
        onupdate='CASCADE',
        ondelete='CASCADE'
    ),
]
```


