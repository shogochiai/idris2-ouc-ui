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
-- Main Content Router
-- =============================================================================

||| Route to active tab content
viewContent : Model -> Node Msg
viewContent model = case model.activeTab of
  TabAuditors  => viewAuditors model.auditors
  TabOUs       => viewOUs model.ous
  TabProposals => viewProposals model.proposals
  TabEvents    => viewEvents model.events

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
        , button [onClick Refresh, class "btn btn-refresh"] [Text "Refresh"]
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
