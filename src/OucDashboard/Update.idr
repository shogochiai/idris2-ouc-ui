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
  -- Economics Integration
  | GotSubscription Subscription      -- REQ_UPDATE_GOT_SUBSCRIPTION
  | GotTreasury Treasury              -- REQ_UPDATE_GOT_TREASURY
  | GotUpgradeEvents (List UpgradeEvent) -- REQ_UPDATE_GOT_UPGRADE_EVENTS
  -- Tier Management
  | RequestTierChange Tier            -- REQ_UPDATE_REQUEST_TIER_CHANGE
  | TierChangeSuccess Tier            -- REQ_UPDATE_TIER_CHANGE_SUCCESS
  | TierChangeFailure String          -- REQ_UPDATE_TIER_CHANGE_FAILURE
  -- Authentication (REQ_UPDATE_AUTH_*)
  | LoginRequest                      -- REQ_UPDATE_AUTH_LOGIN_REQUEST
  | LoginSuccess String               -- REQ_UPDATE_AUTH_LOGIN_SUCCESS (principal)
  | LoginFailure                      -- REQ_UPDATE_AUTH_LOGIN_FAILURE
  | LogoutRequest                     -- REQ_UPDATE_AUTH_LOGOUT_REQUEST
  | LogoutComplete                    -- REQ_UPDATE_AUTH_LOGOUT_COMPLETE

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

-- REQ_UPDATE_GOT_SUBSCRIPTION: Update subscription info
update (GotSubscription sub) model = { subscription := Just sub, loadState := Loaded } model

-- REQ_UPDATE_GOT_TREASURY: Update treasury balances
update (GotTreasury t) model = { treasury := Just t, loadState := Loaded } model

-- REQ_UPDATE_GOT_UPGRADE_EVENTS: Update upgrade event history
update (GotUpgradeEvents evts) model = { upgradeEvents := evts, loadState := Loaded } model

-- REQ_UPDATE_AUTH_LOGIN_REQUEST: Set authenticating state
update LoginRequest model = { authState := Authenticating } model

-- REQ_UPDATE_AUTH_LOGIN_SUCCESS: Set authenticated with principal
update (LoginSuccess principal) model = { authState := Authenticated principal } model

-- REQ_UPDATE_AUTH_LOGIN_FAILURE: Reset to not authenticated
update LoginFailure model = { authState := NotAuthenticated } model

-- REQ_UPDATE_AUTH_LOGOUT_REQUEST: Trigger logout (actual logout in cmd)
update LogoutRequest model = { authState := Authenticating } model

-- REQ_UPDATE_AUTH_LOGOUT_COMPLETE: Reset to not authenticated
update LogoutComplete model = { authState := NotAuthenticated } model

-- REQ_UPDATE_REQUEST_TIER_CHANGE: Start tier change process (sets loading)
update (RequestTierChange tier) model = { loadState := Loading } model

-- REQ_UPDATE_TIER_CHANGE_SUCCESS: Update subscription with new tier
update (TierChangeSuccess tier) model =
  case model.subscription of
    Nothing => { loadState := Loaded } model
    Just sub => { subscription := Just ({ currentTier := tier } sub)
                , loadState := Loaded } model

-- REQ_UPDATE_TIER_CHANGE_FAILURE: Set error state
update (TierChangeFailure msg) model = { loadState := Failed msg } model
