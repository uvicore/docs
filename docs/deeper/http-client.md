---
title: HTTP Client
---

# HTTP Client

Uvicore ships with a fast, fully async **HTTP client** so you can talk to other APIs from your commands, controllers, jobs and services.  As of **0.4** that client is [httpx](https://www.python-httpx.org/) — a modern, feature rich client with a `requests`‑style API, HTTP/1.1 **and** HTTP/2 support, connection pooling, streaming, and first‑class `async`/`await`.

!!! danger "Breaking change in 0.4"
    Uvicore **0.3 and earlier shipped `aiohttp`** as the bundled client.  0.4 replaces it with `httpx`.  The IoC binding, the request methods, and the response object all changed.  If you call `uvicore.ioc.make('aiohttp')` anywhere, see the [aiohttp → httpx migration](#migrating-from-aiohttp) section below and the [Upgrade 0.3 to 0.4](../epologue/upgrade/from-0.3-to-0.4.md#http-client-changed-from-aiohttp-to-httpx) guide.

!!! note "See The Code on Github"
    - [HTTP Client Provider](https://github.com/uvicore/framework/blob/master/uvicore/http_client/package/provider.py)
    - [httpx documentation](https://www.python-httpx.org/)

---

## Dependencies

The HTTP client is available to all levels of Uvicore, regardless of the options you chose when running the [Uvicore Installer](../getting-started/installation.md).

You will notice in your `config/dependencies.py` file that the HTTP client is enabled by default:

```python
dependencies = OrderedDict({
    # ...
    # HTTP async client based on httpx.
    'uvicore.http_client': {
        'provider': 'uvicore.http_client.package.provider.HttpClient',
    },
    # ...
})
```

The provider binds a single shared `httpx.AsyncClient` into the [IoC](ioc.md) on application startup (console, HTTP server **and** pytest) and closes it cleanly on shutdown.

---

## The Shared Client

Resolve the shared client from the IoC with any of these three names — they all return the **same singleton** `httpx.AsyncClient`:

```python
import uvicore

http = uvicore.ioc.make('http_client')   # canonical
http = uvicore.ioc.make('httpx')         # alias
http = uvicore.ioc.make('uvicore.http_client')  # full binding name
```

Because it is a **singleton**, the underlying connection pool is reused across every request in your app — keep‑alive connections are recycled, which is exactly what you want for a long‑running server or CLI.

!!! tip
    The shared client is created with httpx's defaults (no `base_url`, a 5 second default timeout, redirects **off**).  When you need per‑client defaults — a `base_url`, default headers, a bearer token, HTTP/2, custom timeouts or connection limits — create [your own client](#your-own-client-instances) instead of (or alongside) the shared one.

---

## Basic Usage

The single biggest difference from `aiohttp`: in httpx the request is **awaited directly** and returns a fully‑read `Response`.  There is no `async with` around the request (unless you are [streaming](#streaming-large-responses)), and the response accessors (`.text`, `.json()`) are **not** awaited.

```python
import uvicore
from uvicore.support.dumper import dump, dd

async def some_async_method():
    http = uvicore.ioc.make('httpx')
    url = 'https://petstore3.swagger.io/api/v3/pet/findByStatus?status=available'

    r = await http.get(url)
    if r.status_code == 200:
        dump(r)             # the httpx.Response object
        dump(r.text)        # body as str  (NOT awaited)
        dump(r.json())      # body parsed as JSON  (NOT awaited)
```

---

## Making Requests

Every HTTP verb has a matching coroutine on the client.  Each returns an `httpx.Response`.

```python
r = await http.get(url)
r = await http.post(url, json={'name': 'Bob'})
r = await http.put(url, json={'name': 'Bob'})
r = await http.patch(url, json={'active': True})
r = await http.delete(url)
r = await http.head(url)
r = await http.options(url)

# The generic form (handy when the verb is dynamic)
r = await http.request('GET', url)
```

### Query Parameters

Pass a dict (or list of tuples for repeated keys) as `params=` instead of hand‑building the query string:

```python
r = await http.get('https://api.example.com/pets', params={
    'status': 'available',
    'limit': 25,
})
# -> https://api.example.com/pets?status=available&limit=25

# Repeated keys
r = await http.get(url, params=[('tag', 'cat'), ('tag', 'dog')])
# -> ?tag=cat&tag=dog
```

### Sending a Body

httpx picks the encoding based on which keyword you use:

```python
# JSON body (sets Content-Type: application/json)
r = await http.post(url, json={'name': 'Bob', 'roles': ['admin']})

# Form urlencoded body (application/x-www-form-urlencoded)
r = await http.post(url, data={'username': 'bob', 'password': 'secret'})

# Repeated form fields — pass a list value
r = await http.post(url, data={'to': ['a@x.com', 'b@x.com']})

# Raw bytes / string body
r = await http.post(url, content=b'raw bytes here')
r = await http.post(url, content='<xml>...</xml>', headers={'Content-Type': 'application/xml'})
```

### Multipart File Uploads

Use `files=` for multipart uploads.  You can combine `data=` (regular fields) and `files=` (attachments) in the same request, and repeat a field name by passing a list of tuples:

```python
# Single file
files = {'attachment': ('report.pdf', open('report.pdf', 'rb'), 'application/pdf')}
r = await http.post(url, data={'subject': 'Q3'}, files=files)

# Multiple files under the same field name
files = [
    ('attachment', ('a.pdf', a_bytes)),
    ('attachment', ('b.pdf', b_bytes)),
]
r = await http.post(url, files=files)
```

!!! tip "Async file reads"
    httpx itself reads file objects synchronously.  In an async app, read the bytes first with `aiofiles` so you never block the event loop, then hand httpx the bytes — this is exactly how Uvicore's own [Mailgun mail backend](mail.md) builds its attachments:

    ```python
    import aiofiles
    async with aiofiles.open(path, 'rb') as f:
        content = await f.read()
    files = [('attachment', (filename, content))]
    ```

### Headers

```python
r = await http.get(url, headers={
    'Authorization': 'Bearer ' + token,
    'Accept': 'application/json',
})
```

---

## Authentication

httpx has built‑in auth helpers, so you rarely build the header yourself.

```python
import httpx

# HTTP Basic — a plain (user, pass) tuple is the shortcut
r = await http.get(url, auth=('api', secret))

# ...or the explicit helper (identical result)
r = await http.get(url, auth=httpx.BasicAuth('api', secret))

# HTTP Digest
r = await http.get(url, auth=httpx.DigestAuth('user', 'pass'))

# Bearer / token auth — just a header
r = await http.get(url, headers={'Authorization': 'Bearer ' + token})
```

Need a reusable scheme (e.g. attach a token to *every* request and refresh it on a 401)?  Subclass `httpx.Auth` and pass it once when constructing [your own client](#your-own-client-instances):

```python
import httpx

class BearerAuth(httpx.Auth):
    def __init__(self, token: str):
        self.token = token

    def auth_flow(self, request):
        request.headers['Authorization'] = f'Bearer {self.token}'
        yield request

client = httpx.AsyncClient(auth=BearerAuth(my_token))
```

---

## The Response Object

`httpx.Response` exposes everything as **properties or plain methods** — none of them are awaited (the body was already read when you awaited the request).

```python
r = await http.get(url)

r.status_code      # int, e.g. 200
r.is_success       # bool — True for 2xx
r.is_error         # bool — True for 4xx/5xx
r.reason_phrase    # 'OK', 'Not Found', ...

r.text             # body decoded to str
r.content          # body as raw bytes
r.json()           # body parsed as JSON (raises if not valid JSON)

r.headers          # case-insensitive dict-like
r.headers['content-type']
r.cookies          # response cookies
r.url              # the final URL (after any redirects)
r.elapsed          # timedelta of the round trip
r.encoding         # detected/!set text encoding
```

### Raising on Error Status

Instead of checking `status_code` by hand, let httpx raise for any 4xx/5xx:

```python
r = await http.get(url)
r.raise_for_status()      # raises httpx.HTTPStatusError on 4xx/5xx
data = r.json()
```

---

## Error Handling

All httpx errors derive from `httpx.HTTPError`.  The two branches you care about:

| Exception | When it happens |
|---|---|
| `httpx.HTTPStatusError` | You called `raise_for_status()` and got a 4xx/5xx |
| `httpx.RequestError` | The request never completed — network/transport failure |
| `httpx.ConnectError` | (subclass of `RequestError`) couldn't connect |
| `httpx.TimeoutException` | (subclass of `RequestError`) the request timed out |

```python
import httpx

try:
    r = await http.get(url, timeout=10.0)
    r.raise_for_status()
    return r.json()
except httpx.TimeoutException:
    # connect/read/write/pool timeout
    ...
except httpx.HTTPStatusError as e:
    # we got a response, but it was a 4xx/5xx
    status = e.response.status_code
    detail = e.response.text
    ...
except httpx.RequestError as e:
    # DNS failure, connection refused, TLS error, etc. — no response
    ...
```

---

## Timeouts

The shared client uses httpx's default 5 second timeout on **every** phase.  Override per request, or set a policy on your own client:

```python
import httpx

# Simple: one number applies to connect, read, write and pool
r = await http.get(url, timeout=30.0)

# Disable entirely (use with care)
r = await http.get(url, timeout=None)

# Fine-grained policy
timeout = httpx.Timeout(10.0, connect=5.0, read=30.0)
client = httpx.AsyncClient(timeout=timeout)
```

---

## Streaming Large Responses

For large downloads (or server‑sent events) you don't want the whole body in memory.  This is the **one** place you still use `async with`, because the response body is consumed incrementally:

```python
async with http.stream('GET', 'https://example.com/big.csv') as r:
    r.raise_for_status()
    async for chunk in r.aiter_bytes():
        ...                       # process each chunk
    # or: async for line in r.aiter_lines():
    # or: async for raw in r.aiter_raw():
```

---

## Your Own Client Instances

The shared singleton is perfect for ad‑hoc calls, but when you are talking to **one** API repeatedly you'll usually want a dedicated client with its own defaults.  Construct an `httpx.AsyncClient` and use it as an async context manager so its pool is cleaned up:

```python
import httpx

async with httpx.AsyncClient(
    base_url='https://api.example.com/v3',
    headers={'Accept': 'application/json'},
    auth=('api', secret),
    timeout=httpx.Timeout(15.0),
    follow_redirects=True,
    http2=True,                                   # requires the h2 package
    limits=httpx.Limits(max_connections=100, max_keepalive_connections=20),
) as client:
    # Paths are joined onto base_url
    r = await client.get('/pets', params={'status': 'available'})
    r.raise_for_status()
    pets = r.json()
```

A common pattern is to wrap a long‑lived client in your own [singleton service](ioc.md) (see the [SugarCRM](#example-simple-sugarcrm-client) and [FusionAuth](#example-fusionauth-client) examples below), so the base URL, auth and pool are configured once.

!!! note "Redirects are off by default"
    Unlike `requests`, httpx does **not** follow redirects unless you ask.  Pass `follow_redirects=True` on the call or on your client when you need it.

---

## Migrating From aiohttp

In 0.3 and earlier, Uvicore bound `aiohttp.ClientSession` under the name `aiohttp`.  In 0.4 it binds `httpx.AsyncClient` under `http_client` / `httpx`.  The mechanical changes:

| aiohttp (0.3) | httpx (0.4) |
|---|---|
| `uvicore.ioc.make('aiohttp')` | `uvicore.ioc.make('httpx')` *(or `'http_client'`)* |
| `async with http.get(url) as r:` | `r = await http.get(url)` |
| `async with http.post(url, json=p) as r:` | `r = await http.post(url, json=p)` |
| `r.status` | `r.status_code` |
| `await r.text()` | `r.text` |
| `await r.json()` | `r.json()` |
| `await r.read()` | `r.content` |
| `aiohttp.BasicAuth(user, pw)` | `(user, pw)` *or* `httpx.BasicAuth(user, pw)` |
| `aiohttp.FormData()` + `.add_field(...)` | `data={...}` (form) and/or `files=[...]` (uploads) |
| repeated field via multiple `add_field('to', x)` | `data={'to': ['a', 'b']}` (list value) |
| `await session.close()` | `await client.aclose()` |
| manual status checks | `r.raise_for_status()` |

The two gotchas that bite everyone:

1. **No `async with` on the request.** httpx awaits the request and gives you a fully‑read response. `async with` is only for [streaming](#streaming-large-responses).
2. **Response accessors aren't awaited.** `r.text` and `r.json()` are a property and a sync method — `await`ing them is an error.

**Before (aiohttp / 0.3):**

```python
http = uvicore.ioc.make('aiohttp')
async with http.get(url, auth=aiohttp.BasicAuth(user, pw)) as r:
    if r.status == 200:
        data = await r.json()
```

**After (httpx / 0.4):**

```python
http = uvicore.ioc.make('httpx')
r = await http.get(url, auth=(user, pw))
if r.status_code == 200:
    data = r.json()
```

---

## Example Basic Auth GET Helper

```python
import json
import uvicore

async def http_get(url: str, *, as_json: bool = True, basic_auth: str = None) -> tuple:
    """HTTP GET call using httpx"""

    # Async HTTP Client (httpx)
    http = uvicore.ioc.make('httpx')

    # Optional Basic Auth — httpx accepts a plain (user, password) tuple
    auth = None
    if basic_auth:
        (user, password) = basic_auth.split(':')
        auth = (user, password)

    # Make the call (no `async with` — httpx awaits the request directly)
    r = await http.get(url, auth=auth)
    code = r.status_code

    if as_json:
        # .json() will raise if the content type/body is not valid JSON.
        # Some APIs return JSON strings but with content type text/plain,
        # so on failure fall back to json.loads on the raw text.
        try:
            results = r.json()
        except Exception:
            results = json.loads(r.text)
    else:
        results = r.text

    return (code, results)
```

---

## Example Simple SugarCRM Client

A basic example of building your own SugarCRM client class to login and interact with the Sugar API.  This shows the `GET` method only, but you "get" the point :)  It caches the login token in a temp file and re‑logs in once if the token has expired.

```python
import os
import uvicore
from uvicore.support import hash
from uvicore.typing import Dict, List

@uvicore.service('acme.wiki.sugar.client.SugarClient', aliases=['sugar-client'], singleton=True)
class SugarClient:
    """Generic Async httpx REST client for Sugar"""

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
        return uvicore.ioc.make('httpx')

    async def login(self, refresh=False):
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

        # Cache login token in a tmp file by payload hash
        token_file = '/tmp/sugar.token.' + hash.md5(payload)

        # If force re-login, remove token_file
        if refresh and os.path.exists(token_file):
            os.remove(token_file)

        # If token_file exists, use that token instead of hitting Sugar again
        if os.path.exists(token_file):
            with open(token_file, 'r') as f:
                return str(f.readline())

        # Login to sugar via /oauth2/token
        r = await self.http.post(f"{url}/oauth2/token", json=payload)
        r.raise_for_status()
        token = r.json()['access_token']

        # Cache token in token_file
        with open(token_file, 'w') as f:
            f.write(token)

        return token

    async def get_enum(self, module, field):
        """HTTP GET a module's field enum values"""
        return await self._http_get(f"{self.config.url}/{module}/enum/{field}")

    async def get(self, module, *, fields: List = None, filter: Dict = None, max_num: int = 25) -> dict:
        """HTTP GET a module with parameters from Sugar API"""
        payload = {}
        if fields: payload['fields'] = fields
        if filter: payload['filter'] = filter
        if max_num: payload['max_num'] = max_num
        return await self._http_get(f"{self.config.url}/{module}", payload)

    async def _http_get(self, url, payload=None):
        # Get sugar oauth2 token
        token = await self.login()
        headers = {'oauth-token': token}

        # HTTP GET Sugar API, retry login on 400/401 failure
        r = await self.http.get(url, params=payload, headers=headers)
        if r.status_code == 200:
            return r.json()

        if r.status_code in (400, 401):
            # Relogin and try again, token may have expired
            token = await self.login(refresh=True)
            headers = {'oauth-token': token}
            r2 = await self.http.get(url, params=payload, headers=headers)
            if r2.status_code == 200:
                return r2.json()
            raise Exception(r2.text + ' - Status ' + str(r2.status_code))

        raise Exception(r.text + ' - Status ' + str(r.status_code))
```

To use this `SugarClient`:

```python
import uvicore
from acme.wiki.sugar.client import SugarClient
# or SugarClient = uvicore.ioc.make('sugar-client')

accounts = (await SugarClient.get(
    module='Accounts',
    max_num=999,
    fields=['id', 'name'],
))['records']
```

---

## Example FusionAuth Client

A fuller real‑world client showing all the verbs (`get`/`post`/`put`/`patch`/`delete`), config‑driven multi‑tenant keys, and Uvicore [exception](../http/exceptions/concepts.md) integration.

```python
import uvicore
from uvicore.support.dumper import dump, dd
from uvicore.typing import Dict
from uvicore.exceptions import SmartException


@uvicore.service('mreschke.fusionauth.client.Client',
    aliases=['fusionauth'],
    singleton=True,
)
class Client:
    """Generic Async httpx REST client for FusionAuth"""

    @property
    def config(self):
        return uvicore.config.mreschke.fusionauth

    @property
    def http(self):
        return uvicore.ioc.make('httpx')

    @property
    def allowed_tenants(self):
        return [k for (k, v) in self.config.tenant_keys.items() if v]

    async def verify_tenant(self, tenant: str = None):
        if tenant is None: tenant = self.config.default_tenant or 'default'
        if tenant.lower() not in self.allowed_tenants:
            await self.not_found('Invalid tenant.  Must be one of {}'.format(str(self.allowed_tenants)))
        return tenant.lower()

    async def api_key(self, tenant: str, master_key: bool = False) -> str:
        key = self.config.master_key if master_key else self.config.tenant_keys[tenant]
        if key: return key
        await self.not_found('API key not found in config for tenant {}'.format(tenant))

    async def url(self, path: str) -> str:
        auth_url = self.config.url
        if auth_url and auth_url[-1] == '/': auth_url = auth_url[0:-1]  # Strip trailing /
        if path[0] == '/': path = path[1:]                              # Strip leading /
        if auth_url: return auth_url + '/' + path
        await self.not_found('FusionAuth URL not found in config')

    async def get(self, path: str, tenant: str = None, master_key: bool = False):
        key = await self.api_key(tenant, master_key)
        url = await self.url(path)
        r = await self.http.get(url, headers={'Authorization': key})
        return await self._handle(r)

    async def post(self, path: str, tenant: str = None, master_key: bool = False, json: Dict = None):
        key = await self.api_key(tenant, master_key)
        url = await self.url(path)
        r = await self.http.post(url, json=json, headers={'Authorization': key})
        return await self._handle(r)

    async def put(self, path: str, tenant: str = None, master_key: bool = False, json: Dict = None):
        key = await self.api_key(tenant, master_key)
        url = await self.url(path)
        r = await self.http.put(url, json=json, headers={'Authorization': key})
        return await self._handle(r)

    async def patch(self, path: str, tenant: str = None, master_key: bool = False, json: Dict = None):
        key = await self.api_key(tenant, master_key)
        url = await self.url(path)
        r = await self.http.patch(url, json=json, headers={'Authorization': key})
        return await self._handle(r)

    async def delete(self, path: str, tenant: str = None, master_key: bool = False):
        key = await self.api_key(tenant, master_key)
        url = await self.url(path)
        r = await self.http.delete(url, headers={'Authorization': key})
        return await self._handle(r, text=True)

    async def _handle(self, r, text: bool = False):
        """Shared response handling for every verb"""
        if r.status_code == 200:
            return r.text if text else r.json()

        # Prefer a JSON error body, fall back to plain text
        try:
            detail = r.json()
        except Exception:
            detail = r.text
        await self.exception(detail or str(r.status_code) or 'Unknown error', status_code=r.status_code)

    async def not_found(self, message: str):
        if uvicore.app.is_http:
            from uvicore.http.exceptions import NotFound
            raise NotFound(message)
        raise Exception(message)

    async def exception(self, message: str, *, status_code=503):
        raise SmartException(message, status_code)
```

An example `repository/app.py` that adds a higher level "app" endpoint abstraction:

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

    # FusionAuth has no get-by-name endpoint, so for names we list and filter
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
    try:
        async def query():
            response = await fa.get(url, tenant)
            if not response: response['applications'] = []
            return [Dict(x) for x in response.get('applications')]
        return await uvicore.cache.remember(tenant + '/' + url, query)
    except SmartException as e:
        raise SmartException(e.detail, message='Cannot query ' + url)
```

Usage of this `app` level endpoint abstraction:

```python
from mreschke.fusionauth.repository import app

apps = await app.find('my-app', tenant='my-tenant')
```

---

!!! tip "HTTP Client tips"
    - Resolve the shared client with `uvicore.ioc.make('httpx')` (aliases: `http_client`, `httpx`).
    - **Await the request, don't `async with` it** — that's only for `http.stream(...)`.
    - Response accessors are **not** awaited: use `r.status_code`, `r.text`, `r.json()`.
    - Let httpx do the work: `(user, pass)` tuples for basic auth, `params=` for query strings, `json=`/`data=`/`files=` for bodies, and `r.raise_for_status()` for error checking.
    - Need a `base_url`, default headers, HTTP/2 or custom timeouts/limits?  Build your own `httpx.AsyncClient` (often wrapped in a singleton service) instead of the shared one.
    - Upgrading from 0.3?  See [Migrating From aiohttp](#migrating-from-aiohttp).
