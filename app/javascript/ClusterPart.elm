module ClusterPart exposing (..)

import SupportType exposing (HasSupportType)


type alias ClusterPart a =
    HasSupportType { a | name : String }
