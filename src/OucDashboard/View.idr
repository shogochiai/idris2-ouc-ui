module OucDashboard.View

import Text.HTML
import OucDashboard.Model
import OucDashboard.Update

%default total

-- =============================================================================
-- Helper Functions
-- =============================================================================

||| Status badge CSS class
statusClass : OUStatus -> String
statusClass Active  = "badge badge-success"
statusClass Syncing = "badge badge-warning"
statusClass Stale   = "badge badge-secondary"
statusClass Error   = "badge badge-danger"

||| Proposal status badge CSS class
proposalStatusClass : ProposalStatus -> String
proposalStatusClass Pending  = "badge badge-info"
proposalStatusClass Approved = "badge badge-success"
proposalStatusClass Rejected = "badge badge-danger"
proposalStatusClass Executed = "badge badge-primary"

||| Tier badge CSS class
tierClass : Tier -> String
tierClass Archive  = "badge badge-secondary"
tierClass Economy  = "badge badge-info"
tierClass Standard = "badge badge-primary"
tierClass RealTime = "badge badge-success"

||| Upgrade status badge CSS class
upgradeStatusClass : UpgradeStatus -> String
upgradeStatusClass UpgradeProposed = "badge badge-info"
upgradeStatusClass UpgradeApproved = "badge badge-success"
upgradeStatusClass UpgradeRejected = "badge badge-danger"
upgradeStatusClass UpgradeExecuted = "badge badge-primary"

-- =============================================================================
-- Tab Navigation (REQ_VIEW_*)
-- =============================================================================

||| Tab button
tabButton : Tab -> Tab -> Node Msg
tabButton activeTab tab =
  let cls = if activeTab == tab then "tab-btn active" else "tab-btn"
  in button [onClick (SwitchTab tab), class cls] [Text (show tab)]

||| Tab navigation bar
tabNav : Tab -> Node Msg
tabNav activeTab =
  div [class "tab-nav"]
    [ tabButton activeTab TabAuditors
    , tabButton activeTab TabOUs
    , tabButton activeTab TabProposals
    , tabButton activeTab TabEvents
    , tabButton activeTab TabEconomics
    , tabButton activeTab TabTreasury
    ]

-- =============================================================================
-- Loading/Error Views (REQ_VIEW_LOADING, REQ_VIEW_ERROR)
-- =============================================================================

||| REQ_VIEW_LOADING: Display loading indicator
export
viewLoading : Node Msg
viewLoading =
  div [class "loading"]
    [ div [class "spinner"] []
    , p [] [Text "Loading data..."]
    ]

||| REQ_VIEW_ERROR: Display error message
export
viewError : String -> Node Msg
viewError msg =
  div [class "error-panel"]
    [ h3 [] [Text "Error"]
    , p [class "error-message"] [Text msg]
    , button [onClick Refresh, class "btn btn-retry"] [Text "Retry"]
    ]

-- =============================================================================
-- Auditor View (REQ_VIEW_AUDITOR_LIST)
-- =============================================================================

||| Render single auditor card
viewAuditorCard : Auditor -> Node Msg
viewAuditorCard aud =
  div [class "card auditor-card"]
    [ div [class "card-header"]
        [ h4 [] [Text aud.name]
        , span [class "auditor-id"] [Text aud.auditorId]
        ]
    , div [class "card-body"]
        [ p [] [Text ("Assigned OUs: " ++ show (length aud.assignedOUs))]
        , ul [class "ou-list"]
            (map (\addr => li [] [Text addr]) aud.assignedOUs)
        ]
    ]

||| REQ_VIEW_AUDITOR_LIST: Display auditor list
export
viewAuditors : List Auditor -> Node Msg
viewAuditors [] =
  div [class "empty-state"] [Text "No auditors registered"]
viewAuditors auditors =
  div [class "auditor-grid"]
    (map viewAuditorCard auditors)

-- =============================================================================
-- OU View (REQ_VIEW_OU_STATUS)
-- =============================================================================

||| Render single OU card
viewOUCard : OU -> Node Msg
viewOUCard ou =
  div [class "card ou-card"]
    [ div [class "card-header"]
        [ span [class (statusClass ou.status)] [Text (show ou.status)]
        , span [class "chain-badge"] [Text (show ou.chain)]
        ]
    , div [class "card-body"]
        [ p [class "address"] [Text ou.address]
        , p [class "sync-time"] [Text ("Last sync: " ++ ou.lastSyncTime)]
        ]
    ]

||| REQ_VIEW_OU_STATUS: Display OU status cards
export
viewOUs : List OU -> Node Msg
viewOUs [] =
  div [class "empty-state"] [Text "No OUs registered"]
viewOUs ous =
  div [class "ou-grid"]
    (map viewOUCard ous)

-- =============================================================================
-- Proposal View (REQ_VIEW_PROPOSAL_LIST)
-- =============================================================================

||| Render single proposal card
viewProposalCard : Proposal -> Node Msg
viewProposalCard prop =
  div [class "card proposal-card"]
    [ div [class "card-header"]
        [ span [class (proposalStatusClass prop.status)] [Text (show prop.status)]
        , span [class "proposal-id"] [Text prop.proposalId]
        ]
    , div [class "card-body"]
        [ p [class "description"] [Text prop.description]
        , div [class "vote-counts"]
            [ span [class "votes-for"] [Text ("For: " ++ show prop.votesFor)]
            , span [class "votes-against"] [Text ("Against: " ++ show prop.votesAgainst)]
            ]
        ]
    ]

||| REQ_VIEW_PROPOSAL_LIST: Display proposal list
export
viewProposals : List Proposal -> Node Msg
viewProposals [] =
  div [class "empty-state"] [Text "No proposals"]
viewProposals props =
  div [class "proposal-list"]
    (map viewProposalCard props)

-- =============================================================================
-- Event View (REQ_VIEW_EVENT_LOG)
-- =============================================================================

||| Render single event row
viewEventRow : Event -> Node Msg
viewEventRow evt =
  tr []
    [ td [class "timestamp"] [Text evt.timestamp]
    , td [class "event-type"] [Text evt.eventType]
    , td [class "chain"] [Text (show evt.chain)]
    , td [class "details"] [Text evt.details]
    ]

||| REQ_VIEW_EVENT_LOG: Display event log
export
viewEvents : List Event -> Node Msg
viewEvents [] =
  div [class "empty-state"] [Text "No events"]
viewEvents evts =
  table [class "event-table"]
    [ thead []
        [ tr []
            [ th [] [Text "Timestamp"]
            , th [] [Text "Type"]
            , th [] [Text "Chain"]
            , th [] [Text "Details"]
            ]
        ]
    , tbody [] (map viewEventRow evts)
    ]

-- =============================================================================
-- Economics View (REQ_VIEW_TIER_STATUS)
-- =============================================================================

||| REQ_VIEW_TIER_STATUS: Display current tier badge with sync frequency
export
viewTierStatus : Maybe Subscription -> Node Msg
viewTierStatus Nothing =
  div [class "empty-state"] [Text "No subscription data"]
viewTierStatus (Just sub) =
  div [class "card tier-card"]
    [ div [class "card-header"]
        [ h4 [] [Text "Subscription Status"]
        ]
    , div [class "card-body"]
        [ div [class "tier-info"]
            [ span [class (tierClass sub.currentTier)] [Text (show sub.currentTier)]
            , span [class "sync-freq"] [Text ("Sync: " ++ tierSyncFreq sub.currentTier)]
            ]
        , p [class "cost"] [Text ("Monthly: ¥" ++ show (tierMonthlyCost sub.currentTier))]
        , p [class "expiry"] [Text ("Expires: " ++ sub.expiryDate)]
        , p [class "auto-renew"]
            [Text (if sub.autoRenew then "Auto-renew: ON" else "Auto-renew: OFF")]
        ]
    ]

-- =============================================================================
-- Treasury View (REQ_VIEW_TREASURY_BALANCE)
-- =============================================================================

||| REQ_VIEW_TREASURY_BALANCE: Display treasury balances with 70/30 distribution
export
viewTreasuryBalance : Maybe Treasury -> Node Msg
viewTreasuryBalance Nothing =
  div [class "empty-state"] [Text "No treasury data"]
viewTreasuryBalance (Just t) =
  div [class "card treasury-card"]
    [ div [class "card-header"]
        [ h4 [] [Text "Treasury Balances"]
        , span [class "badge badge-info"] [Text "70/30 Split"]
        ]
    , div [class "card-body"]
        [ div [class "balance-row"]
            [ span [class "label"] [Text "ckETH:"]
            , span [class "value"] [Text (show t.ckEthBalance ++ " wei")]
            ]
        , div [class "balance-row"]
            [ span [class "label"] [Text "ICP:"]
            , span [class "value"] [Text (show t.icpBalance ++ " e8s")]
            ]
        , div [class "balance-row"]
            [ span [class "label"] [Text "Cycles:"]
            , span [class "value"] [Text (show t.cyclesBalance)]
            ]
        ]
    ]

-- =============================================================================
-- Upgrade Timeline View (REQ_VIEW_UPGRADE_TIMELINE)
-- =============================================================================

||| Render single upgrade event row
viewUpgradeEventRow : UpgradeEvent -> Node Msg
viewUpgradeEventRow evt =
  tr []
    [ td [class "timestamp"] [Text evt.timestamp]
    , td [class "upgrade-id"] [Text evt.upgradeId]
    , td [class "ou-address"] [Text evt.ouAddress]
    , td [class "status"] [span [class (upgradeStatusClass evt.status)] [Text (show evt.status)]]
    , td [class "votes"]
        [ span [class "votes-for"] [Text ("+" ++ show evt.votesFor)]
        , Text " / "
        , span [class "votes-against"] [Text ("-" ++ show evt.votesAgainst)]
        ]
    ]

||| REQ_VIEW_UPGRADE_TIMELINE: Display upgrade proposal timeline with voting progress
export
viewUpgradeTimeline : List UpgradeEvent -> Node Msg
viewUpgradeTimeline [] =
  div [class "empty-state"] [Text "No upgrade events"]
viewUpgradeTimeline evts =
  table [class "upgrade-table"]
    [ thead []
        [ tr []
            [ th [] [Text "Time"]
            , th [] [Text "Upgrade ID"]
            , th [] [Text "OU"]
            , th [] [Text "Status"]
            , th [] [Text "Votes"]
            ]
        ]
    , tbody [] (map viewUpgradeEventRow evts)
    ]

-- =============================================================================
-- Auth Status View (REQ_VIEW_AUTH_STATUS)
-- =============================================================================

||| Truncate principal for display
truncatePrincipal : String -> String
truncatePrincipal pid =
  if length pid > 16
    then substr 0 8 pid ++ "..." ++ substr (length pid `minus` 5) 5 pid
    else pid

||| REQ_VIEW_AUTH_STATUS: Display authentication status with login/logout button
export
viewAuthStatus : AuthState -> Node Msg
viewAuthStatus NotAuthenticated =
  div [class "auth-status"]
    [ button [onClick LoginRequest, class "btn btn-login"] [Text "Login with II"]
    ]
viewAuthStatus Authenticating =
  div [class "auth-status"]
    [ span [class "auth-loading"] [Text "Authenticating..."]
    ]
viewAuthStatus (Authenticated principal) =
  div [class "auth-status"]
    [ span [class "principal-badge"] [Text (truncatePrincipal principal)]
    , button [onClick LogoutRequest, class "btn btn-logout"] [Text "Logout"]
    ]

-- =============================================================================
-- Main Content Router
-- =============================================================================

||| Route to active tab content
viewContent : Model -> Node Msg
viewContent model = case model.activeTab of
  TabAuditors  => viewAuditors model.auditors
  TabOUs       => viewOUs model.ous
  TabProposals => viewProposals model.proposals
  TabEvents    => viewEvents model.events
  TabEconomics => viewTierStatus model.subscription
  TabTreasury  => viewTreasuryBalance model.treasury

-- =============================================================================
-- Main View
-- =============================================================================

||| Render the application view
export
view : Model -> Node Msg
view model =
  div [class "dashboard"]
    [ header [class "header"]
        [ h1 [] [Text "OUC Dashboard"]
        , div [class "header-actions"]
            [ viewAuthStatus model.authState
            , button [onClick Refresh, class "btn btn-refresh"] [Text "Refresh"]
            ]
        ]
    , tabNav model.activeTab
    , div [class "main-content"]
        [ case model.loadState of
            Idle      => div [class "idle"] [Text "Click Refresh to load data"]
            Loading   => viewLoading
            Loaded    => viewContent model
            Failed msg => viewError msg
        ]
    , div [class "footer"]
        [ Text "OUC Dashboard - Observable Unit Canister Monitoring" ]
    ]
