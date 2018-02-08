
# Alces Flight Center backup and restore process

## Overview

- Once per day, currently at 2am, the Alces Flight Center Postgres database is
  dumped and backed up to S3.

- This process is handled by the [bin/backup-database](/bin/backup-database) script.

- Future improvements to the process might include:
  - investigating Postgres' ability to do
  [Continuous Archiving and Point-in-Time
  Recovery](https://www.postgresql.org/docs/9.6/static/continuous-archiving.html)
  to allow restoring the database to a more recent point in time, so we risk
  less potential data loss;
  - expiring/archiving backups after a certain amount of time;
  - considering backing up the current Dokku environment variables for Alces
    Flight Center - these shouldn't be lost, and will still all be available
    from other sources, but backing them up to one location could be a good
    idea.

## Restore process

- Download the latest backup from
  https://s3.console.aws.amazon.com/s3/buckets/alces-flight-center/backups/?region=us-east-1.

- `cat` the downloaded database dump and pipe this into a valid `psql`
  connection command to an empty database to be used as the new Alces Flight
  Center database, e.g.:
  ```bash
  cat 2018-01-19 |  psql -U postgres -d alces-flight-center_development
  ```

- This should populate the new database to use an identical schema and data as
  the original database at the time this backup was taken - currently up to 1
  day of data may be lost by this process, depending on the time since the last
  backup; any data loss will need to be handled on a case-by-case basis.
