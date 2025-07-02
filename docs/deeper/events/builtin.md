# Built In Events

Uvicore dispatches several events that you may fine useful in your application.



## :material-pound: Foundation Events

Application bootstrap has registered all package service providers.

```python
from uvicore.foundation.events import app as AppEvents
AppEvents.Registered.listen(my_handler)

# or string based
events.listen('uvicore.foundation.events.app.Registered', my_handler)
```

Application bootstrap has booted all package service providers.

This is the best place to handle Uvicore being fully booted and ready to go.

```python
from uvicore.foundation.events import app as AppEvents
AppEvents.Booted.listen(my_handler)

# or string based
events.listen('uvicore.foundation.events.app.Booted', my_handler)
```




## :material-pound: HTTP Server Events

HTTP Server has been started.  This is the Starlette startup async event.

```python
from uvicore.http.events import server as HttpEvents
HttpEvents.Startup.listen(my_handler)

# or string based
events.listen('uvicore.http.events.server.Startup', my_handler)
```

HTTP Server has been shutdown.  This is the Starlette shutdown async event.

```python
from uvicore.http.events import server as HttpEvents
HttpEvents.Shutdown.listen(my_handler)

# or string based
events.listen('uvicore.http.events.server.Shutdown', my_handler)
```




## :material-pound: Console (CLI) Events

Console is starting up.  Runs before console command.

```python
from uvicore.console.events import command as ConsoleEvents
ConsoleEvents.Startup.listen(my_handler)

# or string based
events.listen('uvicore.console.events.command.Startup', my_handler)
```

Console is shutting down.  Runs after console command.

```python
from uvicore.console.events import command as ConsoleEvents
ConsoleEvents.Shutdown.listen(my_handler)

# or string based
events.listen('uvicore.console.events.command.Shutdown', my_handler)
```

Pytest console is starting up.  Runs before pytests.

```python
from uvicore.console.events import command as ConsoleEvents
ConsoleEvents.PytestStartup.listen(my_handler)

# or string based
events.listen('uvicore.console.events.command.PytestStartup', my_handler)
```

Pytest console is shutting down.  Runs after pytests.

```python
from uvicore.console.events import command as ConsoleEvents
ConsoleEvents.PytestShutdown.listen(my_handler)

# or string based
events.listen('uvicore.console.events.command.PytestShutdown', my_handler)
```

!!! info
    These pytest events are actually fired from your own projects `./tests/conftest.py`
