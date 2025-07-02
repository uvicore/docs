# Dispatching Events

You can fire off (dispatch) an event in a few different ways.  Where
you fire off the event is up to your own code.  With the Wiki events
example above the proper place may be in your controller, model or job that
Creates and Deletes wiki posts.  Wherever the location, firing off an event
is simple.

!!! note
    Events are defined as either synchronous or asynchronous.
    Uvicore provides the synchronous `diaptch()` method and the asynchronous `codispatch()` method.


### :material-pound: Dispatch Class Based Events

Dispatch using `events.dispatch()` or `events.codispatch()`

```python
from uvicore import events
from acme.wiki.events import Created

# Using the events.dispatch() method to pass in the class instance
events.dispatch(Created(post))
await events.codispatch(Created(post))
```

Dispatch using the instantiated class `.dispatch()` or `.codispatch()` methods

```python
# Or by using the event classes build-in .dispatch() method
Created(post).dispatch()
await Created(post).codispatch()
```

Dispatch using string dot notation.  Since we defined the Class in the same path, Uvicore will detect the class and Instantiate it with the Dictionary payload as **kwargs into the constructor!
```python
# Or by using the event classes build-in .dispatch() method
events.dispatch('acme.wiki.events.post.Created', {'post': post})
await events.codispatch('acme.wiki.events.post.Created', {'post': post})
```


### :material-pound: Dispatch String Based Events

String based events work with or without a matching event class.

You can simply have an event named `xyz` and dispatch it with `events.dispatch('xyz', {'payload1': 'test'})`

If however you name your class like so `acme.wiki.events.post.Created` AND there happens to be an event Class with the same python module path, that event class will be used. It will be Instantiated, and the dictionary will be passed to the constructor as **kwargs.


```python
from uvicore import events
events.dispatch('acme.wiki.events.post.Created', {'post': post})
await events.codispatch('acme.wiki.events.post.Created', {'post': post})
```



