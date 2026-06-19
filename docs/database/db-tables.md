# DB Tables

When using the default SQLAlchemy backend, defining your tables as SQLAlchemy tables gives you the ability to use Uvicore's query builder, or SQLAlchemy's query builder.  If you do not define any tables, then RAW SQL may be the only way to interact with your data.

Uvicore gives you a few ways to define a table, and they all produce the same thing: a standard SQLAlchemy `Table` associated with the right connection's metadata.

- **A dedicated `@uvicore.table()` class in a separate file** under `database/tables/` (the most common, and usable with or without the ORM).
- **A dedicated `@uvicore.table()` class in the same file** as your model.
- **Fully inline on the ORM model** itself, no `Table` class at all.

Whichever you pick, an ORM model attaches to its table through the same handful of class variables, see [How a Model Finds Its Table](#how-a-model-finds-its-table) below.


## Tables as Separate Files

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


If you are using the Uvicore [ORM](orm-basics.md) (optional), and you are defining your table in a separate file, simply point the `__tableclass__` to the proper table class.

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


## Tables in the Same File

Some folks don't like splitting their table into a separate file from the ORM model, and that's perfectly fine.  Just define the `@uvicore.table()` class in the **same file** as your model and point `__tableclass__` at it.  A model always references its table through `__tableclass__`, whether that table lives in `database/tables/` or right next to the model.

```python
import uvicore
import sqlalchemy as sa
from uvicore.database import Table
from uvicore.orm import Model, ModelMetaclass, Field

# Get related table names with proper prefixes
users = uvicore.db.tablename('auth.users')

# The SQLAlchemy table, defined right above the model
@uvicore.table()
class Posts(Table):
    name = 'posts'
    connection = 'wiki'
    schema = [
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('unique_slug', sa.String(length=100), unique=True),
        sa.Column('title', sa.String(length=100)),
    ]
    schema_kwargs = {}

# The ORM model, in the same file, pointing at the table above
@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    """Wiki Posts"""

    __tableclass__ = Posts

    # Model fields go here
    # ...
```

See the [ORM](orm-basics.md) documentation for more ORM specific details.


### How a Model Finds Its Table

Internally, a model resolves its table through four class variables.  When you use `__tableclass__`, Uvicore derives the other three from it automatically:

| Variable | Meaning | Derived from `__tableclass__` |
|----------|---------|-------------------------------|
| `__tableclass__` | The `@uvicore.table()` class | (you set this) |
| `__connection__` | The connection name | `__tableclass__.connection` |
| `__tablename__` | The table name | `__tableclass__.name` |
| `__table__` | The `sa.Table` instance | `__tableclass__.schema` |


## Tables Inline on the Model

If you'd rather not declare a `Table` class at all, you can define the schema **fully inline** on the model.  Set `__connection__`, `__tablename__`, and a raw `__table__` list of SQLAlchemy columns, and Uvicore builds the real `sa.Table` for you (associating it with the connection's metadata and applying any table prefix, exactly like a `Table` class would).

```python
import uvicore
import sqlalchemy as sa
from uvicore.orm import Model, ModelMetaclass, Field

@uvicore.model()
class Post(Model['Post'], metaclass=ModelMetaclass):
    """Wiki Posts"""

    # Define the table schema right here, inline
    __connection__ = 'wiki'
    __tablename__ = 'posts'
    __table__ = [
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('unique_slug', sa.String(length=100), unique=True),
        sa.Column('title', sa.String(length=100)),
    ]
    # Optional, the inline equivalent of a Table class's schema_kwargs
    __table_kwargs__ = {'sqlite_autoincrement': True}

    id: Optional[int] = Field('id', primary=True, read_only=True)
    slug: str = Field('unique_slug')
    title: str = Field('title')
```

When you define a table inline, `__connection__` and `__tablename__` are **required** (there is no `__tableclass__` to derive them from), and `__table__` must be a **list** of `sa.Column` definitions.  Uvicore turns that list into a built `sa.Table` the moment the model class is defined.

!!! note "Inline-table models load after the database boots"
    Because Uvicore builds the `sa.Table` immediately (it needs the connection's metadata), an inline-table model must be imported *after* the database has bootstrapped, which is exactly what happens when you register it with `register_db_models()` in your [provider](../deeper/provider.md).  This is the same requirement that already applies to any model using `__tableclass__`, so in practice nothing changes.  If you import such a model too early you'll get a clear error telling you so.

!!! tip
    Inline is great for small, self-contained models.  For anything you want to query with the [DB Query Builder](db-queries.md) outside the ORM, or share across models, a dedicated [Table class](#tables-as-separate-files) is still the cleaner choice, the table can be used without the ORM at all.


---


## Base Table

Notice all tables inherit from the `uvicore.database.Table` base class.  This class turns your simple `schema` table definition into a full SQLAlchemy Table and attaches that table to the proper connection's SQLAlchemy metadata found in `uvicore.db.metadatas`.  It does this using the `__init__(self)` constructor.

!!! note
    When you define a table [inline on a model](#tables-inline-on-the-model), the ORM `ModelMetaclass` performs this very same work (building the `sa.Table` from your `__table__` list, applying the prefix, and attaching it to the connection's metadata).  Inline tables and `Table` classes therefore end up identical.

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

If you want to modify the actual SQLAlchemy table **after** it is created, simply extend this parent base `__init__(self)` method.  See [#composite-indexes](db-tables.md#composite-indexes) below for an example.

!!! note
    Notice that any `schema_kwargs` you defined in your table are passed into the SQLAlchemy Table() method giving you extra control!


---


## Table Examples

Below are some quick examples on some tricky to remember SQLAlchemy table definitions.  For brevity we are only showing the `schema` List.

See [https://docs.sqlalchemy.org/en/20/core/constraints.html](https://docs.sqlalchemy.org/en/20/core/constraints.html) for more complex definitions.


### Multiple Unique Constraints

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


### Multiple Primary Keys

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
sa.Column('price_list_id', sa.Integer, sa.ForeignKey(f"{price_lists}.id"), primary_key=True, nullable=False),
sa.Column('stock_item_id', sa.Integer, sa.ForeignKey(f"{items}.id"), primary_key=True, nullable=False),
```


---


### Multiple Foreign Key Constraints

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


### Composite Indexes

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


### Cascades

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


