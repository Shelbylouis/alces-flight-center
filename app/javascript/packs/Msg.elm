module Msg exposing (..)

import Bootstrap.Modal as Modal
import Rails


type Msg
    = ChangeSelectedCluster String
    | ChangeSelectedCategory String
    | ChangeSelectedIssue String
    | ChangeSelectedTier String
    | ChangeSelectedComponent String
    | ChangeSelectedService String
    | ChangeSubject String
    | ChangeTierField Int String
    | StartSubmit
    | SubmitResponse (Result (Rails.Error String) ())
    | ClearError
    | ClusterChargingInfoModal Modal.State
    | ChargeableIssuePreSubmissionModal Modal.State
