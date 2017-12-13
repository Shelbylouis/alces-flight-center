module Issue.Utils
    exposing
        ( availableForSelectedCluster
        , serviceAllowedFor
        , serviceCanBeAssociatedWith
        )

import Cluster exposing (Cluster)
import Issue exposing (Issue)
import SelectList exposing (SelectList)
import Service exposing (Service)
import ServiceType
import SupportType
import Utils


-- XXX Give this module a better name, or remove/merge back into
-- Issue if possible.


{-|

    Whether given Service can be selected along with given Issue. Returns True
    either when this Service can be associated with this Issue, or Issue does
    not require a Service (so it doesn't matter which is selected).

-}
serviceAllowedFor : Issue -> Service -> Bool
serviceAllowedFor issue service =
    if Issue.serviceRequired issue == ServiceType.None then
        True
    else
        serviceCanBeAssociatedWith service issue


{-|

    Whether given Service can be associated with given Issue. Returns True iff
    Issue requires Service and Service is correct type.

-}
serviceCanBeAssociatedWith : Service -> Issue -> Bool
serviceCanBeAssociatedWith service issue =
    case Issue.serviceRequired issue of
        ServiceType.None ->
            -- Issue does not require a Service.
            False

        ServiceType.SpecificType serviceType ->
            -- Service is allowed iff has ServiceType that Issue requires.
            Utils.sameId serviceType.id service.serviceType

        ServiceType.Any ->
            -- Issue takes any Service.
            True


availableForSelectedCluster : SelectList Cluster -> Issue -> Bool
availableForSelectedCluster clusters issue =
    let
        issueIsManaged =
            Issue.supportType issue == SupportType.Managed

        clusterIsAdvice =
            SelectList.selected clusters
                |> SupportType.isAdvice
    in
    -- An Issue is available so long as it is not a managed issue while an
    -- advice-only Cluster is selected.
    not (issueIsManaged && clusterIsAdvice)
