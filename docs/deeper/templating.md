# Templating

Uvicore comes with a templating engine to dynamically render text, emails, PDFs, web views or any other content you can imagine.  Uvicore uses the Jinja templating engine under the hood.

The templating engine is automatically used when building standard [Web Applications](../http/web/routing.md) with HTTP views.  But you can also use it on your own, anywhere in code!  For example a CLI app that converts HTML into PDF using the template system.  Or templated event emails.


## Add the Templating Dependency

Review your `config/dependencies.py` file and ensure this provider is included.

```python

dependencies = OrderedDict({
    # ...

    # Templating engine
    'uvicore.templating': {
        'provider': 'uvicore.templating.package.provider.Templating',
    },

    # ...

})
```



## Registering Paths

When using the Templating engine outside of the regular Web Views, you must add the 'Templating' mixin to your [Package Provider](provider.md) which gives your provider access to the `self.register_templating_paths()` method where you define the paths to your `.j2` Jinja templates.


In your provider include the `from uvicore.templating.package.registers import Templating` mixin

```python

import uvicore
from uvicore.package import Provider
from uvicore.support.dumper import dump, dd
from uvicore.console.package.registers import Cli
from uvicore.templating.package.registers import Templating

@uvicore.provider()
class App1(Provider, Cli, Templating):

    def boot(self) -> None:

        # Define alternate non web view paths for the templating engine
        self.register_templating()

    def register_templating(self) -> None:
        """Register the Templating Engine with alternate non web view paths"""

        # Define template paths
        self.register_templating_paths([
            # Paths can be in myapp.module paths
            'bi.assets.email.templates'
            # Or in actual file paths
            '/home/user/Documents/templates',
        ])

        def up_filter(input):
            return input.upper()

        def up_filter2(context, input):
            return input.upper()

        self.register_templating_context_processors({
            'context_filters': {
                'up': up_filter2,
            },
            'filters': {
                'up': up_filter,
            },
        })
```


## Usage

Now that you have registered your custom template paths from your [Package Provider](provider.md) lets render some templates.

```python
from uvicore.templating.engine import Templates
email_body = Templates.render('welcome_email.j2', {
    'topLeft': 'Top Left <b>HERE</b>!!!',
    'topRight': 'Top Right <b>HERE</b>!!!',
    'main': 'report <b>HTML</b> here!'
})
dd(email_body)
# ... send email with merged/templated body!
```
