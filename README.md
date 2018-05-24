
# Alces Flight Center

## Development

### To setup a development environment

1. Have Ruby version specified in [`.ruby-version`](./.ruby-version) installed
   (if you don't have a preferred method of installing Ruby, I recommend using
   [`rbenv`](https://github.com/rbenv/rbenv) and
   [`ruby-build`](https://github.com/rbenv/ruby-build)).

2. Have PostgreSQL version specified in [`.travis.yml`](./.travis.yml)
   installed and running, and configured so you can connect to it as the
   `postgres` user without a password. On CentOS the following should achieve
   this step (other OSes may vary):

    ```bash
    yum install postgresql96 postgresql96-devel postgresql96-server
    postgresql-setup initdb
    sudoedit `/var/lib/postgres/data/pg_hba.conf` # or `/var/lib/pgsql/data/pg_hba.conf`
    # Change all entries in `METHOD` column to trust, and save and exit.
    systemctl start postgresql
    ```

3. Have [`aws-cli`](https://github.com/aws/aws-cli) installed.

4. Have [`yarn`](https://yarnpkg.com/lang/en/) installed.

5. Clone and setup this repo:

    ```bash
    git clone git@github.com:alces-software/alces-flight-center.git
    cd alces-flight-center
    bin/setup
    ```

6. Perform required/suggested additional manual setup steps output at the end
   of `bin/setup` script.


### To run development server(s)

In separate shells:

- `bin/rails server`;

- `bin/webpack-dev-server` (compiles new Case form Elm app; must be running to
  use new Case form in development);

- `bin/start-docker-redis` (to run Redis server Docker container, which handles
  our asynchronous email queue; not normally required in development). Note:
  `bin/stop-docker-redis` stops this again.


### To update development environment

Re-run `bin/setup` script; it should safely be able to be run multiple times.

### To run tests

- All tests:
  ```bash
  bundle exec rspec
  ```

- All non-Selenium tests (may want to skip these locally as depend on Firefox
  and[`geckodriver`](https://github.com/mozilla/geckodriver), and pop open
  browser window when run):

  ```bash
  bundle exec rspec --tag '~js'
  ```

- Specific tests: see `rspec -h`


### To develop with latest production data

```bash
rake alces:data:import_and_migrate_production
```

This will import the latest production database backup, modify this to remove
real user emails and passwords, and then run all Rails and
[data](https://github.com/OffgridElectric/rails-data-migrations) migrations on
top of this.

This is useful for checking whether recent migrations of both kinds will
cleanly apply when we next deploy to production, as well as generally allowing
you to develop with real-ish data. This also allows you to pay less attention
when developing to situations which theoretically could occur but don't in
practise (though it's usually still worth considering things which a non-admin
user could do, even if they haven't yet).


### To sign in as a user in development

1. Take the email for a user which existed in production at the time you last
   ran `rake alces:data:import_and_migrate_production`, and split off the local
   part (e.g. `bob.whitelock@alces-software.com` -> `bob.whitelock`);

2. Sign in with following credentials:

    - username: `${local_part}@example.com`;

    - password: `password`.


### To develop feature

1. Pick available card at https://trello.com/b/EYQnm3F9/alces-flight-center;

2. implement it, with test coverage;

3. make one or more PRs: https://github.com/alces-software/alces-flight-center/pulls;

4. link PR to Trello card and vice versa, and move to 'Review';

5. get this to pass all checks (currently just Travis; there are a couple of
   intermittent test failures at the moment, so you might occasionally need to
   tell Travis to restart the build - see
   https://trello.com/c/YmGIOtap/273-fix-intermittent-ci-failure);

6. get this reviewed and merged.


### To improve development setup process

- Implement https://trello.com/c/OVPBHLyS/291-dockerize-flight-center;

- and/or: document unclear/inaccurate/missing steps in above sections.


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
