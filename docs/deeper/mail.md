# Mail


Sending email


As Mail() parameters
```python
from uvicore.mail import Mail

x = Mail(
    #mailer='smtp',
    #mailer_options={'port': 124},
    to=['to@example.com'],
    cc=['cc@example.com'],
    bcc=['bcc@example.com'],
    from_name='Matthew',
    from_address='from@example.com',
    subject='Hello1',
    html='Hello1 <b>Body</b> Here',
    attachments=[
        '/tmp/test.txt',
        '/tmp/test2.txt',
    ]
)
await x.send()
```

As Mail() method chaining
```python
from uvicore.mail import Mail
x = (Mail()
    #.mailer('mailgun')
    #.mailer_options({'port': 124})
    .to(['to@example.com'])
    .cc(['cc@example.com'])
    .bcc(['bcc@example.com'])
    .from_name('Matthew')
    .from_address('from@example.com')
    .subject('Hello1')
    .text('Hello1 <b>Body</b> Here')
    .attachments([
        '/tmp/test.txt',
        '/tmp/test2.txt',
    ])
)
await x.send()
```

!!! tip
    Sending an email inside an HTTP route blocks the response until the mail is sent.  To send it *after* the response is returned, hand the work to a Starlette background task or dispatch a [Job](jobs.md).
