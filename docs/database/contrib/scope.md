# Proper Scope


## :material-pound: Flow

- Engine is a global object created just once for a particular database server
    - PASS - Db class is singleton with self._engines by metakey!
- MetaData is also global
    - Having a single MetaData object for an entire application is the most common case, represented as a module-level variable in a single place in an application, often in a “models” or “dbschema” type of package
    - PASS - Db class is singleton with self._metadatas by metakey!
- Result object should live inside the conenct() block and never outside
    - PASS - db.fetchall() uses with engine.connect() and result.all() as return

Be sure to close all connections, they are SMALL scope
Because the Connection creates an open resource against the database, we want to limit our use of this object to a specific context.

```python
engine = create_engine("sqlite+pysqlite:///:memory:", echo=True)
with engine.connect() as conn:
    # SMALL scope for .connect() dies after with
    # do NOT return "Result" object, its SMALL scope as well
    result = conn.execute(text("select 'hello world'"))
    print(result.all())
```

ALSO the Result should be INSIDE the connection block, SMALL scope as well
    "The result of our SELECT was returned in an object called Result that will be
    discussed later. For the moment we’ll add that it’s best to use this object
    within the “connect” block, and to not use it outside of the scope of our connection."
