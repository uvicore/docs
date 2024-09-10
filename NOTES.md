# Notes


## TODO

REMEMBER: Docs are also a SELLING TOOL!!!


## Screenshot specs

- i3, from exact split, move over 2 arrows
- stock konsole, increase font 3lrrx


## Example Application

We use ~/Code/wiki which is an `acme/wiki` uvicore app for all examples
    do NOT use yourapp anywhere, go remove them all with grep


## Hard to Remember

* camelCase vs PascalCase
* LINK - [Uvicore CLI](/cli/)
    * [DB Query Builder](/database/db-queries/)
* :material-auto-fix: FIXME

### Installation

The Installation page need screenshots of WHAT
./uvicore looks like
./uvicore wiki welcome looks like
and what ./uvicore http serve looks like
how home page + swagger /welcome





# Slogan

The Fullstack Asynchronous Web, API and CLI Python Framework

The Fullstack Asynchronous API+Web+CLI Python Framework

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

[Service Provider](/service-providers/)
[Pydantic](/orm-pydantic/)
[Uvicore CLI](/cli/)
[SuperDict](/superdict/)

[IoC](/ioc/)

[Uvicore Installer](/installation/)

[encode/databases](https://github.com/encode/databases)

[SQLAlchemy Core](https://docs.sqlalchemy.org/en/13/core/tutorial.html)

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
