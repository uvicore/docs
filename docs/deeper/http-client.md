# HTTP Client

Uvicore comes with the async `aiohttp` HTTP client so you can talk to other API's

!!! note
    Uvicore also comes with `httpx`, another async HTTP client that is used during pytests.  However uvicore does not provide a standard way to access it like it does for `aiohttp`.  So you are on your own there :)


## :material-pound: Dependencies

The HTTP client is available to all levels of Uvicore, regardless of the options you chose when running the [Uvicore Installer](/getting-started/installation/)

You will notice in your your `config/dependencies.py` file that HTTP client is enabled by default

```python
dependencies = OrderedDict({
    # ...
    # HTTP async client based on aiohttp.
    'uvicore.http_client': {
        'provider': 'uvicore.http_client.package.provider.HttpClient',
    },
    # ...
```





## :material-pound: Basic Usage

Basic usage is to make the HTTP Client form the IoC and use it like so

```python
import uvicore
from uvicore.support.dumper import dump, dd

async def some_async_method():
    http = uvicore.ioc.make('aiohttp')
    url = 'https://petstore3.swagger.io/api/v3/pet/findByStatus?status=available'
    async with http.get(url) as r:
        if r.status == 200:
            dump(r)
            dump(await r.text())
            dump(await r.json())
```






## :material-pound: Example Basic Auth GET Helper

```python
import json
import uvicore
import aiohttp

async def http_get(url: str, *, json: bool = True, basic_auth: str = None) -> tuple:
    """HTTP GET call using AIOHTTP"""

    # Async HTTP Client (aiohttp)
    http = uvicore.ioc.make('aiohttp')

    # Optional Basic Auth
    auth = None
    if basic_auth:
        (user, password) = basic_auth.split(':')
        auth = aiohttp.BasicAuth(user, password)

    # Make the call
    code = 404
    results = ""
    async with http.get(url, auth=auth) as response:
        code = response.status
        if json:
            # json() will fail if the content type is not json
            # Some APIs return JSON strings but with content type plain/text
            # So on failure, try json.loads
            try:
                results = await response.json()
            except:
                results = json_loads(await response.text())
        else:
            results = await response.text()
    return (code, results)
```









## :material-pound: Example Simple SugarCRM Client

Just a basic example of building your own SugarCRM client class to login and interact with the Sugar API.  This example shows `GET` method only, but you "get" the point :)  This code saves the login token to a temp file to re-use it.  If the token expires, the `GET` request will attempt to login once before failing.

```python
import uvicore

@uvicore.service('acme.wiki.sugar.client.SugarClient', aliases=['sugar-client'], singleton=True)
class SugarClient:
    """Generic Async AIOHTTP Rest client for Sugar"""

    @property
    def config(self):
        # Your config/package.py file might have configs like this
        # 'sugar': {
        #     'url': env('SUGAR_URL', 'https://crm.example.com/rest/v10'),
        #     'client': env('SUGAR_CLIENT', 'my-python-client'),
        #     'secret': env('SUGAR_SECRET', 'xyz'),
        #     'platform': env('SUGAR_PLATFORM', 'base'),
        #     'username': env('SUGAR_USERNAME', 'me@example.com'),
        #     'password': env('SUGAR_PASSWORD', 'xyz'),
        # },
        return uvicore.config.acme.wiki.sugar

    @property
    def http(self):
        return uvicore.ioc.make('aiohttp')

    async def login(self, refresh = False):
        """Login to Sugar /oauth2/token and get an access token"""

        # Payload for /oauth2/token
        url = self.config.url
        payload = {
            'grant_type': 'password',
            'client_id': self.config.client,
            'client_secret': self.config.secret,
            'username': self.config.username,
            'password': self.config.password,
            'platform': self.config.platform,
        }
        headers = {
            'Content-Type': 'application/json'
        }

        # Cache login token in a tmp file by payload hash
        token_file = '/tmp/sugar.token.' + hash.md5(payload)

        # If force re-login, remove token_file
        if refresh: os.remove(token_file)

        # If token_file exists, use that token instead of hitting Sugar again
        if os.path.exists(token_file):
            f = open(token_file, 'r')
            token = str(f.readline())
            f.close()
            return token;

        # Login to sugar via /oauth2/token
        async with self.http.post(f"{url}/oauth2/token", json=payload, headers=headers) as r:
            if r.status == 200:
                json_response = await r.json()
                token = json_response['access_token']

        # Cache token in token_file
        f = open(token_file, 'w')
        f.write(token)
        f.close()

        # Return token
        return token

    async def get_enum(self, module, field):
        """HTTP GET a modules fields enum values"""
        return await self._http_get(f"{self.config.url}/{module}/enum/{field}")

    async def get(self, module,
        *,
        fields: List = None,
        filter: Dict = None,
        max_num: int = 25,
    ) -> dict:
        """HTTP GET a module with parameters from Sugar API"""

        # Build API Payload
        payload = {}
        if fields: payload['fields'] = fields
        if filter: payload['filter'] = filter
        if max_num: payload['max_num'] = max_num

        # HTTP GET
        return await self._http_get(f"{self.config.url}/{module}", payload)


    async def _http_get(self, url, payload = None):
        # Get sugar oauth2 token
        token = await self.login()

        # Craft URL and headers
        headers = {
            'Content-Type': 'application/json',
            'oauth-token': token
        }

        # HTTP GET Sugar API, retry login on 400 failure
        async with self.http.get(f"{url}", json=payload, headers=headers) as r:
            if r.status == 200:
                return await r.json()
            elif r.status == 401 or r.status == 400:
                # Relogin and try again, token may have expired
                token = await self.login(True)
                headers = {
                    'Content-Type': 'application/json',
                    'oauth-token': token
                }
                async with self.http.get(f"{url}/{module}", json=payload, headers=headers) as r2:
                    if r2.status == 200:
                        return await r2.json()
                    else:
                        raise Exception(await r2.text() + ' - Status ' + str(r.status))
            else:
                raise Exception(await r.text() + ' - Status ' + str(r.status))
```

To use this `SugarClient`

```python
import uvicore
from acme.wiki.sugar.client import SugarClient
# or SugarClient = uvicore.ioc.make('sugar-client')

accounts = (await SugarClient.get(
    module='Accounts',
    max_num=999,
    fields=['id', 'name']
))['records']
```








## :material-pound: Example FusionAuth Client


```python
import uvicore
from uvicore.configuration import env
from uvicore.support.dumper import dump, dd
from uvicore.typing import Dict
from uvicore.exceptions import SmartException


@uvicore.service('mreschke.fusionauth.client.Client',
    aliases=['fusionauth'],
    singleton=True
)
class Client:
    """Generic Async AIOHTTP Rest client for FusionAuth"""

    @property
    def config(self):
        return uvicore.config.mreschke.fusionauth

    @property
    def allowed_tenants(self):
        return [k for (k,v) in self.config.tenant_keys.items() if v]

    async def verify_tenant(self, tenant: str = None):
        if tenant is None: tenant = self.config.default_tenant or 'default'
        if tenant.lower() not in self.allowed_tenants:
            await self.not_found('Invalid tenant.  Must be one of {}'.format(str(self.allowed_tenants)))
        return tenant.lower()

    async def api_key(self, tenant: str, master_key: bool = False) -> str:
        if master_key:
            key = self.config.master_key
        else:
            key: str = self.config.tenant_keys[tenant]
        if key: return key
        await self.not_found('API key not found in config for tenant {}'.format(tenant))

    async def url(self, path: str) -> str:
        auth_url = self.config.url
        if auth_url[-1] == '/': auth_url = auth_url[0:-1]  # Remove trailing / from base
        if path[0] == '/': path = path[1:]  # Remove leading / from path
        if auth_url: return auth_url + '/' + path
        await self.not_found('FusionAuth URL not found in config')

    async def get(self, path: str, tenant: str = None, master_key: bool = False):
        # Get aiohttp client session from IoC singleton
        http = uvicore.ioc.make('aiohttp')

        # Get proper API key
        key = await self.api_key(tenant, master_key)

        # Get full URL
        url = await self.url(path)

        # Async aiohttp GET
        async with http.get(url, headers={'Authorization': key}) as r:
            #dump(r)
            if r.status == 200:
                return await r.json()
            try:
                detail = await r.json()
            except Exception as e:
                detail = await r.text()
            await self.exception(detail or str(r.status) or 'Unknown error', status_code=r.status)

    async def post(self, path: str, tenant: str = None, master_key: bool = False, json: Dict = None):
        # Get aiohttp client session from IoC singleton
        http = uvicore.ioc.make('aiohttp')

        # Get proper API key
        key = await self.api_key(tenant, master_key)

        # Get full URL
        url = await self.url(path)

        async with http.post(url, json=json, headers={'Authorization': key}) as r:
            #dump(r)
            if r.status == 200:
                return await r.json()
            try:
                #dump('x')
                #detail='x'
                detail = await r.json()
            except Exception as e:
                detail = await r.text()
            await self.exception(detail or 'Not Found', status_code=r.status)

    async def put(self, path: str, tenant: str = None, master_key: bool = False, json: Dict = None):
        # Get aiohttp client session from IoC singleton
        http = uvicore.ioc.make('aiohttp')

        # Get proper API key
        key = await self.api_key(tenant, master_key)

        # Get full URL
        url = await self.url(path)

        async with http.put(url, json=json, headers={'Authorization': key}) as r:
            #dump(r)
            if r.status == 200:
                return await r.json()
            try:
                #dump('x')
                #detail='x'
                detail = await r.json()
            except Exception as e:
                detail = await r.text()
            await self.exception(detail or 'Not Found', status_code=r.status)

    async def patch(self, path: str, tenant: str = None, master_key: bool = False, json: Dict = None):
        # Get aiohttp client session from IoC singleton
        http = uvicore.ioc.make('aiohttp')

        # Get proper API key
        key = await self.api_key(tenant, master_key)

        # Get full URL
        url = await self.url(path)

        async with http.patch(url, json=json, headers={'Authorization': key}) as r:
            #dump(r)
            if r.status == 200:
                return await r.json()
            try:
                #dump('x')
                #detail='x'
                detail = await r.json()
            except Exception as e:
                detail = await r.text()
            await self.exception(detail or 'Not Found', status_code=r.status)

    async def delete(self, path: str, tenant: str = None, master_key: bool = False):
        # Get aiohttp client session from IoC singleton
        http = uvicore.ioc.make('aiohttp')

        # Get proper API key
        key = await self.api_key(tenant, master_key)

        # Get full URL
        url = await self.url(path)

        async with http.delete(url, headers={'Authorization': key}) as r:
            if r.status == 200:
                return await r.text()
                #return await r.json()
            try:
                #dump('x')
                #detail='x'
                detail = await r.json()
            except Exception as e:
                detail = await r.text()
            await self.exception(detail or 'Not Found', status_code=r.status)



    async def not_found(self, message: str):
        if uvicore.app.is_http:
            from uvicore.http.exceptions import NotFound
            raise NotFound(message)
        else:
            await uvicore.ioc.make('aiohttp').close()
            raise Exception(message)

    async def exception(self, message: str, *, status_code=503):
        raise SmartException(message, status_code)
```


An Example `repository/app.py` that adds a higher level "app" endpoint abstraction


```python
import uvicore
from mreschke.fusionauth.client import Client as fa
from uvicore.support.dumper import dump, dd
from uvicore.typing import Dict, List, Optional
from uvicore.exceptions import SmartException

URL = 'api/application'

async def find(id_or_name: str, tenant: Optional[str] = None) -> Dict:
    """Get one application by ID or name"""
    tenant = await fa.verify_tenant(tenant)

    # Get application by name
    # FusionAuth does not have an endpoint to get by name, so we'll get all and filter
    is_guid = len(id_or_name) == 36 and id_or_name.count('-') == 4
    if not is_guid:
        apps = await list(tenant)
        for app in apps:
            if app.name == id_or_name:
                return app
        return None

    url = URL + '/' + id_or_name
    try:
        async def query():
            response = await fa.get(url, tenant)
            return Dict(response['application'])
        return await uvicore.cache.remember(tenant + '/' + url, query)
    except SmartException as e:
        raise SmartException(e.detail, message='Cannot query ' + url)


async def list(tenant: Optional[str] = None) -> List[Dict]:
    """Get all applications"""
    tenant = await fa.verify_tenant(tenant)

    url = URL
    response = ''
    try:
        async def query():
            response = await fa.get(url, tenant)
            if not response: response['applications'] = []
            return [Dict(x) for x in response.get('applications')]
        return await uvicore.cache.remember(tenant + '/' + url, query)
    except SmartException as e:
        raise SmartException(e.detail, message='Cannot query ' + url)


async def upsert(params: Dict, tenant: Optional[str] = None) -> None:
    tenant = await fa.verify_tenant(tenant)
    params = Dict(params)
    url = URL + '/' + params.id
    role_url = url + '/role'

    # Check if app exists by ID
    exists = False
    try:
        existing = await find(params.id)
        exists = True
    except SmartException as e:
        pass

    try:
        if exists:
            # Update existing App
            # Updating application.roles does not work.  It works for initial POST,
            # but not for updates.  Instead we need to handle it manually
            roles = None
            if params.roles:
                roles = params.roles
                del params.roles;

            # Patch the app
            await fa.patch(url, tenant, json={'application': params})

            # Add roles that do not already exist
            for role in roles:
                role_exists = False
                for existing_role in existing.roles:
                    if role.lower() == existing_role.name.lower():
                        role_exists = True
                        break
                if not role_exists:
                    await fa.post(role_url + '/' + role.id, tenant, json={'role': role})

            # Remove roles that should no longer exist
            for existing_role in existing.roles:
                role_exists = False
                for role in roles:
                    if role.lower() == existing_role.name.lower():
                        role_exists = True
                        break
                if not role_exists:
                    await fa.delete(role_url + '/' + existing_role.id, tenant)

        else:
            # Insert new App
            await fa.post(url, tenant, json={'application': params})
    except SmartException as e:
        raise SmartException(e.detail, message='Cannot query ' + url)
```


Usage of this `app` level endpoint abstraction

```python
from mreschke.fusionauth.repository import app

apps = await app.find('my-app', tenant='my-tenant')
```
