# Jobs

## :material-pound: Defining a Job

Create a `jobs` folder (or whatever name you like) and create a job file, example `jobs/train.py`

```python
import uvicore
from uvicore.jobs.job import Job

@uvicore.job()
class Train(Job):
    """Train the Model"""

    def __init__(self, topic: Topic, revision: Revision, file: str):
        self.topic = topic
        self.revision = revision
        self.file = file

    async def handle(self):
        dump('train job handler here')
```


## :material-pound: Dispatch the Job

You can dispatch sync or async jobs like so

**From jobs.dispatch**
```python
from uvicore import jobs
from acme.wiki.jobs import Train

# Sync
jobs.dispatch(Train(topic=1, revision=5, file='/tmp/x'))

# Or await if your handle() is async
await jobs.codispatch(Train(topic=1, revision=5, file='/tmp/x'))
```

**From the class Instance Itself**
```python
from acme.wiki.jobs import Train

# Sync
Train(topic=1, revision=5, file='/tmp/x').dispatch()

# Or await if your handle() is async
await Train(topic=1, revision=5, file='/tmp/x').codispatch()
```
