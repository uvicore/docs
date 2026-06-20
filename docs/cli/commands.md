# Console Commands

Uvicore uses [asyncclick](https://pypi.org/project/asyncclick/) to provide elegant [click](https://pypi.org/project/click/) command line interfaces that allow you to `await` all your existing async methods!


## Uvicore Command Interface

All uvicore packages come with a `./uvicore` CLI.

This CLI allow you to interact with your packages CLI commands, Uvicore's [Built-In Commands](built-in-commands.md), and any other commands provided by packages you depend on.

```bash
./uvicore
```

Output
```
Usage: uvicore [OPTIONS] COMMAND [ARGS]...

  App1 v0.1.0
  Powered by https://uvicore.io v0.4.2
  The Fullstack Async Web, API and CLI Python Framework

Options:
  --version  Show the version and exit.
  --help     Show this message and exit.

Commands:
  app      Uvicore Application Information
  app1     App1 Commands
  config   Configuration Information
  db       Database Commands
  event    Uvicore Event Information
  gen      Generate New Schematics (commands, models, views...)
  http     Uvicore HTTP Commands
  ioc      Uvicore Ioc (Inversion of Control) Information
  package  Uvicore Package Information
```

Not only are your own apps commands available from this interface, but other Uvicore and 3rd party module commands are also available.


## Built-In Commands

Uvicore comes with many built-in commands to view your configs, database connections, routes, IoC
bindings, events and package information, plus generators and a dev server.  These are merged in
from the core Uvicore packages your app depends on, and appear right alongside your own commands.

Explore them all in [Built-In Commands](built-in-commands.md)!

