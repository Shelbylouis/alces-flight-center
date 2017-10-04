module Component exposing (..)

import Cluster


type alias Component =
    { id : Id
    , name : String
    , clusterId : Cluster.Id
    }


type Id
    = Id Int


forCluster : Cluster.Id -> List Component -> List Component
forCluster clusterId components =
    let
        partOfCluster =
            \component ->
                component.clusterId == clusterId
    in
    List.filter partOfCluster components
