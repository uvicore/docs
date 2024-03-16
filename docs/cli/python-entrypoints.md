# Python Entrypoints

Using `./uvicore` directly in app is a great way to bundle many packages commands into a single executable, but often we need actual `setuptools entrypoints`.

Sometimes those `entrypoints` might run a single click command, and sometimes they might run a `click group` of commands.


## Entrypoint for a Single Command

To create a `setuptools entrypoint` for a single command edit your packages `pyproject.toml` file like so:
```toml
[tool.poetry.scripts]
welcome = "myapp.commands.welcome:cli"
```

Ensure your poetry virtual environment is activated.

After this change you must run `poetry install` to register the new entrypoint.

Now you can simply run `welcome` from bash instead of using `./uvicore myapp welcome`.



## Entrypoint for a Click Command Group

To create a `setuptools entrypoint` for a `click group` edit your packages `pyproject.toml` file like so:
```toml
[tool.poetry.scripts]
myapp = 'myapp.commands.entrypoint:cli'
```

You must create this custom `commands/entrypoint.py` file to handle this `click group`.

This boostraps uvicore and dynamically adds all of this main apps commands into a click group
specifically made for this `setuptools entrypoints`


```python
import os
import sys
import uvicore
from uvicore.console import group
from myapp.package import bootstrap
from uvicore.support.module import load

# Bootstrap the Uvicore application from the console entrypoint
app = bootstrap.Application(is_console=True)()

# Define a new asyncclick group
@group()
def cli():
    pass

# Dynamically add in all commands from this package matching this command_group
command_group='myapp'
package = uvicore.app.package(main=True);
if 'console' in package:
    if (package.registers.commands and uvicore.app.is_console):
        for key, group in package.console['groups'].items():
            if key == command_group:
                for command_name, command_class in group.commands.items():
                    cli.add_command(load(command_class).object, command_name)

# Instantiate the asyncclick group
try:
    cli(_anyio_backend='asyncio')
except KeyboardInterrupt:
        try:
            sys.exit(0)
        except SystemExit:
            os._exit(0)
```

Ensure your poetry virtual environment is activated.

After this change you must run `poetry install` to register the new entrypoint.

Now you can simply run `myapp welcome` or `myapp --help` from bash instead of using `./uvicore myapp welcome`.
