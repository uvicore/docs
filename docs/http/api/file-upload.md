# API File Uploads

Uvicore API controllers can use FastAPI's file upload types directly.

## Basic Upload Example

```python
import aiofiles
from fastapi import UploadFile


def register(self, route: ApiRouter):

    @route.post('/train', tags=['Training'])
    async def train(csv_data: UploadFile):
        async with aiofiles.open('/tmp/model.sav', 'wb') as out_file:
            content = await csv_data.read()
            await out_file.write(content)

        return {'filename': csv_data.filename}
```

## Why This Works

Uvicore's API layer sits on FastAPI, so endpoint parameter parsing still supports FastAPI request types such as `UploadFile`.

That means file uploads can be handled with the same parameter-driven style you would expect from FastAPI, while still living inside a Uvicore controller and provider-registered API stack.

## Recommendations

- Keep uploads in API controllers under `http/api/`.
- Use async file handling when writing uploaded data to disk.
- Add `tags`, docstrings, and response metadata when the upload endpoint is part of a public API.
- Prefer explicit validation and size checks in real upload endpoints.

