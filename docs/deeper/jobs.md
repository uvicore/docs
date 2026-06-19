---
title: Jobs
---

# Jobs

A Job encapsulates a single unit of work, training a model, generating a report, processing an upload, into one tidy, reusable class.  Jobs keep your routes and commands thin by giving heavy or reusable logic a proper home, and they can be dispatched **synchronously or asynchronously** from anywhere in your app.

If you have used Laravel's Jobs, the idea is the same, though Uvicore jobs run inline (sync or `await`ed) rather than on a queue worker.

---

## Defining a Job

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


## Dispatch the Job

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
