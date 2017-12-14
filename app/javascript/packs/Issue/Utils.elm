module Issue.Utils exposing (..)

import Cluster exposing (Cluster)
import Issue exposing (Issue)
import SelectList exposing (SelectList)
import Service exposing (Service)
import ServiceType
import SupportType
import Utils


-- XXX Give this module a better name, or remove/merge back into
-- Issue if possible.


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
