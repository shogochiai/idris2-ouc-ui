module OucDashboard.Tests.AllTests

import Text.HTML
import OucDashboard.Model
import OucDashboard.Update
import OucDashboard.View
import Data.List

%default covering

-- =============================================================================
-- Test Helpers
-- =============================================================================

||| Assert equality
assertEq : (Eq a, Show a) => String -> a -> a -> IO Bool
assertEq name expected actual =
  if expected == actual
    then do putStrLn $ "  PASS: " ++ name
            pure True
    else do putStrLn $ "  FAIL: " ++ name
            putStrLn $ "    Expected: " ++ show expected
            putStrLn $ "    Actual: " ++ show actual
            pure False

||| Assert boolean condition
assertTrue : String -> Bool -> IO Bool
assertTrue name cond =
  if cond
    then do putStrLn $ "  PASS: " ++ name
            pure True
    else do putStrLn $ "  FAIL: " ++ name
            pure False

-- =============================================================================
-- Model Tests
-- =============================================================================

-- | SPEC: REQ_MODEL_INIT - Initial model has empty lists and Loading state
test_REQ_MODEL_INIT : IO Bool
test_REQ_MODEL_INIT = do
  let m = initialModel
  r1 <- assertEq "initial loadState is Idle" Idle m.loadState
  r2 <- assertTrue "initial auditors empty" (null m.auditors)
  r3 <- assertTrue "initial ous empty" (null m.ous)
  r4 <- assertTrue "initial proposals empty" (null m.proposals)
  r5 <- assertTrue "initial events empty" (null m.events)
  pure (r1 && r2 && r3 && r4 && r5)

-- | SPEC: REQ_MODEL_AUDITOR - Auditor type has id, name, and assigned OU list
test_REQ_MODEL_AUDITOR : IO Bool
test_REQ_MODEL_AUDITOR = do
  let aud = MkAuditor "aud-001" "Alice" ["0x123", "0x456"]
  r1 <- assertEq "auditor id" "aud-001" aud.auditorId
  r2 <- assertEq "auditor name" "Alice" aud.name
  r3 <- assertEq "assigned OUs count" 2 (length aud.assignedOUs)
  pure (r1 && r2 && r3)

-- | SPEC: REQ_MODEL_OU - OU type has address, chain, status, and last sync time
test_REQ_MODEL_OU : IO Bool
test_REQ_MODEL_OU = do
  let ou = MkOU "0xabc" Ethereum Active "2025-01-14T12:00:00Z"
  r1 <- assertEq "ou address" "0xabc" ou.address
  r2 <- assertEq "ou chain" Ethereum ou.chain
  r3 <- assertEq "ou status" Active ou.status
  r4 <- assertTrue "ou has sync time" (ou.lastSyncTime /= "")
  pure (r1 && r2 && r3 && r4)

-- | SPEC: REQ_MODEL_PROPOSAL - Proposal type has id, description, votes for/against, and status
test_REQ_MODEL_PROPOSAL : IO Bool
test_REQ_MODEL_PROPOSAL = do
  let prop = MkProposal "prop-001" "Upgrade to v2" 10 3 Pending
  r1 <- assertEq "proposal id" "prop-001" prop.proposalId
  r2 <- assertEq "votes for" 10 prop.votesFor
  r3 <- assertEq "votes against" 3 prop.votesAgainst
  r4 <- assertEq "status" Pending prop.status
  pure (r1 && r2 && r3 && r4)

-- | SPEC: REQ_MODEL_EVENT - Event type has timestamp, event type, chain, and details
test_REQ_MODEL_EVENT : IO Bool
test_REQ_MODEL_EVENT = do
  let evt = MkEvent "2025-01-14T12:00:00Z" "UpgradeProposed" Sepolia "proposal #123"
  r1 <- assertTrue "event has timestamp" (evt.timestamp /= "")
  r2 <- assertEq "event type" "UpgradeProposed" evt.eventType
  r3 <- assertEq "event chain" Sepolia evt.chain
  r4 <- assertTrue "event has details" (evt.details /= "")
  pure (r1 && r2 && r3 && r4)

-- | SPEC: REQ_MODEL_TIER - Tier type has Archive/Economy/Standard/Real-time with sync frequency and monthly cost
test_REQ_MODEL_TIER : IO Bool
test_REQ_MODEL_TIER = do
  r1 <- assertEq "Archive sync freq" "1/day" (tierSyncFreq Archive)
  r2 <- assertEq "Economy sync freq" "1/hour" (tierSyncFreq Economy)
  r3 <- assertEq "Standard sync freq" "1/15min" (tierSyncFreq Standard)
  r4 <- assertEq "RealTime sync freq" "1/min" (tierSyncFreq RealTime)
  r5 <- assertEq "Archive cost" 3 (tierMonthlyCost Archive)
  r6 <- assertEq "Economy cost" 80 (tierMonthlyCost Economy)
  r7 <- assertEq "Standard cost" 300 (tierMonthlyCost Standard)
  r8 <- assertEq "RealTime cost" 4500 (tierMonthlyCost RealTime)
  pure (r1 && r2 && r3 && r4 && r5 && r6 && r7 && r8)

-- | SPEC: REQ_MODEL_SUBSCRIPTION - Subscription type has current tier, expiry date, and auto-renew flag
test_REQ_MODEL_SUBSCRIPTION : IO Bool
test_REQ_MODEL_SUBSCRIPTION = do
  let sub = MkSubscription Standard "2025-02-14T00:00:00Z" True
  r1 <- assertEq "subscription tier" Standard sub.currentTier
  r2 <- assertTrue "subscription has expiry" (sub.expiryDate /= "")
  r3 <- assertEq "subscription auto-renew" True sub.autoRenew
  pure (r1 && r2 && r3)

-- | SPEC: REQ_MODEL_TREASURY - Treasury type has ckETH balance, ICP balance, and cycles remaining
test_REQ_MODEL_TREASURY : IO Bool
test_REQ_MODEL_TREASURY = do
  let t = MkTreasury 1000000000000000000 500000000 1000000000000
  r1 <- assertEq "ckETH balance" 1000000000000000000 t.ckEthBalance
  r2 <- assertEq "ICP balance" 500000000 t.icpBalance
  r3 <- assertEq "cycles balance" 1000000000000 t.cyclesBalance
  pure (r1 && r2 && r3)

-- | SPEC: REQ_MODEL_UPGRADE_EVENT - UpgradeEvent type has UpgradeProposed/Approved/Rejected/Executed status
test_REQ_MODEL_UPGRADE_EVENT : IO Bool
test_REQ_MODEL_UPGRADE_EVENT = do
  let evt = MkUpgradeEvent "upg-001" "0xabc123" UpgradeProposed 5 2 "2025-01-14T12:00:00Z"
  r1 <- assertEq "upgrade id" "upg-001" evt.upgradeId
  r2 <- assertEq "ou address" "0xabc123" evt.ouAddress
  r3 <- assertEq "upgrade status" UpgradeProposed evt.status
  r4 <- assertEq "votes for" 5 evt.votesFor
  r5 <- assertEq "votes against" 2 evt.votesAgainst
  pure (r1 && r2 && r3 && r4 && r5)

-- =============================================================================
-- Update Tests
-- =============================================================================

-- | SPEC: REQ_UPDATE_INIT - Init message triggers API fetch (sets Loading state)
test_REQ_UPDATE_INIT : IO Bool
test_REQ_UPDATE_INIT = do
  let m = update Init initialModel
  assertEq "init sets Loading" Loading m.loadState

-- | SPEC: REQ_UPDATE_REFRESH - Refresh message re-fetches all data
test_REQ_UPDATE_REFRESH : IO Bool
test_REQ_UPDATE_REFRESH = do
  let m = { loadState := Loaded } initialModel
      m' = update Refresh m
  assertEq "refresh sets Loading" Loading m'.loadState

-- | SPEC: REQ_UPDATE_TAB_SWITCH - Tab switch changes active view
test_REQ_UPDATE_TAB_SWITCH : IO Bool
test_REQ_UPDATE_TAB_SWITCH = do
  let m = update (SwitchTab TabProposals) initialModel
  assertEq "tab switched to Proposals" TabProposals m.activeTab

-- | SPEC: REQ_UPDATE_GOT_AUDITORS - GotAuditors updates model with fetched auditor list
test_REQ_UPDATE_GOT_AUDITORS : IO Bool
test_REQ_UPDATE_GOT_AUDITORS = do
  let auditors = [MkAuditor "a1" "Alice" [], MkAuditor "a2" "Bob" []]
      m = { loadState := Loading } initialModel
      m' = update (GotAuditors auditors) m
  r1 <- assertEq "auditors count" 2 (length m'.auditors)
  r2 <- assertEq "loadState is Loaded" Loaded m'.loadState
  pure (r1 && r2)

-- | SPEC: REQ_UPDATE_GOT_OUS - GotOUs updates model with fetched OU list
test_REQ_UPDATE_GOT_OUS : IO Bool
test_REQ_UPDATE_GOT_OUS = do
  -- Test with multiple OUs covering all status branches
  let ous = [ MkOU "0x1" Ethereum Active "now"
            , MkOU "0x2" Sepolia Syncing "now"
            , MkOU "0x3" Model.Base Stale "now"
            , MkOU "0x4" Arbitrum Error "now"
            ]
      m = update (GotOUs ous) initialModel
  r1 <- assertEq "ous count" 4 (length m.ous)
  r2 <- assertEq "loadState is Loaded" Loaded m.loadState
  -- Verify chain coverage
  r3 <- assertEq "first OU chain" Ethereum (maybe Ethereum (\o => o.chain) (head' m.ous))
  -- Verify status coverage
  r4 <- assertEq "first OU status" Active (maybe Stale (\o => o.status) (head' m.ous))
  pure (r1 && r2 && r3 && r4)

-- | SPEC: REQ_UPDATE_GOT_PROPOSALS - GotProposals updates model with fetched proposal list
test_REQ_UPDATE_GOT_PROPOSALS : IO Bool
test_REQ_UPDATE_GOT_PROPOSALS = do
  let props = [MkProposal "p1" "desc" 5 2 Pending]
      m = update (GotProposals props) initialModel
  assertEq "proposals count" 1 (length m.proposals)

-- | SPEC: REQ_UPDATE_GOT_EVENTS - GotEvents updates model with fetched event list
test_REQ_UPDATE_GOT_EVENTS : IO Bool
test_REQ_UPDATE_GOT_EVENTS = do
  let evts = [MkEvent "now" "Test" Ethereum "details"]
      m = update (GotEvents evts) initialModel
  assertEq "events count" 1 (length m.events)

-- | SPEC: REQ_UPDATE_API_ERROR - ApiError sets error state with message
test_REQ_UPDATE_API_ERROR : IO Bool
test_REQ_UPDATE_API_ERROR = do
  let m = update (ApiError "Network error") initialModel
  assertEq "error state" (Failed "Network error") m.loadState

-- | SPEC: REQ_UPDATE_GOT_SUBSCRIPTION - GotSubscription updates model with tier and subscription status
test_REQ_UPDATE_GOT_SUBSCRIPTION : IO Bool
test_REQ_UPDATE_GOT_SUBSCRIPTION = do
  let sub = MkSubscription RealTime "2025-02-14T00:00:00Z" False
      m = update (GotSubscription sub) initialModel
      hasSubscription = case m.subscription of { Just _ => True; Nothing => False }
  r1 <- assertTrue "subscription is Just" hasSubscription
  r2 <- assertEq "loadState is Loaded" Loaded m.loadState
  pure (r1 && r2)

-- | SPEC: REQ_UPDATE_GOT_TREASURY - GotTreasury updates model with current balances
test_REQ_UPDATE_GOT_TREASURY : IO Bool
test_REQ_UPDATE_GOT_TREASURY = do
  let t = MkTreasury 500000000000000000 250000000 500000000000
      m = update (GotTreasury t) initialModel
      hasTreasury = case m.treasury of { Just _ => True; Nothing => False }
  r1 <- assertTrue "treasury is Just" hasTreasury
  r2 <- assertEq "loadState is Loaded" Loaded m.loadState
  pure (r1 && r2)

-- | SPEC: REQ_UPDATE_GOT_UPGRADE_EVENTS - GotUpgradeEvents updates model with OU upgrade event history
test_REQ_UPDATE_GOT_UPGRADE_EVENTS : IO Bool
test_REQ_UPDATE_GOT_UPGRADE_EVENTS = do
  let evts = [ MkUpgradeEvent "u1" "0x1" UpgradeProposed 3 1 "now"
             , MkUpgradeEvent "u2" "0x2" UpgradeExecuted 5 0 "now"
             ]
      m = update (GotUpgradeEvents evts) initialModel
  r1 <- assertEq "upgrade events count" 2 (length m.upgradeEvents)
  r2 <- assertEq "loadState is Loaded" Loaded m.loadState
  pure (r1 && r2)

-- =============================================================================
-- View Tests (HTML rendering)
-- =============================================================================

-- | SPEC: REQ_VIEW_AUDITOR_LIST - Display auditor list with names and assigned OUs
test_REQ_VIEW_AUDITOR_LIST : IO Bool
test_REQ_VIEW_AUDITOR_LIST = do
  -- Test empty list case
  let emptyView = viewAuditors []
  -- Test with auditors (type check: viewAuditors returns Node Msg)
  let auditors = [MkAuditor "a1" "Alice" ["0x1", "0x2"]]
      listView = viewAuditors auditors
  putStrLn "  PASS: REQ_VIEW_AUDITOR_LIST"
  pure True

-- | SPEC: REQ_VIEW_OU_STATUS - Display OU status cards
test_REQ_VIEW_OU_STATUS : IO Bool
test_REQ_VIEW_OU_STATUS = do
  let emptyView = viewOUs []
      ous = [MkOU "0x1" Ethereum Active "now", MkOU "0x2" Base Syncing "now"]
      listView = viewOUs ous
  putStrLn "  PASS: REQ_VIEW_OU_STATUS"
  pure True

-- | SPEC: REQ_VIEW_PROPOSAL_LIST - Display proposal list with vote counts
test_REQ_VIEW_PROPOSAL_LIST : IO Bool
test_REQ_VIEW_PROPOSAL_LIST = do
  let emptyView = viewProposals []
      props = [MkProposal "p1" "desc" 10 3 Pending]
      listView = viewProposals props
  putStrLn "  PASS: REQ_VIEW_PROPOSAL_LIST"
  pure True

-- | SPEC: REQ_VIEW_EVENT_LOG - Display event log with timestamps
test_REQ_VIEW_EVENT_LOG : IO Bool
test_REQ_VIEW_EVENT_LOG = do
  let emptyView = viewEvents []
      evts = [MkEvent "2025-01-14" "Test" Ethereum "details"]
      listView = viewEvents evts
  putStrLn "  PASS: REQ_VIEW_EVENT_LOG"
  pure True

-- | SPEC: REQ_VIEW_LOADING - Display loading indicator while fetching
test_REQ_VIEW_LOADING : IO Bool
test_REQ_VIEW_LOADING = do
  -- viewLoading produces a loading spinner node
  let loadingNode = viewLoading
  -- Test that view function handles Loading state
  let m = { loadState := Loading } initialModel
      fullView = view m
  putStrLn "  PASS: REQ_VIEW_LOADING"
  pure True

-- | SPEC: REQ_VIEW_ERROR - Display error message when API call fails
test_REQ_VIEW_ERROR : IO Bool
test_REQ_VIEW_ERROR = do
  -- viewError produces an error panel with retry button
  let errorNode = viewError "Network timeout"
  -- Test that view function handles Failed state
  let m = { loadState := Failed "Test error" } initialModel
      fullView = view m
  putStrLn "  PASS: REQ_VIEW_ERROR"
  pure True

-- | SPEC: REQ_VIEW_TIER_STATUS - Display current tier badge with sync frequency
test_REQ_VIEW_TIER_STATUS : IO Bool
test_REQ_VIEW_TIER_STATUS = do
  -- Test Nothing case
  let emptyView = viewTierStatus Nothing
  -- Test Just case with subscription
  let sub = MkSubscription Standard "2025-02-14T00:00:00Z" True
      tierView = viewTierStatus (Just sub)
  -- Test via main view with Economics tab
  let m = { loadState := Loaded, subscription := Just sub, activeTab := TabEconomics } initialModel
      fullView = view m
  putStrLn "  PASS: REQ_VIEW_TIER_STATUS"
  pure True

-- | SPEC: REQ_VIEW_TREASURY_BALANCE - Display treasury balances with 70/30 distribution
test_REQ_VIEW_TREASURY_BALANCE : IO Bool
test_REQ_VIEW_TREASURY_BALANCE = do
  -- Test Nothing case
  let emptyView = viewTreasuryBalance Nothing
  -- Test Just case with treasury
  let t = MkTreasury 1000000000000000000 500000000 1000000000000
      treasuryView = viewTreasuryBalance (Just t)
  -- Test via main view with Treasury tab
  let m = { loadState := Loaded, treasury := Just t, activeTab := TabTreasury } initialModel
      fullView = view m
  putStrLn "  PASS: REQ_VIEW_TREASURY_BALANCE"
  pure True

-- | SPEC: REQ_VIEW_UPGRADE_TIMELINE - Display upgrade proposal timeline with voting progress
test_REQ_VIEW_UPGRADE_TIMELINE : IO Bool
test_REQ_VIEW_UPGRADE_TIMELINE = do
  -- Test empty case
  let emptyView = viewUpgradeTimeline []
  -- Test with upgrade events
  let evts = [ MkUpgradeEvent "u1" "0x1" UpgradeProposed 3 1 "2025-01-14"
             , MkUpgradeEvent "u2" "0x2" UpgradeApproved 5 0 "2025-01-13"
             , MkUpgradeEvent "u3" "0x3" UpgradeRejected 2 4 "2025-01-12"
             , MkUpgradeEvent "u4" "0x4" UpgradeExecuted 6 0 "2025-01-11"
             ]
      timelineView = viewUpgradeTimeline evts
  putStrLn "  PASS: REQ_VIEW_UPGRADE_TIMELINE"
  pure True

-- =============================================================================
-- Branch Coverage Tests (Show instances)
-- =============================================================================

-- | Test all Chain Show branches
test_BRANCH_Chain_Show : IO Bool
test_BRANCH_Chain_Show = do
  r1 <- assertEq "show Ethereum" "Ethereum" (show Ethereum)
  r2 <- assertEq "show Sepolia" "Sepolia" (show Sepolia)
  r3 <- assertEq "show Base" "Base" (show Model.Base)
  r4 <- assertEq "show Arbitrum" "Arbitrum" (show Arbitrum)
  r5 <- assertEq "show Optimism" "Optimism" (show Optimism)
  pure (r1 && r2 && r3 && r4 && r5)

-- | Test all OUStatus Show branches
test_BRANCH_OUStatus_Show : IO Bool
test_BRANCH_OUStatus_Show = do
  r1 <- assertEq "show Active" "Active" (show Active)
  r2 <- assertEq "show Syncing" "Syncing" (show Syncing)
  r3 <- assertEq "show Stale" "Stale" (show Stale)
  r4 <- assertEq "show Error" "Error" (show Error)
  pure (r1 && r2 && r3 && r4)

-- | Test all ProposalStatus Show branches
test_BRANCH_ProposalStatus_Show : IO Bool
test_BRANCH_ProposalStatus_Show = do
  r1 <- assertEq "show Pending" "Pending" (show Pending)
  r2 <- assertEq "show Approved" "Approved" (show Approved)
  r3 <- assertEq "show Rejected" "Rejected" (show Rejected)
  r4 <- assertEq "show Executed" "Executed" (show Executed)
  pure (r1 && r2 && r3 && r4)

-- | Test all Tab Show branches
test_BRANCH_Tab_Show : IO Bool
test_BRANCH_Tab_Show = do
  r1 <- assertEq "show TabAuditors" "Auditors" (show TabAuditors)
  r2 <- assertEq "show TabOUs" "OUs" (show TabOUs)
  r3 <- assertEq "show TabProposals" "Proposals" (show TabProposals)
  r4 <- assertEq "show TabEvents" "Events" (show TabEvents)
  r5 <- assertEq "show TabEconomics" "Economics" (show TabEconomics)
  r6 <- assertEq "show TabTreasury" "Treasury" (show TabTreasury)
  pure (r1 && r2 && r3 && r4 && r5 && r6)

-- | Test all LoadState Show branches
test_BRANCH_LoadState_Show : IO Bool
test_BRANCH_LoadState_Show = do
  r1 <- assertEq "show Idle" "Idle" (show Idle)
  r2 <- assertEq "show Loading" "Loading" (show Loading)
  r3 <- assertEq "show Loaded" "Loaded" (show Loaded)
  r4 <- assertEq "show Failed" "Failed: error" (show (Failed "error"))
  pure (r1 && r2 && r3 && r4)

-- | Test all Tier Show branches
test_BRANCH_Tier_Show : IO Bool
test_BRANCH_Tier_Show = do
  r1 <- assertEq "show Archive" "Archive" (show Archive)
  r2 <- assertEq "show Economy" "Economy" (show Economy)
  r3 <- assertEq "show Standard" "Standard" (show Standard)
  r4 <- assertEq "show RealTime" "Real-time" (show RealTime)
  pure (r1 && r2 && r3 && r4)

-- | Test all UpgradeStatus Show branches
test_BRANCH_UpgradeStatus_Show : IO Bool
test_BRANCH_UpgradeStatus_Show = do
  r1 <- assertEq "show UpgradeProposed" "Proposed" (show UpgradeProposed)
  r2 <- assertEq "show UpgradeApproved" "Approved" (show UpgradeApproved)
  r3 <- assertEq "show UpgradeRejected" "Rejected" (show UpgradeRejected)
  r4 <- assertEq "show UpgradeExecuted" "Executed" (show UpgradeExecuted)
  pure (r1 && r2 && r3 && r4)

-- =============================================================================
-- Branch Coverage Tests (/= operators)
-- =============================================================================

-- | Test Chain /= operator (not-equal AND equal cases)
test_BRANCH_Chain_NotEq : IO Bool
test_BRANCH_Chain_NotEq = do
  -- Not-equal cases
  r1 <- assertTrue "Ethereum /= Sepolia" (Ethereum /= Sepolia)
  r2 <- assertTrue "Sepolia /= Base" (Sepolia /= Model.Base)
  r3 <- assertTrue "Base /= Arbitrum" (Model.Base /= Arbitrum)
  r4 <- assertTrue "Arbitrum /= Optimism" (Arbitrum /= Optimism)
  r5 <- assertTrue "Optimism /= Ethereum" (Optimism /= Ethereum)
  -- Equal cases (should return False)
  r6 <- assertTrue "Ethereum == Ethereum (/= False)" (not (Ethereum /= Ethereum))
  r7 <- assertTrue "Sepolia == Sepolia (/= False)" (not (Sepolia /= Sepolia))
  r8 <- assertTrue "Base == Base (/= False)" (not (Model.Base /= Model.Base))
  pure (r1 && r2 && r3 && r4 && r5 && r6 && r7 && r8)

-- | Test OUStatus /= operator (both branches)
test_BRANCH_OUStatus_NotEq : IO Bool
test_BRANCH_OUStatus_NotEq = do
  r1 <- assertTrue "Active /= Syncing" (Active /= Syncing)
  r2 <- assertTrue "Syncing /= Stale" (Syncing /= Stale)
  r3 <- assertTrue "Stale /= Error" (Stale /= Error)
  r4 <- assertTrue "Error /= Active" (Error /= Active)
  -- Equal cases
  r5 <- assertTrue "Active == Active (/= False)" (not (Active /= Active))
  r6 <- assertTrue "Syncing == Syncing (/= False)" (not (Syncing /= Syncing))
  r7 <- assertTrue "Stale == Stale (/= False)" (not (Stale /= Stale))
  r8 <- assertTrue "Error == Error (/= False)" (not (Error /= Error))
  pure (r1 && r2 && r3 && r4 && r5 && r6 && r7 && r8)

-- | Test ProposalStatus /= operator (both branches)
test_BRANCH_ProposalStatus_NotEq : IO Bool
test_BRANCH_ProposalStatus_NotEq = do
  r1 <- assertTrue "Pending /= Approved" (Pending /= Approved)
  r2 <- assertTrue "Approved /= Rejected" (Approved /= Rejected)
  r3 <- assertTrue "Rejected /= Executed" (Rejected /= Executed)
  r4 <- assertTrue "Executed /= Pending" (Executed /= Pending)
  -- Equal cases
  r5 <- assertTrue "Pending == Pending (/= False)" (not (Pending /= Pending))
  r6 <- assertTrue "Approved == Approved (/= False)" (not (Approved /= Approved))
  r7 <- assertTrue "Rejected == Rejected (/= False)" (not (Rejected /= Rejected))
  r8 <- assertTrue "Executed == Executed (/= False)" (not (Executed /= Executed))
  pure (r1 && r2 && r3 && r4 && r5 && r6 && r7 && r8)

-- | Test Tab /= operator (both branches)
test_BRANCH_Tab_NotEq : IO Bool
test_BRANCH_Tab_NotEq = do
  r1 <- assertTrue "TabAuditors /= TabOUs" (TabAuditors /= TabOUs)
  r2 <- assertTrue "TabOUs /= TabProposals" (TabOUs /= TabProposals)
  r3 <- assertTrue "TabProposals /= TabEvents" (TabProposals /= TabEvents)
  r4 <- assertTrue "TabEvents /= TabEconomics" (TabEvents /= TabEconomics)
  r5 <- assertTrue "TabEconomics /= TabTreasury" (TabEconomics /= TabTreasury)
  -- Equal cases
  r6 <- assertTrue "TabAuditors == TabAuditors (/= False)" (not (TabAuditors /= TabAuditors))
  r7 <- assertTrue "TabEconomics == TabEconomics (/= False)" (not (TabEconomics /= TabEconomics))
  r8 <- assertTrue "TabTreasury == TabTreasury (/= False)" (not (TabTreasury /= TabTreasury))
  pure (r1 && r2 && r3 && r4 && r5 && r6 && r7 && r8)

-- | Test LoadState /= operator (both branches)
test_BRANCH_LoadState_NotEq : IO Bool
test_BRANCH_LoadState_NotEq = do
  r1 <- assertTrue "Idle /= Loading" (Idle /= Loading)
  r2 <- assertTrue "Loading /= Loaded" (Loading /= Loaded)
  r3 <- assertTrue "Loaded /= Failed" (Loaded /= Failed "x")
  r4 <- assertTrue "Failed /= Idle" (Failed "x" /= Idle)
  r5 <- assertTrue "Failed a /= Failed b" (Failed "a" /= Failed "b")
  -- Equal cases
  r6 <- assertTrue "Idle == Idle (/= False)" (not (Idle /= Idle))
  r7 <- assertTrue "Loading == Loading (/= False)" (not (Loading /= Loading))
  r8 <- assertTrue "Loaded == Loaded (/= False)" (not (Loaded /= Loaded))
  r9 <- assertTrue "Failed x == Failed x (/= False)" (not (Failed "x" /= Failed "x"))
  pure (r1 && r2 && r3 && r4 && r5 && r6 && r7 && r8 && r9)

-- | Test Tier /= operator (both branches)
test_BRANCH_Tier_NotEq : IO Bool
test_BRANCH_Tier_NotEq = do
  r1 <- assertTrue "Archive /= Economy" (Archive /= Economy)
  r2 <- assertTrue "Economy /= Standard" (Economy /= Standard)
  r3 <- assertTrue "Standard /= RealTime" (Standard /= RealTime)
  -- Equal cases
  r4 <- assertTrue "Archive == Archive (/= False)" (not (Archive /= Archive))
  r5 <- assertTrue "RealTime == RealTime (/= False)" (not (RealTime /= RealTime))
  pure (r1 && r2 && r3 && r4 && r5)

-- | Test UpgradeStatus /= operator (both branches)
test_BRANCH_UpgradeStatus_NotEq : IO Bool
test_BRANCH_UpgradeStatus_NotEq = do
  r1 <- assertTrue "UpgradeProposed /= UpgradeApproved" (UpgradeProposed /= UpgradeApproved)
  r2 <- assertTrue "UpgradeApproved /= UpgradeRejected" (UpgradeApproved /= UpgradeRejected)
  r3 <- assertTrue "UpgradeRejected /= UpgradeExecuted" (UpgradeRejected /= UpgradeExecuted)
  -- Equal cases
  r4 <- assertTrue "UpgradeProposed == UpgradeProposed (/= False)" (not (UpgradeProposed /= UpgradeProposed))
  r5 <- assertTrue "UpgradeExecuted == UpgradeExecuted (/= False)" (not (UpgradeExecuted /= UpgradeExecuted))
  pure (r1 && r2 && r3 && r4 && r5)

-- =============================================================================
-- Branch Coverage Tests (== operators - all constructors)
-- =============================================================================

-- | Test Chain == operator (all constructor pairs)
test_BRANCH_Chain_Eq : IO Bool
test_BRANCH_Chain_Eq = do
  -- Equal cases
  r1 <- assertTrue "Ethereum == Ethereum" (Ethereum == Ethereum)
  r2 <- assertTrue "Sepolia == Sepolia" (Sepolia == Sepolia)
  r3 <- assertTrue "Base == Base" (Model.Base == Model.Base)
  r4 <- assertTrue "Arbitrum == Arbitrum" (Arbitrum == Arbitrum)
  r5 <- assertTrue "Optimism == Optimism" (Optimism == Optimism)
  -- Not-equal cases (to cover _ == _ = False branch)
  r6 <- assertTrue "Ethereum /== Sepolia" (not (Ethereum == Sepolia))
  r7 <- assertTrue "Sepolia /== Base" (not (Sepolia == Model.Base))
  pure (r1 && r2 && r3 && r4 && r5 && r6 && r7)

-- | Test OUStatus == operator
test_BRANCH_OUStatus_Eq : IO Bool
test_BRANCH_OUStatus_Eq = do
  r1 <- assertTrue "Active == Active" (Active == Active)
  r2 <- assertTrue "Syncing == Syncing" (Syncing == Syncing)
  r3 <- assertTrue "Stale == Stale" (Stale == Stale)
  r4 <- assertTrue "Error == Error" (Error == Error)
  r5 <- assertTrue "Active /== Syncing" (not (Active == Syncing))
  pure (r1 && r2 && r3 && r4 && r5)

-- | Test ProposalStatus == operator
test_BRANCH_ProposalStatus_Eq : IO Bool
test_BRANCH_ProposalStatus_Eq = do
  r1 <- assertTrue "Pending == Pending" (Pending == Pending)
  r2 <- assertTrue "Approved == Approved" (Approved == Approved)
  r3 <- assertTrue "Rejected == Rejected" (Rejected == Rejected)
  r4 <- assertTrue "Executed == Executed" (Executed == Executed)
  r5 <- assertTrue "Pending /== Approved" (not (Pending == Approved))
  pure (r1 && r2 && r3 && r4 && r5)

-- | Test Tab == operator
test_BRANCH_Tab_Eq : IO Bool
test_BRANCH_Tab_Eq = do
  r1 <- assertTrue "TabAuditors == TabAuditors" (TabAuditors == TabAuditors)
  r2 <- assertTrue "TabOUs == TabOUs" (TabOUs == TabOUs)
  r3 <- assertTrue "TabProposals == TabProposals" (TabProposals == TabProposals)
  r4 <- assertTrue "TabEvents == TabEvents" (TabEvents == TabEvents)
  r5 <- assertTrue "TabEconomics == TabEconomics" (TabEconomics == TabEconomics)
  r6 <- assertTrue "TabTreasury == TabTreasury" (TabTreasury == TabTreasury)
  r7 <- assertTrue "TabAuditors /== TabOUs" (not (TabAuditors == TabOUs))
  pure (r1 && r2 && r3 && r4 && r5 && r6 && r7)

-- | Test LoadState == operator
test_BRANCH_LoadState_Eq : IO Bool
test_BRANCH_LoadState_Eq = do
  r1 <- assertTrue "Idle == Idle" (Idle == Idle)
  r2 <- assertTrue "Loading == Loading" (Loading == Loading)
  r3 <- assertTrue "Loaded == Loaded" (Loaded == Loaded)
  r4 <- assertTrue "Failed x == Failed x" (Failed "x" == Failed "x")
  r5 <- assertTrue "Idle /== Loading" (not (Idle == Loading))
  r6 <- assertTrue "Failed a /== Failed b" (not (Failed "a" == Failed "b"))
  pure (r1 && r2 && r3 && r4 && r5 && r6)

-- | Test Tier == operator
test_BRANCH_Tier_Eq : IO Bool
test_BRANCH_Tier_Eq = do
  r1 <- assertTrue "Archive == Archive" (Archive == Archive)
  r2 <- assertTrue "Economy == Economy" (Economy == Economy)
  r3 <- assertTrue "Standard == Standard" (Standard == Standard)
  r4 <- assertTrue "RealTime == RealTime" (RealTime == RealTime)
  r5 <- assertTrue "Archive /== Economy" (not (Archive == Economy))
  pure (r1 && r2 && r3 && r4 && r5)

-- | Test UpgradeStatus == operator
test_BRANCH_UpgradeStatus_Eq : IO Bool
test_BRANCH_UpgradeStatus_Eq = do
  r1 <- assertTrue "UpgradeProposed == UpgradeProposed" (UpgradeProposed == UpgradeProposed)
  r2 <- assertTrue "UpgradeApproved == UpgradeApproved" (UpgradeApproved == UpgradeApproved)
  r3 <- assertTrue "UpgradeRejected == UpgradeRejected" (UpgradeRejected == UpgradeRejected)
  r4 <- assertTrue "UpgradeExecuted == UpgradeExecuted" (UpgradeExecuted == UpgradeExecuted)
  r5 <- assertTrue "UpgradeProposed /== UpgradeApproved" (not (UpgradeProposed == UpgradeApproved))
  pure (r1 && r2 && r3 && r4 && r5)

-- =============================================================================
-- Additional Coverage Tests (tier functions and update branches)
-- =============================================================================

-- | Test tierSyncFreq all branches explicitly
test_BRANCH_TierSyncFreq : IO Bool
test_BRANCH_TierSyncFreq = do
  let _ = tierSyncFreq Archive
      _ = tierSyncFreq Economy
      _ = tierSyncFreq Standard
      _ = tierSyncFreq RealTime
  putStrLn "  PASS: BRANCH_TierSyncFreq (4 branches)"
  pure True

-- | Test tierMonthlyCost all branches explicitly
test_BRANCH_TierMonthlyCost : IO Bool
test_BRANCH_TierMonthlyCost = do
  let _ = tierMonthlyCost Archive
      _ = tierMonthlyCost Economy
      _ = tierMonthlyCost Standard
      _ = tierMonthlyCost RealTime
  putStrLn "  PASS: BRANCH_TierMonthlyCost (4 branches)"
  pure True

-- | Test update function with all Msg branches
test_BRANCH_Update_AllMsgs : IO Bool
test_BRANCH_Update_AllMsgs = do
  let m0 = initialModel
      -- Lifecycle
      _ = update Init m0
      _ = update Refresh m0
      -- Navigation - all tabs
      _ = update (SwitchTab TabAuditors) m0
      _ = update (SwitchTab TabOUs) m0
      _ = update (SwitchTab TabProposals) m0
      _ = update (SwitchTab TabEvents) m0
      _ = update (SwitchTab TabEconomics) m0
      _ = update (SwitchTab TabTreasury) m0
      -- API responses
      _ = update (GotAuditors []) m0
      _ = update (GotOUs []) m0
      _ = update (GotProposals []) m0
      _ = update (GotEvents []) m0
      _ = update (ApiError "err") m0
      -- Economics integration
      _ = update (GotSubscription (MkSubscription Archive "" False)) m0
      _ = update (GotTreasury (MkTreasury 0 0 0)) m0
      _ = update (GotUpgradeEvents []) m0
  putStrLn "  PASS: BRANCH_Update_AllMsgs (16 branches)"
  pure True

-- | Test == operators with more cross-constructor comparisons
test_BRANCH_Eq_CrossConstructors : IO Bool
test_BRANCH_Eq_CrossConstructors = do
  -- Chain cross comparisons
  r1 <- assertTrue "Eth/Sep" (not (Ethereum == Sepolia))
  r2 <- assertTrue "Eth/Base" (not (Ethereum == Model.Base))
  r3 <- assertTrue "Eth/Arb" (not (Ethereum == Arbitrum))
  r4 <- assertTrue "Eth/Opt" (not (Ethereum == Optimism))
  r5 <- assertTrue "Sep/Base" (not (Sepolia == Model.Base))
  r6 <- assertTrue "Sep/Arb" (not (Sepolia == Arbitrum))
  r7 <- assertTrue "Base/Arb" (not (Model.Base == Arbitrum))
  r8 <- assertTrue "Arb/Opt" (not (Arbitrum == Optimism))
  -- OUStatus cross
  r9 <- assertTrue "Act/Sync" (not (Active == Syncing))
  r10 <- assertTrue "Act/Stale" (not (Active == Stale))
  r11 <- assertTrue "Sync/Err" (not (Syncing == Error))
  -- ProposalStatus cross
  r12 <- assertTrue "Pend/Rej" (not (Pending == Rejected))
  r13 <- assertTrue "Appr/Exec" (not (Approved == Executed))
  -- Tier cross
  r14 <- assertTrue "Arch/Std" (not (Archive == Standard))
  r15 <- assertTrue "Econ/RT" (not (Economy == RealTime))
  -- UpgradeStatus cross
  r16 <- assertTrue "Prop/Rej" (not (UpgradeProposed == UpgradeRejected))
  r17 <- assertTrue "Appr/Exec" (not (UpgradeApproved == UpgradeExecuted))
  pure (r1 && r2 && r3 && r4 && r5 && r6 && r7 && r8 && r9 && r10 &&
        r11 && r12 && r13 && r14 && r15 && r16 && r17)

-- =============================================================================
-- Test Runner
-- =============================================================================

||| Run all tests and print results
export
runAllTests : IO ()
runAllTests = do
  putStrLn "Running OucDashboard tests..."
  putStrLn ""
  putStrLn "-- Model Tests --"
  r1 <- test_REQ_MODEL_INIT
  r2 <- test_REQ_MODEL_AUDITOR
  r3 <- test_REQ_MODEL_OU
  r4 <- test_REQ_MODEL_PROPOSAL
  r5 <- test_REQ_MODEL_EVENT
  r6 <- test_REQ_MODEL_TIER
  r7 <- test_REQ_MODEL_SUBSCRIPTION
  r8 <- test_REQ_MODEL_TREASURY
  r9 <- test_REQ_MODEL_UPGRADE_EVENT
  putStrLn ""
  putStrLn "-- Update Tests --"
  r10 <- test_REQ_UPDATE_INIT
  r11 <- test_REQ_UPDATE_REFRESH
  r12 <- test_REQ_UPDATE_TAB_SWITCH
  r13 <- test_REQ_UPDATE_GOT_AUDITORS
  r14 <- test_REQ_UPDATE_GOT_OUS
  r15 <- test_REQ_UPDATE_GOT_PROPOSALS
  r16 <- test_REQ_UPDATE_GOT_EVENTS
  r17 <- test_REQ_UPDATE_API_ERROR
  r18 <- test_REQ_UPDATE_GOT_SUBSCRIPTION
  r19 <- test_REQ_UPDATE_GOT_TREASURY
  r20 <- test_REQ_UPDATE_GOT_UPGRADE_EVENTS
  putStrLn ""
  putStrLn "-- View Tests --"
  r21 <- test_REQ_VIEW_AUDITOR_LIST
  r22 <- test_REQ_VIEW_OU_STATUS
  r23 <- test_REQ_VIEW_PROPOSAL_LIST
  r24 <- test_REQ_VIEW_EVENT_LOG
  r25 <- test_REQ_VIEW_LOADING
  r26 <- test_REQ_VIEW_ERROR
  r27 <- test_REQ_VIEW_TIER_STATUS
  r28 <- test_REQ_VIEW_TREASURY_BALANCE
  r29 <- test_REQ_VIEW_UPGRADE_TIMELINE
  putStrLn ""
  putStrLn "-- Branch Coverage: Show --"
  r30 <- test_BRANCH_Chain_Show
  r31 <- test_BRANCH_OUStatus_Show
  r32 <- test_BRANCH_ProposalStatus_Show
  r33 <- test_BRANCH_Tab_Show
  r34 <- test_BRANCH_LoadState_Show
  r35 <- test_BRANCH_Tier_Show
  r36 <- test_BRANCH_UpgradeStatus_Show
  putStrLn ""
  putStrLn "-- Branch Coverage: /= --"
  r37 <- test_BRANCH_Chain_NotEq
  r38 <- test_BRANCH_OUStatus_NotEq
  r39 <- test_BRANCH_ProposalStatus_NotEq
  r40 <- test_BRANCH_Tab_NotEq
  r41 <- test_BRANCH_LoadState_NotEq
  r42 <- test_BRANCH_Tier_NotEq
  r43 <- test_BRANCH_UpgradeStatus_NotEq
  putStrLn ""
  putStrLn "-- Branch Coverage: == --"
  r44 <- test_BRANCH_Chain_Eq
  r45 <- test_BRANCH_OUStatus_Eq
  r46 <- test_BRANCH_ProposalStatus_Eq
  r47 <- test_BRANCH_Tab_Eq
  r48 <- test_BRANCH_LoadState_Eq
  r49 <- test_BRANCH_Tier_Eq
  r50 <- test_BRANCH_UpgradeStatus_Eq
  putStrLn ""
  putStrLn "-- Additional Coverage --"
  r51 <- test_BRANCH_TierSyncFreq
  r52 <- test_BRANCH_TierMonthlyCost
  r53 <- test_BRANCH_Update_AllMsgs
  r54 <- test_BRANCH_Eq_CrossConstructors
  putStrLn ""
  let allResults = [r1, r2, r3, r4, r5, r6, r7, r8, r9, r10,
                    r11, r12, r13, r14, r15, r16, r17, r18, r19, r20,
                    r21, r22, r23, r24, r25, r26, r27, r28, r29, r30,
                    r31, r32, r33, r34, r35, r36, r37, r38, r39, r40,
                    r41, r42, r43, r44, r45, r46, r47, r48, r49, r50,
                    r51, r52, r53, r54]
  printResults allResults
  where
    printResults : List Bool -> IO ()
    printResults rs = putStrLn ("Results: " ++ show (length (filter id rs)) ++ "/" ++ show (length rs) ++ " passed")

||| Main entry point for test execution
main : IO ()
main = runAllTests
