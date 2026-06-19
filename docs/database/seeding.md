# Seeding Data

Database seeders are defined in your package's `database/seeders/*` files.

Seeding allow you to populate your database tables with pre-defined data.  Most applications require at least some data to be inserted before the app can function normally.


## Creating a Seeder

You may use the Uvicore schematic generator to create seeder files automatically, or create it by hand.

!!! note
    Seeders are best used with the [ORM](orm-basics.md), and the examples created with the schematic reflect ORM use cases.  If you are not using the ORM, simply substitute the Model queries below with Uvicore query builder or SQLAlchemy query builder syntax!

```bash
./uvicore gen seeder --help
./uvicore gen seeder posts post
```

!!! warning "init file"
    Be sure to add your new seeder to the `database/seeders/__init__.py`

The schematic includes many commented examples of how to use the seeder.  A form of quick inline documentation!

A basic "wiki" `posts` seeder using the `Post` model looks like this

```python
import uvicore
from acme.wiki.models import Post
from uvicore.support.dumper import dump, dd

@uvicore.seeder()
async def seed():
    uvicore.log.item('Seeding posts')

    await Post.insert([
        {'slug': 'post-1', 'title': 'Post 1'},
        {'slug': 'post-2', 'title': 'Post 2'},
    ])
```


---


## Running the Seeders

!!! danger
    Take caution!  Running the `drop`, `recreate` and `reseed` commands will result in DATA LOSS.  Be careful!

The Uvicore [Uvicore CLI](../cli/index.md) provides the `./uvicore db` commands to help you manage your database seeders.


- Show all connections
```bash
./uvicore db connections
```

- Create all tables (empty, no seeders run)
```
./uvicore db create wiki
```

- Drop all tables (**dangerous!**)
```
./uvicore db drop wiki
```

- Drop and create all in one go (**dangerous!**)
```
./uvicore db recreate wiki
```

- Run your seeders
```
./uvicore db seed wiki
```

- Drop, Create and Seed all in one go (**dangerous!**)
```
./uvicore db reseed wiki
```


---


## Seeder Examples

Below are some quick examples on some tricky to remember seeder hacks.  For brevity we are only showing the inserts you can use inside your `async def seed()` method


### Bulk Insert List[Post]

```python
# Issue here is some model fields are required that we don't have yet, like relations.
# Also cannot add sub relations like one-to-many, many-to-many etc...
await Post.insert([
    Post(slug='post-1', title='Post 1'),
    Post(slug='post-2', title='Post 2'),
])
```


---


### Single insert using Model instance

```python
# Get relation values for link convenience
tags = await Tag.query().key_by('name').get()
post = await Post(slug='post-1', title='Post 1', creator_id=1).save()

# Create AND Link if not exist Many-To-Many tags
await post.link('tags', [
    tags['linux'],
    tags['bsd'],
])
# Create Polymorphic One-To-One
await post.create('image', {
    'filename': 'post2-image.png',
    'size': 2483282
})
# Create Polymorphic One-To-Many
# NOTE: .add is simply an alias for .create()
await post.add('attributes', [
    {'key': 'post2-test1', 'value': 'value for post2-test1'},
    {'key': 'post2-test2', 'value': 'value for post2-test2'},
    {'key': 'badge', 'value': 'IT'},
])
```


---



### Bulk insert List[Dict] with child relations

```python
# Get relation values for link convenience
tags = await Tag.query().key_by('name').get()

# Insert with relations
await Post.insert_with_relations([
    {
        'slug': 'post-1',
        'title': 'Post 1',
        'creator_id': 1,

        # One to many
        'comments': [
            {'title': 'Comment 1', 'body': 'Comment 1 body'},
            {'title': 'Comment 2', 'body': 'Comment 2 body'},
        ],

        # Many-To-Many tags works with existing Model, new Model or new Dict
        'tags': [
           # Existing Tag
           tags['linux'],
           tags['mac'],
           tags['bsd'],
           tags['bsd'],  # Yes its a duplicate, testing that it doesn't fail

           # New Tag as Model (tag created and linked)
           Tag(name='test1', creator_id=4),

           # New Tag as Dict (tag created and linked)
           {'name': 'test2', 'creator_id': 4},
        ],

        # Polymorphic One-To-One
        'image': {
            'filename': 'post1-image.png',
            'size': 1234932,
        },

        # Polymorphic One-To-Many Attributes
        'attributes': [
            {'key': 'post1-test1', 'value': 'value for post1-test1'},
            {'key': 'post1-test2', 'value': 'value for post1-test2'},
            {'key': 'badge', 'value': 'IT'},
        ],
    }
])
```


---


### Bulk Insert Using Faker

```python
from faker import Faker

post_items = []
fake = Faker()
for _ in range(100):
    title = fake.text(max_nb_chars=50)
    post = Post(
        slug=fake.slug(title),
        title=title,
        creator_id=1,
    )
    post_items.append(post)
await Post.insert(post_items)
```
