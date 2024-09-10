# Release Notes

## :material-pound: 0.1

Initial public beta release of Uvicore.

Used in production by a few internal companies, running a few dozen APIs and basic websites.

Not 100% feature complete.  The web at large would have many requests for enhancement.


## :material-pound: 0.2

Refactor of the "service" concept. The word `service` removed in favor or `package`, `provider`, and `registers`.

See [Upgrade 0.1 to 0.2](/epologue/upgrade/from-0.1-to-0.2/) for details.


## :material-pound: 0.3

Removed the async `encode/databases` wrapper and upgraded `SQLAlchemy` from from 1.4 up to the new async SQLAlchemy 2.0.
