# README

## Redis

We require a Redis server to handle our asynchronous email queue. In
development, you can run one using Docker and the `bin/start-docker-redis` and
`bin/stop-docker-redis` scripts. This will run a Redis server on `localhost:6379`
which also happens to be the default we try to connect to.

In staging and production, Dokku should provide Flight Center with a suitable
Redis server by setting the `REDIS_URL` environment variable. We can use the
`dokku-redis` plugin to make this happen more magically:

```
$ dokku redis:create redis-flight-center
$ dokku redis:link redis-flight-center flight-center
```

And make sure that there's at least one worker process running:
```
dokku ps:scale flight-center resque=1
```

In all environments, the Resque dashboard is mounted at `/resque` for logged-in
admin users, and can be used to verify that queues are being processed and
workers running.
