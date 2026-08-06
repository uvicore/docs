---
title: Logging
---

# Logging

Uvicore ships with a colorful, structured logger available everywhere as `uvicore.log`.  It writes to your console (beautifully rendered with [rich](https://rich.readthedocs.io/)) and to log files on disk, with per-message layout helpers that make CLI output and log files a pleasure to read.

Because logging bootstraps very early, `uvicore.log` is available almost immediately — even inside your package provider's `register()` and `boot()` methods.

```python
import uvicore

uvicore.log.info('Something happened')
uvicore.log.warning('Something suspicious happened')
uvicore.log.error('Something bad happened')
```

---

## Configuration

Logging configuration lives in your **running application's** config — the `logger` key of `config/app.py`, which the installer splits out into its own `config/logger.py` concern file.

!!! warning "The logger config is app-only, deliberately"
    The `uvicore.logging` package does **not** provide its own `config/logger.py`, and you cannot override logging config with the usual deep-merge-by-the-same-config-key trick.

    Logging bootstraps before any package config is merged (right after the configuration service itself) precisely so the log is available in every other package's `register()` and `boot()`.  That ordering is the whole point, and it means there is exactly one place logging is configured: the app that is actually running.

Most of the config has `.env` overrides, so day-to-day tweaking is a one-line change:

```
# Levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_CONSOLE_ENABLED=true
LOG_CONSOLE_LEVEL="INFO"
LOG_CONSOLE_COLORS=true
LOG_FILE_ENABLED=true
LOG_FILE_LEVEL="INFO"
LOG_FILE_PATH="/var/log/acme.wiki/%Y-%m-%d_{channel}.log"
LOG_FILE_RETENTION=30
```

And the full config, from `config/logger.py`:

```python
from uvicore.configuration import env

logger = {
    'console': {
        'enabled': env.bool('LOG_CONSOLE_ENABLED', True),
        'level': env('LOG_CONSOLE_LEVEL', 'INFO'),
        'colors': env.bool('LOG_CONSOLE_COLORS', True),
        'filters': [],
        'exclude': [
            'uvicore.orm',
            'asyncio',
            'aiosqlite',
        ],
    },
    'file': {
        'enabled': env.bool('LOG_FILE_ENABLED', True),
        'level': env('LOG_FILE_LEVEL', 'INFO'),
        'file': env('LOG_FILE_PATH', '/var/log/acme.wiki/%Y-%m-%d_{channel}.log'),
        'retention': env.int('LOG_FILE_RETENTION', 0),

        # Legacy rotation, used ONLY when 'file' has no strftime tokens
        'when': env('LOG_ROTATE_WHEN', 'midnight'),
        'interval': env.int('LOG_ROTATE_INTERVAL', 1),
        'backup_count': env.int('LOG_ROTATE_BACKUP_COUNT', 7),

        'filters': [],
        'exclude': [
            'uvicore.orm',
            'asyncio',
            'aiosqlite',
        ],
    },
    'channels': {
        'Auditor': {},
        'Importer': {},
        'Processor': {},
    },
}
```

Every key is optional — anything you leave out is deep-merged from sensible defaults.

---

## Log Levels

Uvicore uses the standard Python log levels plus one custom level, `NOTICE` (25), which sits between `INFO` (20) and `WARNING` (30).  It is a real registered level, so your log file's `%(levelname)s` column shows `NOTICE` too.

```python
uvicore.log.debug('Verbose detail nobody needs in production')
uvicore.log.info('The normal narrative of what is happening')
uvicore.log.notice('Worth noticing, but not a problem')
uvicore.log.warning('Suspicious, but we carried on')
uvicore.log.error('This failed')
uvicore.log.critical('This failed catastrophically')
uvicore.log.exception('This failed and we are logging it from an except block')
```

Calling the logger directly is shorthand for `info()`:

```python
uvicore.log('Same as uvicore.log.info(...)')
```

`WARNING`, `ERROR` and `CRITICAL` go to **STDERR**.  Everything else goes to **STDOUT**.  This lets you pipe a CLI command's narrative output somewhere while still seeing its problems.

---

## Layout Helpers

These are what make Uvicore's CLI output look designed rather than dumped.  Each one is a normal log message at `INFO` level, so it lands in your log file too.

```python
uvicore.log.header('Nightly Run')        # full width rule with a centered title
uvicore.log.header2('Batch 7')           # lighter full width rule
uvicore.log.header3('Details')           # inline styled title
uvicore.log.header4('Sub details')       # inline styled title, lightest

uvicore.log.item('First tier item')      # ● glyph
uvicore.log.item2('Second tier item')    # ◆ glyph
uvicore.log.item3('Third tier item')     # ✚ glyph
uvicore.log.item4('Fourth tier item')    # ▸ glyph

uvicore.log.separator()                  # ═══ full width
uvicore.log.line()                       # ─── full width
uvicore.log.blank()                      # one blank line
```

Items accept a `level` for indentation:

```python
uvicore.log.item('Top level')
uvicore.log.item2('Nested under it', level=2)
uvicore.log.item3('Nested deeper', level=3)
```

And `nl()` is a chainable `blank()`, handy for spacing a header off the previous output:

```python
uvicore.log.nl().header('Seeding Tables')
```

Which renders like this:

```bash
════════════════════════════════  Nightly Run  ═════════════════════════════════
    ● starting all sections

──────────────────────────────────  Batch 7  ───────────────────────────────────
    ● 500 rows transformed
⚠  2 rows skipped
────────────────────────────────────────────────────────────────────────────────
 ℹ NOTICE  all sections reported
```

---

## Console Output

The console handler is powered by rich.  Colors and decorations come from the `UVICORE_LOG_THEME` in `uvicore/logging/logger.py` — a rich `Theme` you can re-skin if you want a different look.

The file handler is deliberately **not** styled.  It stays a plain `%(asctime)s | %(levelname)s | %(name)s | %(message)s` line so your logs remain greppable.

If you want dumb, ASCII, STDOUT-only output — for a CI system or a log collector that chokes on ANSI — turn colors off:

```
LOG_CONSOLE_COLORS=false
```

That swaps rich for a plain `logging.StreamHandler`.

---

## Dumping Variables

`dump()` and `dd()` do not work inside the HTTP request pipeline (there is nowhere for them to print).  `uvicore.log.dump()` does:

```python
uvicore.log.dump(my_dict, my_model)
```

It pretty-prints to the console when the console is at `DEBUG` (or when running pytest), and separately writes the values to your log file when the file handler is at `DEBUG`.

---

## Filters and Excludes

Every log record carries the name of the logger that emitted it.  Framework internals name themselves — `uvicore.orm`, `uvicore.http`, `uvicore.auth`, `uvicore.model_router` — and third-party libraries name themselves too (`sqlalchemy`, `asyncio`, `aiosqlite`, `httpx`, `faker.factory`).

`exclude` drops records whose logger name matches; `filters`, when non-empty, keeps **only** records that match.

```python
'console': {
    # Show nothing except these
    'filters': ['uvicore.orm'],

    # Show everything except these
    'exclude': ['asyncio', 'aiosqlite'],
},
```

!!! warning "Matching is by prefix, not exact name"
    This mirrors how Python's own logging filters behave: `uvicore` matches `uvicore.orm` and everything else beneath it.  Handy for silencing a whole subsystem — but watch out for accidental matches.  An exclude of `Import` also kills `Importer`, and `Transform` also kills `Transformer`.

You can also scope a single message to a logger name with `name()`, which is chainable and applies to exactly the next call:

```python
uvicore.log.name('acme.wiki.importer').info('This record is named, and filterable')
```

!!! tip
    `name()` is a **filtering** scope, not a destination — it changes which filters and excludes apply, not which file the record lands in.  For a separate log *file*, use a [channel](#multiple-log-files-channels).

    The scope is task-local (it lives in a `ContextVar`), so two concurrent async tasks cannot clobber each other's scope.

---

## File Logging

Uvicore gives you two ways to write log files.  Which one you get depends entirely on the filename you configure.

### Date-stamped filenames (recommended)

Put [strftime](https://docs.python.org/3/library/time.html#time.strftime) tokens in the path and the date becomes part of the filename:

```python
'file': '/var/log/acme.wiki/%Y-%m-%d_{channel}.log',
```

```bash
/var/log/acme.wiki/2026-07-29_default.log
/var/log/acme.wiki/2026-07-30_default.log
```

A long-running process — a queue worker, a Kafka or Redis consumer looping forever — rolls onto the next day's file **by itself** when the date changes.  Nothing is ever renamed.

This is the recommended mode, for three concrete reasons:

- **Multiple processes can share one log.** With `uvicorn --workers N`, or a CLI command running alongside your web server, every process independently derives the same wall-clock filename and appends to it.  There is nothing to coordinate and nothing to race on.
- **The filename never lies.** Every timestamp inside `2026-07-29_default.log` really does start with `2026-07-29`, because the filename is derived from each record's own creation time rather than from the clock at write time.
- **Nothing is renamed, so nothing can be lost.** See the warning under legacy rotation below.

`{channel}` is substituted with `default` for your main log, and with the channel name for each [named channel](#multiple-log-files-channels).

!!! note
    `{channel}` is optional.  If you leave it out, your main log uses the path exactly as written and each channel gets the channel name appended before the extension — so `/var/log/acme.wiki/wiki.log` yields `wiki.log`, `wiki_Processor.log`, `wiki_Auditor.log`.  A channel always gets its own file; that is the whole point of a channel.

You can use any strftime tokens you like, including ones that create directories:

```python
'file': '/var/log/acme.wiki/%Y/%m/%Y-%m-%d_{channel}.log',
```

Missing directories are created for you.

#### Retention

Dated files accumulate forever unless you tell Uvicore otherwise:

```python
'file': {
    'file': '/var/log/acme.wiki/%Y-%m-%d_{channel}.log',
    'retention': 30,   # days, 0 = keep forever
},
```

The sweep runs when the file rolls (about once a day, never per record) and only ever deletes files matching that log's own pattern — one channel can never prune another channel's files.

!!! note
    `retention` is not the same thing as `backup_count`.  `backup_count` belongs to the legacy rotating handler and **cannot** work with dated filenames, so `retention` exists to replace it.  For compression, size caps or offsite shipping, reach for `logrotate` instead — this is deliberately the simple 90% case.

!!! tip "Two dated-file caveats worth knowing"
    Dated filenames trade rename races for a permissions race: if two processes running as **different users** append to the same file, the second gets `EACCES` on every record.  Use a shared group, or put `{pid}` in the filename.

    Also, `O_APPEND` makes each write atomic, so lines from different processes never interleave — unless a single record exceeds the ~8KB stream buffer (possible when logging whole SQL statements or `dump()`ing large dicts).

### Legacy time-based rotation

If your filename has **no** strftime tokens, you get Python's `TimedRotatingFileHandler`, exactly as older Uvicore versions did:

```python
'file': {
    'file': '/var/log/acme.wiki/wiki.log',
    'when': 'midnight',
    'interval': 1,
    'backup_count': 7,
},
```

The live file is always `wiki.log`; at each boundary it is *renamed* to `wiki.log.2026-07-29` and a fresh `wiki.log` is started.

!!! danger "Do not use rotation if more than one process writes the same file"
    Rename-based rotation is only safe for a single writer.  With multiple processes on one filename — `uvicorn --workers N`, or a CLI command running beside your server — one process renames the file out from under the others.  The losers keep appending to the renamed (or already-deleted) file, and because their internal "next rollover" time is never updated they **never rotate again** for the rest of their lives.  The result is silently lost log data.

    There is a second, milder problem even with a single writer: if the process is idle across a boundary, the archive is named after the interval that *should* have ended rather than the data inside it.  A process idle Monday through Thursday produces one file named for Monday containing four days of records, and no files at all for Tuesday and Wednesday.

    Date-stamped filenames have neither problem.  Prefer them.

---

## Multiple Log Files (Channels)

Real applications have sections — an importer, an auditor, a rules engine — and mixing all of their output into one file makes every one of them harder to read.  **Channels** give each section its own log file.

Define them in your `logger` config:

```python
'channels': {
    'Auditor': {},
    'Importer': {},
    'Processor': {},
    'RulesEngine': {},
    'Transformer': {},
},
```

And write to them:

```python
uvicore.log.channel('Processor').info('Batch 7 complete')
uvicore.log.channel('Auditor').warning('Checksum mismatch on row 412')
```

With a dated `{channel}` path that yields exactly one file per section, per day:

```bash
/var/log/acme.wiki/2026-07-29_Auditor.log
/var/log/acme.wiki/2026-07-29_Importer.log
/var/log/acme.wiki/2026-07-29_Processor.log
/var/log/acme.wiki/2026-07-29_RulesEngine.log
/var/log/acme.wiki/2026-07-29_Transformer.log
```

A channel supports the **entire** logger interface — every level, every layout helper, `dump()`, and chaining:

```python
log = uvicore.log.channel('Processor')
log.nl().header('Batch 7')
log.item('500 rows transformed')
log.item2('2 rows skipped', level=2)
log.dump({'batch': 7, 'rows': 500})
```

### Channels are safe to hold onto

A channel object carries no per-call state, so unlike `name()` you can grab one once and keep it across `await` boundaries and across threads.  This is the recommended pattern for a long-running consumer:

```python
class Processor:

    def __init__(self):
        self.log = uvicore.log.channel('Processor')

    async def handle(self, message):
        self.log.item('processing {}'.format(message.id))
        await self.transform(message)
        self.log.item2('done', level=2)
```

Channels are created lazily on first use and cached, so calling `uvicore.log.channel('Processor')` repeatedly always returns the same object.

### What a channel inherits

A channel inherits the top-level `console` and `file` config, which is why `{}` is usually all you need.  Override anything you like:

```python
'channels': {
    # Inherits everything
    'Processor': {},

    # File only, no console noise
    'Auditor': {
        'console': {'enabled': False},
    },

    # Its own level, its own file, its own retention
    'Debugger': {
        'file': {
            'level': 'DEBUG',
            'file': '/var/log/acme.wiki/%Y-%m-%d_debug.log',
            'retention': 3,
        },
    },
},
```

The one thing a channel does **not** inherit is `filters` and `exclude`.  Those match on logger names like `uvicore.orm` and `asyncio`, which have nothing to do with your channel names — inheriting an include-style `filters` list would leave every channel file silently empty.  A channel can still set its own explicitly.

### Channel isolation

Each channel gets its own Python logger and its own handlers, and it does **not** propagate to the root logger.  This means:

- A channel's records go to its own file and the console, and never into your default log file.  No double writes.
- Conversely, `uvicore.log.info()` never writes into a channel's file.
- Records from framework internals and third-party libraries continue to land in your **default** log file, where your `exclude` lists filter them.

!!! note
    Because channels do not propagate, a handler you attach to the *root* Python logger (pytest's `caplog`, a Sentry handler) will not see channel records.  Attach it to the channel's logger instead:

    ```python
    import logging
    logging.getLogger('Processor').addHandler(my_handler)
    ```

!!! warning "Channel names cannot contain a dot"
    Dots create parent/child relationships in Python's logging hierarchy.  A channel named `uvicore` would become the parent of `uvicore.orm` and silently vacuum every ORM record into its file.  Uvicore raises if you try.  Use flat names like `Processor`.

### Channels defined at runtime

Channels are read live from config on first access, so a provider's `boot()` can add one:

```python
def boot(self) -> None:
    uvicore.config.app.logger.channels.Reporter = {'file': {'level': 'DEBUG'}}
```

And an undefined channel is not an error — it is simply created from your defaults, so a typo produces a stray file rather than a crashed application.

---

## Under the Hood

`uvicore.log` is a singleton bound in the [IoC Container](ioc.md) under `uvicore.logging.logger.Logger` with the aliases `Logger`, `logger`, `Log` and `log`.  Like anything else in the container it can be [overridden](ioc.md) from your app's `config/app.py`:

```python
'overrides': {
    'ioc_bindings': {
        'Logger': 'acme.wiki.overrides.logger.Logger',
    },
},
```

The default log writes to Python's **root** logger, which is what lets records from SQLAlchemy, `databases`, `asyncio`, `httpx` and friends flow into your log file where your `exclude` lists can filter them.
