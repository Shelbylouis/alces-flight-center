
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

5. Clone and setup [`flight-sso`](https://github.com/alces-software/flight-sso)
   repo, following the instructions at
   https://github.com/alces-software/flight-sso#development. This can be done
   anywhere, but currently for the `alces:data:create_sso_accounts` Rake task
   to work correctly this and the `alces-flight-center` repo should be sibling
   directories of each other (this task is used by
   `alces:data:import_and_migrate_production`, where we import recent
   production data, so you will probably want to use it unless you know what
   you're doing).

6. Clone and setup this repo:

    ```bash
    git clone git@github.com:alces-software/alces-flight-center.git
    cd alces-flight-center
    bundle exec bin/setup
    ```

7. Perform required/suggested additional manual setup steps output at the end
   of `bin/setup` script.

8. Read through the `.env.example` file and set up any necessary environment
   variables.


### To run development server(s)

In separate shells:

- `bin/rails server`;

- `cd ../flight-sso && docker-compose up` (to run
  [`flight-sso`](https://github.com/alces-software/flight-sso) server, required
  to sign in).

- `bin/webpack-dev-server` (to compile new Case form Elm app; must be running
  to use new Case form in development);

- `bin/start-docker-redis` (to run Redis server Docker container, which handles
  our asynchronous email queue; not normally required in development). Note:
  `bin/stop-docker-redis` stops this again.


### To access Flight Center in development

By default the `flight-sso` server will listen on `localhost` port `4000`, so
the SSO root URL will be `http://accounts.alces-flight.lvh.me:4000`.

Accessing SSO, and SSO-authenticated services, does not work via `localhost`,
so you'll have to access your local Flight Center through
`http://center.alces-flight.lvh.me:3000` (or whatever port you're running it
on).

Flight Center doesn't need to access the SSO server directly, so you should be
fine if you're running Center in a VM as long as your browser can access both.
It does, however, need to have a shared secret with the SSO server, passed in
either via `secrets.yml` (in development) or the `JSON_WEB_TOKEN_SECRET`
environment variable in production.


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

- To get Rails to throw exceptions rather than render fancy error pages, set
  `EXCEPTIONS=true` when running `rspec`. This will cause some otherwise-passing
  tests to fail!


### To develop with latest production data

```bash
rake alces:data:import_and_migrate_production
```

This will:

- import the latest production database backup;

- run all Rails and [data](https://github.com/ilyakatz/data-migrate) migrations
  on top of this;

- modify this to remove real user emails and passwords;

- create an SSO `Account` in your local `flight-sso` environment for each
  Flight Center `User`, where this does not already exist. Note: Flight Center
  `User`s are matched with SSO `Account`s by email address, and both must exist
  to sign in to Flight Center as a `User`.

This is useful for checking whether recent migrations of both kinds will
cleanly apply when we next deploy to production, as well as generally allowing
you to develop with real-ish data. This also allows you to pay less attention
when developing to situations which theoretically could occur but don't in
practise (though it's usually still worth considering things which a non-admin
user could do, even if they haven't yet).


### To sign in as a user in development

As described above, Flight Center `User`s are matched with SSO `Account`s by
email address, and both must exist to sign in to Flight Center as a `User`.
Normally this should be transparent in development, and after running `rake
alces:data:import_and_migrate_production` you should be able to sign in as any
`User` by the following process:

1. Take the email for a `User` which existed in production at the time you last
   ran `rake alces:data:import_and_migrate_production`, split off the local
   part, and remove any non-alphanumeric characters (e.g.
   `bob.whitelock@alces-software.com` -> `bobwhitelock`);

2. Sign in with the following credentials:

    - username: `$username`, as found above;

    - password: `password`.

Alternatively, a Flight Center `User` and corresponding Flight SSO account can
be created by the following process:

- Via `rails console` in Flight SSO, or via the website registration form,
  create yourself a Flight SSO account using any email address. Be sure to
  confirm the account (either the web method or with `Account#confirm()` in the
  console)
- Via `rails console` in Flight Center, create yourself a Flight Center account
  using the same email address (and don't forget `admin: true`)
- Log in via SSO. Enjoy admin powers responsibly.

The process is the same in production except that you probably already have a
Flight SSO account there.

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

### To set up Slack notifications for your development environment

There are two environment variables that need to be set in your .env file
before Slack notifications will work within your development environment,
`SLACK_CHANNEL` and `SLACK_WEBHOOK_URL`.

The former refers to the channel (including preceding `#`) that the notifier
will send all notifications to. Therefore if you wish to receive all Slack
notifications via private messages you will need to set this to 
`@<your_slack_username_here>`. Slack docs suggest that you can't change the
channel from the one defined in the webhook, which means that in production
this should be `#support`.

The latter however is vital to making the notifier function properly and should
be kept secret. This URL can be found within the `Incoming WebHooks` section
of our Slack workspace. From there you need to navigate to the `Alces Flight
Center` configuration which will display the URL for you in its configuration
page. Once you copy this URL to its respective environment variable you should
be able to send notfications to Slack from your development environment.

### To develop new Case form app

The Case form app is written in Elm. See http://elm-lang.org/docs for various
documentation related to working with this, and in particular see
https://guide.elm-lang.org/install.html#configure-your-editor for how to
improve the Elm editing experience for your editor.

Running `bin/webpack-dev-server`, as described above, should be sufficient to
re-compile the Case form app when any relevant files are changed.

We use the latest (experimental) version of
[`elm-format`](https://github.com/avh4/elm-format#experimental-version) to
format our Elm code, which ensures the code is all consistently formatted and
minimizes the time we need to spend caring about how it is formatted. This can
be installed with `yarn global add elm-format@exp`, and should ideally be run
across every Elm source file prior to committing any changes - all major Elm
editor plugins should support doing this automatically on file save; this may
require toggling an option to enable.

Also, some possibly relevant comments related to aspects of the architecture of
the Case form app, which could be relevant to refer back to in future (and
hopefully won't get out of date):

- https://github.com/alces-software/alces-flight-center/pull/346#discussion_r194493189
  (point 2);
- https://github.com/alces-software/alces-flight-center/pull/346#pullrequestreview-127604799
  (in particular response to second quote).

### To deploy changes to staging/production

The following Rake tasks are available to deploy local changes to
staging/production:

```bash
$ rake -T | grep alces:deploy
[...]
rake alces:deploy:production                   # Deploy to production
rake alces:deploy:production:dry_run           # Output what will happen on deploy to production, without doing anything
rake alces:deploy:production:hotfix            # Deploy hotfix release to production
rake alces:deploy:production:hotfix:dry_run    # Output what will happen on hotfix deploy to production, without doing anything
rake alces:deploy:staging                      # Deploy to staging
rake alces:deploy:staging:dry_run              # Output what will happen on deploy to staging, without doing anything
```

Some notes on using these:

- Each command should just work, and will fail fast and safely if any necessary
  pre-conditions are not met; the non-`dry_run` commands also ask for
  confirmation first before doing anything.

- Each command will output any needed additional manual steps at the end of
  running it.

- The commands to deploy to production require you to be on the `master` branch
  before running.

- The commands to deploy to staging expects a `STAGING_PASSWORD` environment
  variable to be set when run, e.g. `rake alces:deploy:staging
  STAGING_PASSWORD='foo'`, which previously was used to modify the production
  data imported in staging to allow signing in as site users using this
  password.

  This is still done but no longer has any effect, since Flight Center now uses
  [`flight-sso`](https://github.com/alces-software/flight-sso) which has its
  own password management; however the code to do this has still been kept for
  now, in case we later want to perform similar changes to the
  `flight-sso-staging` instance on deploy (see
  https://trello.com/c/p2UsFby4/206-consider-creating-modifying-flight-sso-staging-users-for-imported-production-users-on-deploy-to-staging).

- On deploy to staging we import the latest production backup so we can try
  things out with real data; when this is done the staging database is dropped
  and then recreated afresh and the new data imported. I have noticed that, if
  you are unlucky with when things get run, a cron job could attempt to connect
  to the database at the point when the import script attempts to drop it; if
  there are any ongoing connections the production import will then fail,
  causing the whole deploy to abort.

  To avoid any chance of this happening, I suggest commenting the staging cron
  jobs (via `crontab -e` on the apps server) before deploying to staging, and
  then un-commenting these again post-deploy.

- See [`docs/hotfix-release-policy.md`](./docs/hotfix-release-policy.md) for
  when we should consider making a hotfix vs a normal release.


## Creating accounts for customers

- If they don't have a Flight SSO account, they should register for one first.
- Get them to give you the email address they used for their Flight SSO account
  (possibly double-check against the SSO database just to make sure).
- Create them a Flight Center account in the appropriate site, using the email
  address of their Flight SSO account.


## Design

### Authorisation

A brief overview of how we're currently altering the UI based on what the
`current_user` is authorised to do:

- Whenever we do conditional logic on the role of the current user, e.g. `if
  current_user.admin?`, we should instead switch using the Pundit policy for
  the record and action we are considering, e.g. `if policy(@case).create?`
  (the user is implicit when doing this in a view). This avoids duplicating
  authorisation logic in various places in views/decorators etc., which avoids
  the possibility of this getting out-of-sync with the actual auth logic in the
  policy.

- When buttons etc. are admin-only, they should not be shown at all to other
  types of users.

- When buttons etc. are contact-only, they should not be shown to admins.

- Any button that will change the state of the system, rather than just being
  for navigation or querying purposes, should not be available to viewers, and
  this should be both enforced server-side and indicated client-side (either by
  making the buttons unavailable or disabled as appropriate).

- Viewer users should be able to see (but not alter) all information across the
  site which should be available to contacts.

- When a button is available to contacts but should not be available to
  viewers, this should be indicated by disabling the button and indicating why
  this is the case - this can be done in a consistent way across the site using
  the `PolicyDependentOptions` class.

### When to consider implementing admin-only features outside `rails_admin` interface

For basic CRUD of data by admins we have an auto-generated
[`rails_admin`](https://github.com/sferik/rails_admin) interface. Using this,
with minor customizations, saves time developing basic admin-only functionality
that would be better spent elsewhere. Refer to response to point 3 at
https://github.com/alces-software/alces-flight-center/pull/334#pullrequestreview-126343497
for when we should consider going beyond this.


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
