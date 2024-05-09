# Console Commands

Uvicore uses [asyncclick](https://pypi.org/project/asyncclick/) to provide elegant [click](https://pypi.org/project/click/) command line interfaces that allow you to `await` all your existing async methods!


## Uvicore Command Interface

All uvicore packages come with a `./uvicore` CLI.

This CLI allow you to interact with your packages CLI commands, Uvicore's [Built-In Commands](built-in-commands), and any other commands provided by packages you depend on.

```bash
./uvicore
```

Output
```
Usage: uvicore [OPTIONS] COMMAND [ARGS]...

  Uvicore 0.2.0
  The Fullstack Async Web, API and CLI Python Framework

  Copyright (c) 2023 Matthew Reschke License http://mreschke.com/license/mit

Options:
  --version  Show the version and exit.
  --help     Show this message and exit.

Commands:
  app      Uvicore Application Information
  config   Configuration Information
  event    Uvicore Event Information
  gen      Generate New Schematics (commands, models, views...)
  ioc      Uvicore Ioc (Inversion of Control) Information
  package  Uvicore Package Information
  myapp    MyApp Commands
```

Not only are your own apps commands available from this interface, but other Uvicore and 3rd party module commands are also available.


## Build in Commands

Uvicore comes with several build-in commands to view your configs, routes, IoC bindings and package information.

Explore the built-in Uvicore CLI Commands!

