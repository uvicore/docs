# Writing Commands

In addition to the commands provided by Uvicore and other dependent packages, you may also build your own custom commands.  Commands are stored in your packages `commands/` directory.

## Generating Commands

To create new commands, you can use the `./uvicore gen command` schematic generator or build them by hand.

```bash
./uvicore gen command --help
```

Output
```
Usage: uvicore gen command [OPTIONS] NAME

  Generate a new CLI command schematic...

  USAGE:
      Commands should be lower_underscore and SINGULAR (plural is OK)
      Remember to manually add the command to your service provider!

      ./uvicore gen command welcome
      ./uvicore gen command process
      ./uvicore gen command scan_files

Options:
  --help  Show this message and exit.
```


## Registering Commands

Once you generate your new command, you must register your command with Uvicore.

You must define your commands in your packages `package/provider.py` Provider inside the `boot()` method.

You may register commands as a dictionary

```python
def boot(self) -> None:
    # You can define CLI groups and commands as a complete dictionary
    self.register_cli_commands({
        'myapp': {
            'help': 'MyApp Commands',
            'commands': {
                'welcome': 'myapp.commands.welcome.cli',
                'other': 'myapp.commands.other.cli',
            },
        },
    })
```

Or you you may register commands as `kwargs`

```python
def boot(self) -> None:
    # Or you can define commands as kwargs (multiple calls to self.commands() are appended)
    self.register_cli_commands(
        group='myapp',
        help='MyApp Commands',
        commands={
            'welcome': 'myapp.commands.welcome.cli',
            'other': 'myapp.commands.other.cli',
        },
    )
```



## Calling Commands

Use the `./uvicore` CLI interface to interact with your commands.

```bash
./uvicore myapp
```

Output

```
Usage: uvicore myapp [OPTIONS] COMMAND [ARGS]...

  MyApp Commands

Options:
  --help  Show this message and exit.

Commands:
  welcome  Welcome to Uvicore
  other    My Other Command
```

Execute your `welcome` command

```bash
./uvicore myapp welcome
```



## Command Structure

Here is an example of a basic command with no arguments or parameters.  The `"""Welcome to Uvicore"""` document block is the help text that shows in your `./uvicore` CLI output.

```python
import uvicore
from uvicore.support.dumper import dump, dd
from uvicore.exceptions import SmartException
from uvicore.console import command, argument, option


@command()
async def cli():
    """Welcome to Uvicore"""
    # ex: ./uvicore myapp welcome
    try:

        print("""Welcome to a Uvicore Example CLI Command!

This command lives in your commands/welcome.py file and is registered with the CLI
in your package/provider.py boot() method.  Create as many CLI commands as needed
and be sure to checkout the commands included with the uvicore packages.

~mReschke""")

    except SmartException as e:
        # Python exit() with any value means "error" in bash exit code speak!
        exit(e.detail)
```

Here is an example of a more advanced command with arguments and options.

```python
import uvicore
from uvicore.support.dumper import dump, dd
from uvicore.exceptions import SmartException
from uvicore.console import command, argument, option

@command(help="My Other Command")
@argument('id_or_name')
@option('--tenant', help='Tenant')
@option('--coin', default='BTC', help='Coin with Default')
@option('--json', is_flag=True, help='Output results as JSON')
async def get(id_or_name: str, tenant: str, coin: str, json: bool):
    # ex: ./uvicore myapp other --tenant bob --json
    try:
        # Do stuff
        dd(id_or_name, tenant, coin, json)
    except SmartException as e:
        # Python exit() with any value means "error" in bash exit code speak!
        exit(e.detail)
```
