# Handling Events

Handlers are callbacks that are dispatched when an event fires.  Handlers are
defined using `.listen(), .listener(), .handle(), .handler() .call() or .subscribe()` methods as noted in
[Listening To Events](#listening-to-events).

Handlers can be basic python methods (functions) or dedicated handler classes.

All handlers receive an `event: Dict` and `payload: Any`.  The `event`
dictionary is the metadata for an event that was defined by the developer
during the event registration.  If the event listener is a class, the payload
will be an instance of that class with properties of all constructor parameters.
If the event listener is just a string, the payload is a `namedtuple` of
parameters.


### :material-pound: Callable Handlers

Basically anything in python that is callable.

```python
# Handler Example
def my_handler(event: Dict, payload: Any) -> None:
    # Do work when this event is dispatched.

# Listener Example which calls the handler
from acme.wiki.events.post import Created as OnPostCreated
OnPostCreated.listen(my_handler)
```

You can evn use a Class with a magic `__call__` method on it..that class is technically now "callable"!

```python
# Handler Example
from uvicore.events import Handler
from acme.wiki.events.post import Created as OnPostCreated
class MyHandler(handler):
    def __call__(self, event: OnPostCreated)
    # Do work when this event is dispatched.

# Listener Example which calls the handler
OnPostCreated.listen(MyHandler)
```


### :material-pound: Class Handlers

A good practice is to make yourself a `handlers` folder with handler classes.  The `handle()` method will be called when the even is fired.


```python
from typing import Dict, Any
from uvicore.events.handler import Handler

class NotifyUser(Handler):

    def handle(self, event: Dict, payload: Any):
        # Instance variable self.app is also available to you
        # Do work when this event is dispatched.
```


### :material-pound: Subscription Handler

Subscriptions are a great way to listen and handle multiple events from a single
file.

```python
from typing import Dict, Any
from uvicore.contracts import Dispatcher

class AppEventSubscription:

    def app_registered(self, event: Dict, payload: Any):
        #  Do something when then the framework is done registering all providers

    def app_booted(self, event: Dict, payload: Any):
        #  Do something when then the framework is done booting all providers

    def post_created(self, event: Dict, payload: Any):
        #  Do something when a wiki post is created

    def subscribe(self, events: Dispatcher):
        # A subscription is an all in one class that can both listen AND handle
        # one or more events in a single place.
        events.listen('uvicore.foundation.events.app.Registered', self.app_registered)
        events.listen('uvicore.foundation.events.app.Booted', self.app_booted)
        events.listen('acme.wiki.post.Created', self.post_created)
```
