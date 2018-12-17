# ActivityPub Server

An [ActivityPub](https://activitypub.rocks) server that can present Actors, create Objects, and deliver Activities.

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

The server will start running on port 8080, and you're ready to expose it to the web with something like nginx.

## Sample nginx configuration

Let's assume you have an existing site that's already happily being served with nginx. This app is designed to only handle incoming requests with the activitystreams Accept header, so it can live right alongside your site and even share some URLs if necessary.

First, set up a `proxy_pass` at a path that's unlikely to be shared by any other pages on your site that points to wherever this app is running (port 8080 is the Unicorn default):

    location /activitypub/ {
      proxy_pass http://localhost:8080/;
    }

Then, in **inside your existing `location /` directive**, add some conditional rewrites before everything else:

    location / {
      if ($http_accept ~ application\/ld\+json) {
        rewrite ^/(.+) /activitypub/$1 last;
      }

      if ($http_content_type ~ activity\+json) {
        rewrite ^/(.+) /activitypub/$1 last;
      }

      # the rest of your existing `location /` directive would be here
    }

You probably want to redirect requests whose path start with `.well-known/` to this app as well, although you may have other software serving data at paths like that. (If you do, you probably already know how to patch this into your existing processes.)

   location /.well-known/ {
      rewrite ^/(.+) /activitypub/$1 last;
    }

Now reload your config and see if it worked! Happy content negotiating!

For more on nginx, [this guide](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-rails-app-with-unicorn-and-nginx-on-ubuntu-14-04#install-and-configure-nginx) should get you going in the right direction.

## Creating an Account

There’s a command line script for this:

```
rake accounts:create -- --username john --display-name "John Holdun" --summary "Greetings from me" --icon-url "https://johnholdun.com/images/bookworm-full.png"
```

Fill in your own options to create a new account on your server. The icon needs to already exist at the URL you specify; this server does not handle media uploads. You can also add the `--help` flag to see the options this command accepts:

```
rake accounts:create -- --help
```

## Adding to the Outbox

Following the standard ActivityPub flow, you can `Create` `Note`s, `Follow` `Person`s, and more:

```
curl -i -X POST -H "Authorization: Bearer exampletoken" -H "Content-Type: application/json" -d '{"type":"Like","object":"https://mastodon.social/users/johnholdun/statuses/1508775"}' https://johnholdun.localtunnel.me/users/john/outbox
```

If the request works, you'll receive a 201 with a Location header that directs you to your created Activity. In order to deliver this Activity to the relevant parties, you'll need to run the outbox queue.

### Addressing your audience

The outbox makes no assumptions about who you want to notify about your creations. If you don't specify `to` or `cc` fields, it won't be sent to anyone! Here are some recommendations for who to send to, by type of object:

- Like: to author of liked object
- Follow: to target
- Note: to public, cc followers and anyone tagged and author of reply, if applicable
- Announce: to public, cc followers and author of object being announced

An Undo should generally be sent to the same audience as the activity it's undoing.

## The Queue

The inbox flow for this project is designed to be minimally process-intensive. Any request to an inbox URL will be accepted and written to the `unverified_inbox` table without being parsed. A second process will parse these items one at a time, in the order they were received, saving activities and accepting follows as appropriate. You can run the parser like so:

```
ruby -e "require './environment'; ParseInbox.call"
```

This command will parse all new activities and exit. If there is a problem parsing an activity, its `errors` column will be populated with helpful information; this item will be ignored on subsequent runs and manual intervention will be required. There's no built-in mechanism for running this parser continuously yet, but a frequent cron job might do the trick.

There's another process for delivering activities that are added to your local outbox. You can have this clear out a batch of outbox items in a similar way to the inbox queue:

```
ruby -e "require './environment'; ParseOutbox.call"
```

## To Do

### Static content

The POST /inbox requests _may_ be the most heavily-used routes (which is why they are designed the way they are, to reduce processing time), but GETs require little to no logic. To make this app as performant as possible, I want most GET requests to return static data (i.e. pre-generated JSON files). The biggest piece of work here involves creating slices of feeds that are suitable for pagination.

### Authentication

Any outbox POST is just checked against a static string right now. I think adopting [IndieLogin](https://indielogin.com/) makes sense here.

## Acknowledgements

This codebase started as a fork of [Mastodon](https://github.com/tootsuite/mastodon/), which I stripped away line by line to learn how the ActivityPub spec works in practice. It's changed and expanded a lot since then, but I wanted to thank Gargron and everyone else that has worked on that project for pointing me in the right direction!
