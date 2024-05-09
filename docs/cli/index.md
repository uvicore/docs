---
# DOC STATUS
# ------------------------------------------------------------------------------
# 100% done
# Looking good!
# ------------------------------------------------------------------------------
title: CLI
---

# CLI

Uvicore has an asynchronous [Click](https://click.palletsprojects.com) command line that allows you to call your existing Uvicore **async** methods thanks to [AsyncClick](https://pypi.org/project/asyncclick/)!


In uvicore, the CLI, Web and API are simply **entrypoints** into your apps async functionality.  Therefore the CLI must await your async methods just as your HTTP controllers do.

The `./uvicore` CLI provides access to your own apps async commands as well as Uvicore's own built in command like 'http serve' and 'db reseed'!

