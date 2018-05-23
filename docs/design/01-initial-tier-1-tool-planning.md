
Plans for initial MOTD tool, with consideration to future user/group management
tool(s).

# Requirements

- Every Cluster should have a MOTD.

- We want to update this via the Case form; unlike with any existing Tier
  fields when this is done we also want to show the current MOTD in the form.

- It is possible that we will get multiple MOTD change request Cases in
  succession, in which case only the last change really needs to be made.

- Soon we will want similar handling for creating, updating, and deleting
  Cluster users for a Cluster via the Case form.


# Implementation plan

- Add `motd` field to Cluster.

- Add `tool` field to Tier, which will be required for level 1 Tier/forbidden
  for other levels.

- Add a new 'Request change of MOTD' Issue with a level 1 Tier with a new
  `motd` tool.
  - This might fit best within our current hierarchy to be available under the
    'HPC Environment' Service in the 'End User Assistance' Category (or
    wherever else you want).

- When a level 1 Tier is selected in the Case form the associated tool will be
  displayed
  - for the MOTD tool this will just mean:
    - the current MOTD is displayed;
    - a textarea is given pre-filled with the current MOTD, which can then be
      adapted/replaced with the new one to be requested.

- When a Case is created using the tool, in addition to the usual things done
  on creation of a Case (displaying the data on the Case page, emailing users
  with the details of the Case etc.) a `ChangeMotdRequest` will be created.

- A Case can have 0 or 1 `ChangeMotdRequest` associated with it, this will be
  the only relationship currently needed for `ChangeMotdRequest`.

- A `ChangeMotdRequest` will have an `apply` method, which will perform the
  change represented by this request (i.e. change the MOTD of the Cluster to
  the value in this request).
  
  This method will be able to made available to admins in various ways -
  initially a button on the Case page would make sense, later a table of all
  Tier 1 requests (discussed below) could be shown to admins including this
  button so they can easily go through each and make the changes in succession.

- `apply`ing a Tier 1 request will initially be decoupled from `resolve`ing the
  associated Case - so these two actions can be done or not done independently
  of each other. I can see various reasons we might want to do both
  independently:

  - We may want to `resolve` a Case and not have to `apply` an associated
    request if the request has already been superseded by a later request;
    decoupling them allows this whereas if they had to be done together we
    would need to make sure everything is always done in the right order.

  - We may want to `apply` a request but not `resolve` the associated Case if
    we want to re-`apply` the change in the request, or if we want to keep the
    Case open after making the change for some reason.
    
    `resolve` is also a contact-facing action which will send an email etc.,
    whereas I am imagining `apply` as only visible to admins and users will
    only be able to see the results of the admin doing this (the changed MOTD);
    therefore it seems better to keep the separation and admins can `apply`
    things as needed and only `resolve` when they are ready to inform the Site
    contact.

  - Later I am also imagining we may want to have multiple Tier 1 requests
    associated with a single Case created via a tool, e.g. various user change
    requests created with the User Management tool, so it would make sense to
    have these be independent actions which an admin can do each of in turn,
    and then `resolve` the Case when they are done.

- I also don't see a reason that we need to forbid re-`apply`ing a request, as
  allowing this could be useful in certain situations, e.g. if we get multiple
  requests to change the MOTD and apply a later one and then an earlier one
  which it has superseded, we may want to reverse this change and allowing
  re-`apply`ing the later one would seem the obvious way to support this.
  Distinguishing if a request has already been `apply`ed or not in the UI would
  still seem a reasonable thing to do however, so admins can more easily see
  this and work through requests.


# Consideration of future tools in above plan

The above plan was made with consideration of how future Tier 1 tools, in
particular the User Management tool, would fit into this (and would be a bit
over-engineered if all we needed was a way for Users to request the MOTD be
changed while viewing the existing MOTD). Some current thoughts on how the User
Management tool will work with the above:

- We will have a single User Management tool accessible through the Case form,
  where they will be able to view their existing Users, pending requests, and
  create, update, or delete these Users. For each of these actions when the
  form is submitted we will create a corresponding 'request' model associated
  with the Case, i.e. `CreateUserRequest`, `UpdateUserRequest`,
  `DeleteUserRequest`; each of these holds the relevant data for performing the
  given action on the given `ClusterUser`.

- Each of these request models will have an `apply` action; however, unlike
  with the MOTD change request, when these are run we will operate by
  creating/updating a new `ClusterUser` model which will be associated with the
  Cluster (aside: at some distant point this could be merged with our normal
  `User` model, when we want to provide non-contact Users access to logging
  Cases through Flight Center).

- These requests will be accessible in similar ways to MOTD requests, i.e.
  initially they will be shown on the associated Case page, later they could be
  shown in a global table for admins or maybe on the corresponding User
  Management Service page.

- When performing actions through this tool it would be ideal to allow
  operating on:

  - existing `ClusterUser`s,

  - already pending requests (which would allow creating a User and then
    immediately editing it before an admin creates it, e.g. if a contact
    decides it should be added to a different group),

  - and requests created during the same session with the tool (which could
    allow things like creating a group and then creating some users using it).

- Similar things to all the above will apply to Group Management, which could
  be done either through a different, similar tool or the same tool.
