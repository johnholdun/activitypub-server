# ActivityPub Server

A proof-of-concept for an ActivityPub server that can create and persist Actors, create and deliver Statuses for those Actors, and also create Likes (AKA Favorites) and Announcements (AKA Reblogs AKA Boosts AKA Retweets) for other Statuses elsewhere on the internet (AKA The Fediverse).

## Starting the server

If you're starting from scratch, install all the dependencies first:

```
gem install bundler
bundle install
```

Then you're ready for this:

```
bundle exec unicorn
```

The server will start running on port 8080, and you're ready to expose it to the web with something like nginx. Describing that process is outside of the scope of this readme, but [this guide](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-rails-app-with-unicorn-and-nginx-on-ubuntu-14-04#install-and-configure-nginx) should get you going in the right direction.

## Creating an Account

There’s a command line script for this:

```
rake accounts:create -- --username john --display-name "John Holdun" --summary "Greetings from me!" --icon-url "https://johnholdun.com/images/bookworm-full.png"
```

Fill in your own options to create a new account on your server. The icon needs to already exist at the URL you specify; this server does not handle media uploads.

There are similar tasks for other actions you can perform on behalf of accounts on your server:

```
favorites:create
favorites:delete
follows:create
follows:delete
reblogs:create
reblogs:delete
statuses:create
statuses:delete
```

Run any of these with the `--help` flag to see the options it accepts:

```
rake favorites:create -- --help
```

## To Do

### Static content

An ActivityPub server is generally more read-heavy than write-heavy. To make this app as performant as possible, I want most GET requests to return static data (i.e. pre-generated JSON files). The biggest piece of work here involves creating slices of feeds that are suitable for pagination.

### Authentication

The API endpoints are all hard-coded for a local user named `john`. Authentication is out of scope for this project, but maybe adopting [IndieLogin](https://indielogin.com/) makes sense.

### Receive incoming items and add to queue

This already works, but the naïve `data.json` approach is not scalable. The inbox URL should quickly and generously accept all incoming items to an append-only queue, which is then parsed asynchronously by a separate process.

### Miscellaneous

- Add "received at" metadata to incoming items

## Acknowledgements

This codebase started as a fork of [Mastodon](https://github.com/tootsuite/mastodon/), which I stripped away line by line to learn how the ActivityPub spec works in practice. Thanks to Eugen and everyone else that has worked on that project!
