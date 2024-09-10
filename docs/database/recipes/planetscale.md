# PlanetScale & Vitess

[PlanetScale](https://planetscale.com/) is a Cloud Hosted Sharded MySQL database built on [Vitess](https://vitess.io/)

PlanetScale looks and feels [mostly] like any other MySQL database, with a single connection (VTGate proxy) despite having multiple sharded mysqld backends.

PlanetScale requires an SSL connection


## :material-pound: SSL

The `options` dictionary in the `config/database.py` are values passed directly to the `dialect` connection.  The default `pymysql` dialect in `encode/databases` is `aiomysql` which accepts an SSL parameter among others.

Example `config/database.py` PlanetScale SSL Connection

```python
    # Standard Uvicore DB Connections
    'connections': {

        # PlanetScale MySQL SSL Connection
        'ps': {
            'driver': 'mysql',
            'dialect': 'pymysql',
            'host': 'aws.connect.psdb.cloud',
            'port': 3306,
            'database': 'mydb',
            'username': 'xyzsk9db...',
            'password': 'pscale_pw_abc...',
            'prefix': None,
            'options': {
                # SSL required for PlanetScale
                'ssl': True,
            }
        }
    }
```

!!! note
    PlanetScale seems a bit more strict on RESERVED words.  So be sure to wrap all columns in backticks -  \`mycolumn\`
