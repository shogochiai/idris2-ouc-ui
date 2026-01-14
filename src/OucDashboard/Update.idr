module OucDashboard.Update

import OucDashboard.Model

%default total

-- =============================================================================
-- Messages (REQ_UPDATE_*)
-- =============================================================================

||| Application messages
public export
data Msg
  -- Lifecycle
  = Init                              -- REQ_UPDATE_INIT
  | Refresh                           -- REQ_UPDATE_REFRESH
  -- Navigation
  | SwitchTab Tab                     -- REQ_UPDATE_TAB_SWITCH
  -- API Responses
  | GotAuditors (List Auditor)        -- REQ_UPDATE_GOT_AUDITORS
  | GotOUs (List OU)                  -- REQ_UPDATE_GOT_OUS
  | GotProposals (List Proposal)      -- REQ_UPDATE_GOT_PROPOSALS
  | GotEvents (List Event)            -- REQ_UPDATE_GOT_EVENTS
  | ApiError String                   -- REQ_UPDATE_API_ERROR

-- =============================================================================
-- Update Function (MVU pattern)
-- =============================================================================

||| Update function - pure state transformation
export
update : Msg -> Model -> Model
-- REQ_UPDATE_INIT: Init sets loading state (actual fetch done in display)
update Init model = { loadState := Loading } model

-- REQ_UPDATE_REFRESH: Re-fetch all data
update Refresh model = { loadState := Loading } model

-- REQ_UPDATE_TAB_SWITCH: Change active view
update (SwitchTab tab) model = { activeTab := tab } model

-- REQ_UPDATE_GOT_AUDITORS: Update auditor list
update (GotAuditors as) model = { auditors := as, loadState := Loaded } model

-- REQ_UPDATE_GOT_OUS: Update OU list
update (GotOUs os) model = { ous := os, loadState := Loaded } model

-- REQ_UPDATE_GOT_PROPOSALS: Update proposal list
update (GotProposals ps) model = { proposals := ps, loadState := Loaded } model

-- REQ_UPDATE_GOT_EVENTS: Update event list
update (GotEvents es) model = { events := es, loadState := Loaded } model

-- REQ_UPDATE_API_ERROR: Set error state
update (ApiError msg) model = { loadState := Failed msg } model
