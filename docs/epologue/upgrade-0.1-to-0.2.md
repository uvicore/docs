# Upgrade 0.1 to 0.2

## :material-pound: New Service Directory

- Rename the old `./services` directory to `./package`
- Change `./package/bootstrap.py` from `def application` to a `class Application`
```python
import uvicore
from uvicore.support import path
from uvicore.configuration import Env


class Application:
    """Bootstrap the application either from the CLI or Web entry points

    Bootstrap only runs when this package is running as the main app via
    ./uvicore or uvicorn/gunicorn server"""

    def __init__(self, is_console: bool = False):
        self.is_console = is_console

    def __call__(self):
        # Base path
        base_path = path.find_base(__file__)

        # Load .env from environs
        Env().read_env(base_path + '/.env')

        # Import this apps config (import must be after Env())
        from ..config.app import config as app_config

        # Bootstrap the Uvicore Application (Either CLI or HTTP entry points based on is_console)
        uvicore.bootstrap(app_config, base_path, self.is_console)

        # Return application
        return uvicore.app
```
- Rename `./package/yourapp.py` to `./package/provider.py`
- In `./package/provider.py` these imports and methods need to be changed
```py
# OLD Imports
from uvicore.console.provider import Cli
from uvicore.http.provider import Http
from uvicore.redis.provider import Redis
from uvicore.database.provider import Db
from uvicore.package import ServiceProvider

# NEW Imports
from uvicore.console.package.registers import Cli
from uvicore.http.package.registers import Http
from uvicore.redis.package.registers import Redis
from uvicore.database.package.registers import Db
from uvicore.package import Provider

# NOTICE ServiceProvider changed to Provider, so also change your class children.


# All of Uvicore register methods now start with "register_"
# So look through the entire file and make changes.
# Examples of new registration methods
self.register_redis_connections()
self.register_db_connections()
self.register_db_models()
self.register_db_tables()
self.register_db_seeders()
self.register_http_api_routes()
self.register_cli_commands()
```
- In `./uvicore` file change the bootstrap import and use a Class instead
```python
# OLD
from yourapp.services import bootstrap
app = bootstrap.application(is_console=True)

# NEW
from yourapp.package import bootstrap
app = bootstrap.Application(is_console=True)()
```
- Do the exact same for `./http/server.py`
- The config folder has changed as we now have multiple configs for visual clarity, however under the hood, uvicore only cares about the `app.py` and `package.py`.  In the new structure those files simply import the other sub files.  You don't have to do this and can keep it all in just 2 files if you want.  If you prefer to have a full separation, use the uvicore installer to install a fresh new 0.2 app and review how the configs are layed out.
- Modifications to `./config/app.py`
```python
# ------------------------------------------------------------------------------

# OLD - main is no longer a string
'main': 'yourapp',

# NEW
'main': {
    'package': 'yourapp',
    'provider': 'yourapp.package.provider.Yourapp'
},

# ------------------------------------------------------------------------------

# OLD - The old "packages" OrderedDict is now
# AND you must REMOVE your actual package there.  This is what "main" is for now.
'packages': OrderedDict({})

# NEW
'providers': {} # Or can still be an OrderedDict as well

# ------------------------------------------------------------------------------

# OLD - "bindings" is renamed to "ioc_bindings"
'bindings': {}

# NEW
'ioc_bindings': {}

# ------------------------------------------------------------------------------

# OLD - "paths" has moved from app.py to the package.py
# So MOVE your paths over to package.py

# ------------------------------------------------------------------------------
```
- Modifications to `./config/package.py`
```python
# ------------------------------------------------------------------------------
# Remember 'paths' has moved from app.py to package.py, so move those.

# ------------------------------------------------------------------------------
# OLD 'dependencies' is the same, except all the Uvicore paths have changed
# Everything is now .package.provider.X instead of .services.X

# Example OLD
'uvicore.foundation': {
    'provider': 'uvicore.foundation.services.Foundation',
},

# Example New
'uvicore.foundation': {
    'provider': 'uvicore.foundation.package.provider.Foundation',
},

# ------------------------------------------------------------------------------
```
