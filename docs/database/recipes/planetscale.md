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

                # Required as of PlanetScale's 2026-09-01 Vitess change, see Autocommit below
                'autocommit': True,
            }
        }
    }
```

## Autocommit

!!! danger "Set this on every PlanetScale connection"
    As of **2026-09-01** PlanetScale changed Vitess to report the correct autocommit value in the
    initial handshake packet.  If you do nothing, a long-lived PlanetScale connection can start
    failing with aborted transactions.

Vitess used to report the **wrong** autocommit value during the connection handshake.  The practical
effect was that `pymysql`, `aiomysql` and `asyncmy` connections ran with autocommit effectively
**ON**, even though the driver intended it OFF.  Once Vitess reports the value correctly, those same
connections behave as `autocommit=False` — which leaves an implicit transaction open on every
connection, and Vitess aborts a transaction left open for more than **20 seconds**.

PlanetScale offers two fixes.  Set either through the `options` dictionary, which Uvicore passes
straight to the driver as SQLAlchemy's `connect_args`:

| Option | Set | Use when |
|---|---|---|
| **A** | `'autocommit': True` | You rely on default behavior.  **Preserves** how your PlanetScale connection behaves today. |
| **B** | `'init_command': 'set autocommit=0'` | Your app wraps all queries in explicit transactions, or holds connections for less than 20 seconds. |

```python
'options': {
    'ssl': True,
    'autocommit': True,          # Option A, or:
    # 'init_command': 'set autocommit=0',   # Option B
}
```

Option A is the right default for most apps.  Uvicore needs no special support for either — `options`
is already a straight passthrough to `connect_args`.

See PlanetScale's
[pymysql handshake autocommit](https://planetscale.com/docs/vitess/connecting/pymysql-handshake-autocommit)
notice for the upstream details.

!!! warning "Do NOT copy `autocommit: True` onto a non-PlanetScale connection"
    It is tempting to set this everywhere "to be safe", on the assumption that it is the default
    anyway.  **It is not.**  `pymysql` and `aiomysql` both default to `autocommit=False`, and a
    plain MySQL session reports `@@session.autocommit = 0` when no such kwarg is passed.  It only
    *looks* enabled on PlanetScale today because of the handshake bug described above.

    Forcing it True is not cosmetic — it silently disables rollback.  An `INSERT` followed by
    `connection.rollback()` stays **committed**, because the statement was already committed at the
    driver level.  Set it only on the connections that actually point at PlanetScale/Vitess, and
    leave your other MySQL, MariaDB and Aurora connections alone.

---

!!! tip
    Remember `dialect` is the *type* of database (`mysql`) and `driver` is the *library* used to talk to it (`aiomysql`, `pymysql`...).  Don't swap them.  See [DB Configuration](../db-config.md#backends-drivers-and-dialects) for the full explanation.

!!! tip "Long-running processes"
    Connections are pooled per engine.  `pre_ping` defaults to **True**, so a connection VTGate
    closed while it sat idle is detected and replaced rather than handed to your query.  If you run
    day-long worker or audit processes, see [Connection Pooling](../db-config.md#connection-pooling)
    to also tune `recycle`, `size` and `max_overflow`.

!!! note
    PlanetScale seems a bit more strict on RESERVED words.  So be sure to wrap all columns in backticks -  \`mycolumn\`
