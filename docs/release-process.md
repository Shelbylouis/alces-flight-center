
# Release process

1. Merge everything which should be released into `master`.

2. If the release is a hotfix (the branch merged into `master` is not
   `develop`) then uncomment the appropriate line in `bin/deploy-production`
   script.

3. Run `bin/deploy-production` script.

4. Do other things while this runs.

5. Debug things if the script fails for some reason.

6. Rename the `Done` column at
   https://trello.com/b/EYQnm3F9/alces-flight-center appropriately and create a
   new `Done` column.

7. Announce the release at https://alces.slack.com/messages/C72GT476Y/,
   mentioning where to see what's in this release (the renamed column).
