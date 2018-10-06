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
