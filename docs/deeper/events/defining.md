# Defining Your Own Events


You may define events in two ways.

1. With a Class that holds a strictly defined payload (via the constructor)
2. As a simple string with a loosely defined dictionary payload.


## :material-pound: Class Based Events

Class based events not only provide a stricter interface, but they also bind themselves to the [IoC](/deeper/ioc/) allowing you to view all Class based events using the `./uvicore event list` CLI as long as that file has been `imported` in your packages provider.

The benifits of an event class are that you can force the payload requirements
using the class `__init__()` constructor.  An event class performs NO work.  It
is simply a data container for the payload itself.  Event classes are typically
stored in the `events` directory of your package.

```python
# events/post.py
import uvicore
from uvicore.events import Event
from acme.wiki.models import Post

@uvicore.event()
class Created(Event):

    # Events are either synchronous or asynchronous
    is_async = True

    def __init__(self, post: Post):
        self.post = post
```


## :material-pound: String Based Events


String based events are not known ahead of time, so they are harder to discover.  Read the package developers documentation to learn about the events they may fire.

The event strings can be whatever you like, however it is best practice to name the string as if it were going to be an actual event class someday.  For example `acme.wiki.events.post.Created`. If at some point you want to create the actual class, all existing listeners that use that string will not need to be changed as the system looks for a class of the same name to instantiate.

Examples of string based events can be found in the ORM Model

!!! note "See The Code on Github"
    - [model.py](https://github.com/uvicore/framework/blob/master/uvicore/orm/model.py)
    - Search for 'def _before_insert' to see examples of:
        - `event_name = 'uvicore.orm-{' +  self.__class__.modelfqn + '}-BeforeInsert'`
        - `await uvicore.events.codispatch(event_name, {'model': self})`


