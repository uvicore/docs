# Event System

---

Notes on 0.2.7
Fixed event system
need to update docs
no more event,payload, just event:Dict or event:Class
talk about listen decorator
async __call__ does work
talk about priority, default 50 etc...
---





Uvicore provides an observer (pub/sub) implementation allowing you to listen
(subscribe) to events that occur in the framework and in your own packages.

Events are a great way to decouple various aspects of your project.  A single
event can have many listeners that need not depend on each other.  For example,
each time a wiki post is created you may wish to send an email or slack
notification to all watchers of the post.

Events allow for the `O` in `S.O.L.I.D` which mean code is Open for extension but closed for modification.  You can extend functionality to existing code (that fires events) without touching the code itself.  Be sure to add event to your code at the beginning to allow other developers to listen to those events and extend their own functionality with their own handlers!

Events are dispatched throughout the framework and many other packages.  When an
event is dispatched all defined listeners will be called in order they were
added.  Listeners define the event(s) to watch and the event handlers (callbacks)
to fire when then event is dispatched.  Handlers can be methods, classes or
even bulk listening/handling `subscriptions`.
