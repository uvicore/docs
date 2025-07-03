# Notes


db methods to document

.execute
.all - Get many records from query. Returns empty List if no records found
.fetchall -  Alias to .all()
.first - Get one (first/top) record from query. Returns None if no records found
.fetchone - Alias to .first()
.one - Get one record from query. Throws Exception if no data found or querying more than one record
.one_or_none - Get one record from query.  Returns None if no record found.  Throws Exception of querying more than one record
.scalars - Get many scalar values from query.  Returns empty List if no records found. If selecting multiple columns, returns List of FIRST column only.
.scalar - Get a single scalar value from query. Returns None if no record found.  Returns first (top) if more than one record found
.scalar_one - Get a single scalar value from query.  Throws Exception if no data found or if querying more than one record
.scalar_one_or_none - Get a single scalar value from query.  Returns None if no record found.  Throws Exception if querying more than one record

.insertmany - Bulk insert many rows, returning bulk primary keys (for databases that support INSERT..RETURNING)
.insertone - Insert one row, returning the one rows PK (as a tuple in case of dual PKs)




## Document Status

**Other Pages**

- [x] Home Page
- [ ] Features (partial)

**Going down the list of all uvicore core modules**

- [ ] auth
- [ ] cache
- [ ] configuration
    - 100% reviewed again 2025-02-08, its DONE!
- [ ] console
- [ ] container
- [ ] contracts
- [ ] database
    - Fix notes about SA 1.4 now
    - Fix PlanetScale config exmaple, its different for aiomysql vs pymysql...
- [ ] events
- [ ] exceptions
    - I added SmartException in `http/exceptions/smart/` but did NOT test the 'Throw from Controller' part.  Double check the code works.
    - Also add to the `/cli` section ?
- [ ] factories ?
- [ ] foundation
- [ ] http
- [ ] http_client
- [ ] jobs
- [ ] logging
- [ ] mail
- [ ] orm
- [ ] package
- [ ] redis
- [ ] support
- [ ] templating
- [ ] typing

**Other**

- [ ] Changelog for 0.3
- [ ] Upgrade from 0.2 to 0.3




## TODO

REMEMBER: Docs are also a SELLING TOOL!!!

DB query builder has NO insert() capabilities, you can do it manually like so for now
```python
            query = uvicore.db.table('audit_queue').insert()
            values = {
                'client_id': client_id,
                'last_ro_detail_audit_transformed_at': datetime.strptime('2000-01-01 00:00:00', "%Y-%m-%d %H:%M:%S"),
                'last_count_summary_audit_transformed_at': datetime.strptime('2000-01-01 00:00:00', "%Y-%m-%d %H:%M:%S"),
            }
            values[last_audit_field] = last_audit_date
            # await(uvicore.db.query()
            #     .table('audit_queue')
            #     .create(values)
            # )
            await uvicore.db.insertone(query, values)

```


# Apostrophe

- If you want to keep it singular and show OWNERSHIP then its 's
    - Ex: It is defined in your package's `db.py` file
    - Ex: Uvicore's own `ORM`
    - The family's house burt down
- No apostrophe (pacakges, connections) means plural, more than one
    - There are many families at school
- If word already ends in s already (plural or singluar) and you want to show ownership
    - The Jess's house burnt down




## Screenshot specs

- i3, from exact split, move over 2 arrows
- stock konsole, increase font 3lrrx
- I believe I used online https://gifcap.dev/ to record screen to gif


## Example Application

We use `~/Code/wiki` which is an `acme/wiki` uvicore app for all examples
    do NOT use yourapp anywhere, go remove them all with grep


## Hard to Remember

* camelCase vs PascalCase
* LINK - [Uvicore CLI](/cli/)
    * [DB Query Builder](/database/db-queries/)
* fixme
:material-auto-fix: FIXME
:material-auto-fix: Content Coming Soon...





### Installation

The Installation page need screenshots of WHAT
./uvicore looks like
./uvicore wiki welcome looks like
and what ./uvicore http serve looks like
how home page + swagger /welcome





# Slogan

## Github Description
The Full Stack Asynchronous Python Framework with the performance of FastAPI and the elegance of Laravel! - https://uvicore.io


## CLI Output

The Fullstack Async Web, API and CLI Python Framework



## Other Ideas


The Fullstack Asynchronous Web, API and CLI Python Framework

The Fullstack Asynchronous API+Web+CLI Python Framework

The Full Stack Asynchronous Python Framework with the performance of FastAPI and the elegance of Laravel!

Uvicore
    = Dual Routers based on Starlette and FastAPI
    + Automatic Model router for instant OpenAPI endpoints
    + Beautiful Custom ORM with built in Pydantic Validations and column mapping
    + Async everything, including CLI commands that can await your async methods
    + Instant app scaffolding to get started building modules and apps instantly
    + File generators to scaffold controllers, commands, models, tables and other code


    + Design apps to be Modules and Modules to run as Apps (no shell to host your modules)

    Starlette
    + FastAPI
    + Pydantic
    + SqlAlchemy Core
    + Custom ORM
    +

The Fullstack Async Web, API and CLI Python Framework

The Fullstack Async Python Web, API and CLI Framework

The Fullstack Python Web/API/CLI Async Framework

The Fullstack Python Async Application Framework

The Fullstack Python Async Web, API & CLI Framework



A Fast Async Python Framework for CLI, Web and API

High Performance Web, API and CLI Python Framework

High Performance Async Fullstack Web, API and CLI Python Framework

The Async Fullstack Web, API and CLI Python Framework

High Performance Async Fullstack Python Web, API and CLI Framework

Python async Web, API and CLI fullstack Framework

Python Fullstack Asynchronous Web, API and CLI Framework

Asynchronous Python Web, API and CLI Fullstack Framework






# Mkdocs and Material


## Common Links

[Modular Concept](/deeper/modular/)

[Package Provider](/deeper/provider/)
[Pydantic](/database/orm-pydantic/)
[Uvicore CLI](/cli/)
[SuperDict](/deeper/superdict/)

automatic [API Model Router](/http/api/model-router/)

[IoC](/deeper/ioc/)

[Uvicore CLI](/cli/)

[ORM](/database/orm-basics/)
[Query Builder](/database/db-queries/)
[SQLAlchemy Query Builder](/database/db-sa-queries/)

[ORM vs Query Builder vs RAW SQL](/database/#orm-vs-query-builder-vs-raw)

[Configuration System](/getting-started/configuration/)

[Uvicore Installer](/getting-started/installation/)

[encode/databases](https://github.com/encode/databases)

[FastAPI](https://github.com/fastapi/fastapi)

[Starlette](https://github.com/encode/starlette)

[Jinja](https://github.com/pallets/jinja)

[SQLAlchemy Core](https://docs.sqlalchemy.org/en/20/core/)

[SQLAlchemy](https://www.sqlalchemy.org/)

[SQLAlchemy Core](https://docs.sqlalchemy.org/en/20/core/)

[AsyncClick](https://github.com/python-trio/asyncclick)

[View Composers](/view-composers/)



## Common paragraphs


In order to use the database layer with Uvicore you must first ensure you have installed the `database` extras from the framework.  This is by default already included in the `uvicore-installer`.
```
# Poetry pyproject.toml
uvicore = {version = "0.1.*", extras = ["database", "redis", "web"]}

# Pipenv Pipfile
uvicore = {version = "==0.1.*", extras = ["database", "redis", "web"]}

# requirements.txt
uvicore[database,redis,web] == 0.1.*
```



After the database extras have been installed you must update your `config.package.py` `dependencies` OrderedDict in `config/package.py`
```python
    'dependencies': OrderedDict({
        'uvicore.foundation': {
            'provider': 'uvicore.foundation.services.Foundation',
        },
        # ...
        'uvicore.database': {
            'provider': 'uvicore.database.services.Database',
        },
        # ...
    }),
```

!!! warning
    This section is for contributing developers of the uvicore source code. Or for folks who just wish to learn how uvicore works under the hood!


!!! note "See The Code on Github"
    - [Exceptions](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/__init__.py)
    - [Handlers](https://github.com/uvicore/framework/blob/master/uvicore/http/exceptions/handlers.py)
    - [Status Code Constants](https://github.com/uvicore/framework/blob/master/uvicore/http/status.py)





## Admonitions

https://squidfunk.github.io/mkdocs-material/reference/admonitions/

!!! note
    This is the `!!! note` admonition

!!! abstract
    This is the `!!! abstract` admonition

!!! info
    This is the `!!! info` admonition

!!! info "Custom Title Here"
    This is the `!!! info "Custom Title Here"` admonition

!!! tip
    This is the `!!! tip` admonition with a code block

    ```python
    def hi():
        """Code in a admonition provided by superfences"""
        pass
    ```

---

!!! note ""
    No title use ""

---

!!! check
    asdf

---



---

!!! warning "With title"
    Warning here

---

!!! danger
    asdfasdfasdf
    asdf

---

???+ info "Collapsible Admonition"
    Collapsible note
    Plus means default to open

---

!!! seealso
    asdfasdfasdf
    asdf


## Content Tabs

!!! example

    === "Mac"

        ```bash
        do mac stuff
        ```

    === "Linux"

        ```bash
        do linux stuff
        ```


## Footnotes

Lorem ipsum[^1] dolor sit amet, consectetur adipiscing elit.[^2]



[^1]: Lorem ipsum dolor sit amet, consectetur adipiscing elit.
[^2]:
    Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    multi line


## Icons and Emojis

Smile Emoji :smile:

See https://emojiguide.com/ or https://emojipedia.org for all emoji.

I use the twitter emoji

You can also just paste 🧒 emoji right in markdown.  Or use things like :slightly_frowning_face:

This theme comes with these 3 FULL SETS of icons!

* :material-account-circle: – `.icons/material/account-circle.svg`
* :fontawesome-regular-laugh-wink: – `.icons/fontawesome/regular/laugh-wink.svg`
* :octicons-octoface-16: – `.icons/octicons/octoface-16.svg`


## Tasklist


* [x] Lorem ipsum dolor sit amet, consectetur adipiscing elit
* [ ] Vestibulum convallis sit amet nisi a tincidunt
    * [x] In hac habitasse platea dictumst
    * [x] In scelerisque nibh non dolor mollis congue sed et metus
    * [ ] Praesent sed risus massa
* [ ] Aenean pretium efficitur erat, donec pharetra, ligula non scelerisque
