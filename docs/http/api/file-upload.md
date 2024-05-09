# File Upload

Add these imports to your API controller
```
import aiofiles
from fastapi import UploadFile
```


Route type hinting like so

```python
def register(self, route: ApiRouter):

    @route.post('/train', tags=['MVP'])
    async def train(csv_data: UploadFile):
        """Train Topic 1, Revison 1 for MVP"""

        async with aiofiles.open(f"/tmp/model.sav", "wb") as out_file:
            content = await csv_data.read()
            await out_file.write(content)

        # with open(file, "wb") as binary_file:
        #     # Write bytes to file
        #     binary_file.write(csv_data)

        return {"filename": csv_data.filename}
```
