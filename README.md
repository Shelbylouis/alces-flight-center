
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
    bundle exec bin/setup
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


### To update Flight Chrome for Flight Center

Flight Chrome from
[`alces-flight-www`](https://github.com/alces-software/alces-flight-www) is
used for the header and footer of Flight Center, and may periodically need
updating to support new features/content/styles etc. for these. To do this:

1. Have `alces-flight-www` checked out as a sibling directory, named
   `alces-flight-www`, of wherever you have cloned this repo.

2. Make sure `alces-flight-www` is on the branch you want to build
   `flight-chrome` from.

3. Run `bin/update-flight-chrome`.

4. Make the necessary manual updates output at the end of this script.

## Old SSO docs (need to combine with above)

### Required environment variables
- `SSO_BASE_URL` - base URL for SSO server. In production, should be
`https://accounts.alces-flight.com`. This is passed through into the generated
HTML.
- `JSON_WEB_TOKEN_SECRET` - Shared secret for verifying SSO token signatures. This
should be the same value as that for `flight-sso` in the environment you're
running in.

### Running SSO in development

In order to log in to Flight Center in development you'll need a locally-running
copy of `flight-sso`, which you can check out from
`https://github.com/alces-software/flight-sso`.

By default (`docker-compose up` to start it) it'll listen on `localhost` port
`4000`, so the SSO root URL will be `http://accounts.alces-flight.lvh.me:4000`.

Accessing SSO, and SSO-authenticated services, does not work via `localhost`,
so you'll have to access your local Flight Center through
`http://center.alces-flight.lvh.me:3000` (or whatever port you're running it on).

Flight Center doesn't need to access the SSO server directly, so you should be
fine if you're running Center in a VM as long as your browser can access both.
It does, however, need to have a shared secret with the SSO server, passed in
either via `secrets.yml` (in development) or the
`JSON_WEB_TOKEN_SECRET` environment variable in production.

### Creating user accounts

User accounts created in Flight Center are matched with SSO accounts by email
address.

#### Creating yourself an admin account in development

- Via `rails console` in Flight SSO, or via the website registration form,
create yourself a Flight SSO account using any email address. Be sure to
confirm the account (either the web method or with `Account#confirm()` in the
console)
- Via `rails console` in Flight Center, create yourself a Flight Center account
using the same email address (and don't forget `admin: true`)
- Log in via SSO. Enjoy admin powers responsibly.

The process is the same in production except that you probably already have a
Flight SSO account there.

#### Creating accounts for customers

- If they don't have a Flight SSO account, they should register for one first.
- Get them to give you the email address they used for their Flight SSO account
(possibly double-check against the SSO database just to make sure).
- Create them a Flight Center account in the appropriate site, using the email
address of their Flight SSO account.

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
