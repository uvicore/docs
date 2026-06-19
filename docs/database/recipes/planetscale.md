# PlanetScale & Vitess

[PlanetScale](https://planetscale.com/) is a Cloud Hosted Sharded MySQL database built on [Vitess](https://vitess.io/)

PlanetScale looks and feels [mostly] like any other MySQL database, with a single connection (VTGate proxy) despite having multiple sharded mysqld backends.

PlanetScale requires an SSL connection


## SSL

PlanetScale is a MySQL database, so the `dialect` is `mysql` and the `driver` is a MySQL driver such as the default async `aiomysql`.  The `options` dictionary is passed straight through to that driver, and `aiomysql` accepts an `ssl` parameter.

Example `config/database.py` PlanetScale SSL Connection

```python
    # Standard Uvicore DB Connections
    'connections': {

        # PlanetScale MySQL SSL Connection
        'ps': {
            'backend': 'sqlalchemy',
            'dialect': 'mysql',
            'driver': 'aiomysql',
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

!!! tip
    Remember `dialect` is the *type* of database (`mysql`) and `driver` is the *library* used to talk to it (`aiomysql`, `pymysql`...).  Don't swap them.  See [DB Configuration](../db-config.md#backends-drivers-and-dialects) for the full explanation.

!!! note
    PlanetScale seems a bit more strict on RESERVED words.  So be sure to wrap all columns in backticks -  \`mycolumn\`
