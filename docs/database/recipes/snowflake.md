# Snowflake

Uvicore can connect to snowflake like any other database using [SQLAlchemy](https://www.sqlalchemy.org/)

## Install the Driver

You must install the `snowflake-sqlalchemy` driver to connect to Snowflake using SQLAlchemy

```bash
# If using poetry
poetry add snowflake-sqlalchemy

# If using pip
pip install snowflake-sqlalchemy
```



## Connection Details

You may define a Snowflake connection in your `config/database.py` file


```python

from uvicore.configuration import env
from uvicore.typing import OrderedDict


# --------------------------------------------------------------------------
# Database Connections
#
# Uvicore allows for multiple database connections (backends) each with
# their own connection name.  Use 'default' to set the default connection.
# Database doesn't just mean a local relational DB connection.  Uvicore
# ORM can also query remote APIs, CSVs, JSON files and smash them all
# together as if from a local database join!
# --------------------------------------------------------------------------
database = {
    'default': env('DATABASE_DEFAULT', 'sf'),
    'connections': {

        # Snowflake Connection
        'sf': {
            'backend': 'sqlalchemy',
            'dialect': env('DB_WIKI_DIALECT', 'snowflake'),
            'account': env('DB_WIKI_ACCOUNT', ''),
            'database': env('DB_WIKI_DB', ''),
            'schema': env('DB_WIKI_SCHEMA', ''),
            'warehouse': env('DB_WIKI_WAREHOUSE', ''),
            'username': env('DB_WIKI_USER', ''),
            'password': env('DB_WIKI_PASSWORD', ''),
            'role': env('DB_WIKI_ROLE', ''),
            'options': {
                # If using a Private Key, replace all new lines with blanks (all on one string)
                # and remove -----BEGIN PRIVATE KEY----- and -----END PRIVATE KEY-----
                # Or take the .pem file and run it through a DER base64 to get a single string like so
                # openssl pkcs8 -in snowflake.pem -inform PEM -outform DER -nocrypt | base64 -w 0
                'private_key': env('DB_WIKI_PRIVATE_KEY', ''),
            }
        },
    }
}
```
