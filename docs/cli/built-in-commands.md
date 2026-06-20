---
title: Built-In Commands
---

# Built-In Commands

Because your app depends on several Uvicore packages, your `./uvicore` CLI comes loaded with a
rich set of **built-in commands** for free.  These let you inspect your merged configs, view your
database connections, list your registered packages, dump your IoC bindings, explore your event
system, generate new schematics and run the dev HTTP server — all without writing a single line of
code.

Each command group is contributed by a different core Uvicore package, then merged together into
the single `./uvicore` interface:

| Group | Provided by | Purpose |
|-------|-------------|---------|
| [`app`](#uvicore-app) | `uvicore.foundation` | Running application information |
| [`config`](#uvicore-config) | `uvicore.configuration` | Inspect the deep-merged configuration |
| [`db`](#uvicore-db) | `uvicore.database` | Create, drop, seed and reseed tables |
| [`event`](#uvicore-event) | `uvicore.foundation` | Explore events and their listeners |
| [`gen`](#uvicore-gen) | `uvicore.console` (+ `orm`, `http`) | Generate new schematics |
| [`http`](#uvicore-http) | `uvicore.http` | Show routes and run the dev server |
| [`ioc`](#uvicore-ioc) | `uvicore.foundation` | Inspect the IoC container |
| [`package`](#uvicore-package) | `uvicore.foundation` | Inspect registered packages |

Running `./uvicore` with no arguments lists every available group, including your own app's
commands and any 3rd party package commands:

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

!!! tip
    Every command and sub-command accepts `--help`.  When in doubt, append `--help` to discover the
    available sub-commands, arguments and options — for example `./uvicore db --help` or
    `./uvicore db reseed --help`.

!!! note "See The Code on Github"
    The core command groups live across the Uvicore packages, for example
    [foundation/commands](https://github.com/uvicore/framework/blob/master/uvicore/foundation/commands),
    [configuration/commands](https://github.com/uvicore/framework/blob/master/uvicore/configuration/commands),
    [database/commands](https://github.com/uvicore/framework/blob/master/uvicore/database/commands) and
    [http/commands](https://github.com/uvicore/framework/blob/master/uvicore/http/commands).

---

## ./uvicore app

Application information for the currently running app.

```
Commands:
  info  Running Application Information
```

### ./uvicore app info

Show the **final, deep-merged** application information — name, paths, version, debug flag and the
fully resolved `redis`, `database`, `cache` and other config trees as they exist after every
package has merged its defaults and your app has applied its overrides.

```bash
./uvicore app info
```

Output (truncated)
```
:: Final Merged Application Information ::
OrderedDict({
    'name': 'App1',
    'main': Dict({'package': 'app1', 'provider': 'app1.package.provider.App1'}),
    'path': '/path/to/app1',
    'version': '0.1.0',
    'uvicore_version': '0.4.2',
    'debug': False,
    ...
})
```

---

## ./uvicore config

Inspect your configuration after all packages have been deep-merged together.  This is invaluable
for confirming that an override in your app's `config/` actually took effect.

```
Commands:
  get   Get a config value by key
  list  List all deep merged configs from all packages
```

### ./uvicore config list

List the entire deep-merged configuration dictionary from every registered package.

```bash
./uvicore config list
```

| Option | Description |
|--------|-------------|
| `--raw` | Show output without the pretty printer |

### ./uvicore config get

Get a single config value by its dotted key.

```bash
./uvicore config get app.name
./uvicore config get database.connections
```

| Argument | Description |
|----------|-------------|
| `KEY` | The dotted config key to retrieve (optional) |

| Option | Description |
|--------|-------------|
| `--raw` | Show output without the pretty printer |

!!! tip
    Configuration keys are accessed with dot-notation, exactly as you would in code with
    `uvicore.config('app.name')`.  See [Configuration](../getting-started/configuration.md) for
    more on how configs are merged.

---

## ./uvicore db

Manage your database tables across one or more connections.  See
[Database](../database/index.md) for the bigger picture on connections, tables and seeders.

```
Commands:
  connections  Show all packages database connections
  create       Create tables for connection(s)
  drop         Drop tables for connection(s)
  recreate     Recreate (drop/create) tables for connection(s)
  reseed       Reseed (drop/create/seed) tables for connection(s)
  seed         Seed tables for connection(s)
```

### ./uvicore db connections

Show the final, deep-merged database connections from every package.

```bash
./uvicore db connections
```

### ./uvicore db create / drop / recreate / seed / reseed

These five commands all take a `CONNECTIONS` argument — a comma separated list of connection names
(or `all` for every connection) — and operate on the tables for those connections.

| Command | Action |
|---------|--------|
| `create` | Create the tables |
| `drop` | Drop the tables |
| `recreate` | Drop, then create the tables |
| `seed` | Run the seeders to populate the tables |
| `reseed` | Drop, create, then seed the tables |

```bash
# A single connection
./uvicore db reseed app1

# Multiple connections (comma separated, no spaces)
./uvicore db recreate app1,auth

# Every connection
./uvicore db create all
```

| Argument | Description |
|----------|-------------|
| `CONNECTIONS` | Comma separated connection name(s), or `all` |

!!! danger "Destructive commands"
    `drop`, `recreate` and `reseed` **delete data**.  Use them freely against local/in-memory
    development databases, but be careful pointing them at anything you care about.

---

## ./uvicore event

Explore Uvicore's event system — every event your packages define and every listener registered
against them.  See [Events](../deeper/events/index.md) for how to define and dispatch events.

```
Commands:
  get        Show detailed info for one event
  list       List all events
  listeners  Show all event listeners/handlers
```

### ./uvicore event list

List every event known to the application.

```bash
./uvicore event list
```

### ./uvicore event listeners

Show every event listener/handler and the event it is bound to.

```bash
./uvicore event listeners
```

### ./uvicore event get

Show detailed info for a single event by name.

```bash
./uvicore event get uvicore.foundation.events.app.Booted
```

| Argument | Description |
|----------|-------------|
| `EVENT` | The full dotted name of the event |

---

## ./uvicore gen

Generate new **schematics** — boilerplate stub files for the common building blocks of a Uvicore
app.  The `gen` group itself is provided by `uvicore.console`, while the individual generators are
contributed by the `orm` and `http` packages.

```
Commands:
  api-controller   Generate a new HTTP API controller schematic
  command          Generate a new CLI command schematic
  composer         Generate a new web view composer schematic
  controller       Generate a new HTTP Web controller schematic
  model            Generate a new ORM model schematic
  seeder           Generate a new Database table seeder schematic
  table            Generate a new Database table schematic
```

Each generator prints its own naming conventions and examples under `--help`.  A quick summary:

| Command | Arguments | Naming convention |
|---------|-----------|-------------------|
| `command` | `NAME` | lower_underscore, singular (plural ok) |
| `model` | `NAME` `TABLE` | model singular, table plural |
| `table` | `NAME` | lower_underscore, plural |
| `seeder` | `TABLENAME` `MODELNAME` | tablename plural, modelname singular |
| `controller` | `NAME` | lower_underscore, singular |
| `api-controller` | `NAME` | lower_underscore, singular |
| `composer` | `NAME` | lower_underscore, singular |

```bash
./uvicore gen command scan_files
./uvicore gen model user users
./uvicore gen table posts
./uvicore gen seeder users user
./uvicore gen controller home
./uvicore gen api-controller user
./uvicore gen composer side_nav
```

!!! note
    After generating a `command`, remember to manually register it in your package's service
    provider.  See [Writing Commands](writing-commands.md) for the full walkthrough.

---

## ./uvicore http

HTTP related commands for inspecting routes and running the development server.  See the
[HTTP](../http/index.md) section for everything web and API.

```
Commands:
  routes  Show all Web and API Routes
  serve   Unicorn dev server (reload and logs)
```

### ./uvicore http routes

Show every registered Web and API route — method, path, name and endpoint.

```bash
./uvicore http routes
```

### ./uvicore http serve

Run the [Uvicorn](https://www.uvicorn.org/) development server with auto-reload and logging
enabled.  This is the quickest way to bring your app up locally.

```bash
./uvicore http serve
```

!!! tip
    `http serve` is for **development** only (reload + verbose logs).  For production you run
    Uvicorn/Gunicorn against your ASGI app directly — see [Serving](../http/index.md).

---

## ./uvicore ioc

Inspect the [IoC (Inversion of Control)](../deeper/ioc.md) container — every binding, singleton and
override that powers Uvicore's dependency injection.

```
Commands:
  bindings    List all Ioc Bindings
  get         Get a binding by name
  overrides   List Overridden Ioc Bindings
  singletons  List Singleton Ioc Bindings
  type        List Ioc Bindings of a Specific Type (comma separated)
```

### ./uvicore ioc bindings

List every binding registered in the IoC container.

```bash
./uvicore ioc bindings
```

| Option | Description |
|--------|-------------|
| `--raw` | Show output without the pretty printer |

### ./uvicore ioc singletons

List only the bindings registered as singletons.

```bash
./uvicore ioc singletons
```

### ./uvicore ioc overrides

List only the bindings that have been overridden by another package or your app.

```bash
./uvicore ioc overrides
```

### ./uvicore ioc type

List bindings of one or more specific types.

```bash
./uvicore ioc type model,controller
```

| Argument | Description |
|----------|-------------|
| `TYPE` | One or more binding types, comma separated |

### ./uvicore ioc get

Get a single binding by its name.

```bash
./uvicore ioc get uvicore.console.console
```

| Argument | Description |
|----------|-------------|
| `KEY` | The binding name (optional) |

| Option | Description |
|--------|-------------|
| `--raw` | Show output without the pretty printer |

---

## ./uvicore package

Inspect the packages registered with your application.  Packages are registered in **exact order of
dependency**, which these commands make visible.  See [Service Providers](../deeper/provider.md) for more.

```
Commands:
  get        Show detailed info for one package
  list       List all packages
  providers  Show providers graph
```

### ./uvicore package list

List every registered package in dependency-registration order, including each package's console
groups, config and metadata.

```bash
./uvicore package list
```

### ./uvicore package providers

Show the service provider graph — the order in which each package's providers register and boot.

```bash
./uvicore package providers
```

| Option | Description |
|--------|-------------|
| `--json` | Show the providers graph as JSON |

### ./uvicore package get

Show detailed info for a single package by name.

```bash
./uvicore package get uvicore.configuration
```

| Argument | Description |
|----------|-------------|
| `PACKAGE` | The full package name |

---

!!! tip "Built-In Command tips"
    - Append `--help` to **any** group or command to see its sub-commands, arguments and options.
    - Many inspection commands (`config`, `ioc`) support `--raw` to skip the pretty printer — handy
      when piping output to another tool.
    - `db` connection commands take a comma separated list of connection names, or `all`.
    - `drop`, `recreate` and `reseed` are **destructive** — they delete table data.
    - These commands are merged in from the core Uvicore packages; your own app's commands and any
      3rd party package commands appear right alongside them. See
      [Writing Commands](writing-commands.md) to add your own.
