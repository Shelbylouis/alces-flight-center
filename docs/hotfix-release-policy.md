
# Hotfix policy

## When we can/should hotfix

1. Fix is for a critical level bug (i.e. system is broken)
2. Fix does not significantly affect or modify existing user-facing
   functionality
3. Fix has only a cosmetic effect on existing user-facing functionality
   (styles, layout)
4. Fix is restricted in scope (i.e. only affects one subsystem) and can be
   easily smoke tested
5. Fix is to a data structure or database content or other data fixtures

## When we can't/shouldn't hotfix

1. Fix introduces a new feature or modifies an existing feature -- this needs
   to go through feature testing phase
2. Fix cannot be easily smoke tested -- potentially introduces unecessary risk

## What we should do after releasing a hotfix

1. Test that the problem has been alleviated
2. Announce to channel that a hotfix has been released and what it fixes
