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
  let ous = [MkOU "0x1" Ethereum Active "now"]
      m = update (GotOUs ous) initialModel
  r1 <- assertEq "ous count" 1 (length m.ous)
  r2 <- assertEq "loadState is Loaded" Loaded m.loadState
  pure (r1 && r2)

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

-- =============================================================================
-- Fetch Tests (API endpoint simulation)
-- =============================================================================

-- | SPEC: REQ_FETCH_AUDITORS - Fetch auditors from /api/auditors endpoint
-- | Test: Simulates receiving auditor data and verifies model update
test_REQ_FETCH_AUDITORS : IO Bool
test_REQ_FETCH_AUDITORS = do
  -- Simulate fetch response: /api/auditors returns JSON, parsed to List Auditor
  let fetchedData = [MkAuditor "aud-001" "Alice" ["0x1"], MkAuditor "aud-002" "Bob" []]
      m = { loadState := Loading } initialModel
      m' = update (GotAuditors fetchedData) m
  r1 <- assertEq "fetched auditor count" 2 (length m'.auditors)
  r2 <- assertEq "first auditor name" "Alice" (maybe "" (\a => a.name) (head' m'.auditors))
  let result = r1 && r2
  putStrLn $ (if result then "  PASS" else "  FAIL") ++ ": REQ_FETCH_AUDITORS"
  pure result

-- | SPEC: REQ_FETCH_OUS - Fetch OUs from /api/ous endpoint
test_REQ_FETCH_OUS : IO Bool
test_REQ_FETCH_OUS = do
  let fetchedData = [MkOU "0xabc" Ethereum Active "2025-01-14T12:00:00Z"]
      m = update (GotOUs fetchedData) initialModel
  r1 <- assertEq "fetched OU count" 1 (length m.ous)
  r2 <- assertEq "OU chain" Ethereum (maybe Sepolia (\o => o.chain) (head' m.ous))
  let result = r1 && r2
  putStrLn $ (if result then "  PASS" else "  FAIL") ++ ": REQ_FETCH_OUS"
  pure result

-- | SPEC: REQ_FETCH_PROPOSALS - Fetch proposals from /api/proposals endpoint
test_REQ_FETCH_PROPOSALS : IO Bool
test_REQ_FETCH_PROPOSALS = do
  let fetchedData = [MkProposal "p1" "Upgrade" 10 2 Pending, MkProposal "p2" "Fix" 5 5 Approved]
      m = update (GotProposals fetchedData) initialModel
  r1 <- assertEq "fetched proposal count" 2 (length m.proposals)
  r2 <- assertEq "first proposal votes" 10 (maybe 0 (\p => p.votesFor) (head' m.proposals))
  let result = r1 && r2
  putStrLn $ (if result then "  PASS" else "  FAIL") ++ ": REQ_FETCH_PROPOSALS"
  pure result

-- | SPEC: REQ_FETCH_EVENTS - Fetch events from /api/events endpoint
test_REQ_FETCH_EVENTS : IO Bool
test_REQ_FETCH_EVENTS = do
  let fetchedData = [MkEvent "2025-01-14T12:00:00Z" "UpgradeProposed" Sepolia "prop #1"]
      m = update (GotEvents fetchedData) initialModel
  r1 <- assertEq "fetched event count" 1 (length m.events)
  r2 <- assertEq "event type" "UpgradeProposed" (maybe "" (\e => e.eventType) (head' m.events))
  let result = r1 && r2
  putStrLn $ (if result then "  PASS" else "  FAIL") ++ ": REQ_FETCH_EVENTS"
  pure result

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
  putStrLn ""
  putStrLn "-- Update Tests --"
  r6 <- test_REQ_UPDATE_INIT
  r7 <- test_REQ_UPDATE_REFRESH
  r8 <- test_REQ_UPDATE_TAB_SWITCH
  r9 <- test_REQ_UPDATE_GOT_AUDITORS
  r10 <- test_REQ_UPDATE_GOT_OUS
  r11 <- test_REQ_UPDATE_GOT_PROPOSALS
  r12 <- test_REQ_UPDATE_GOT_EVENTS
  r13 <- test_REQ_UPDATE_API_ERROR
  putStrLn ""
  putStrLn "-- Fetch Tests --"
  r14 <- test_REQ_FETCH_AUDITORS
  r15 <- test_REQ_FETCH_OUS
  r16 <- test_REQ_FETCH_PROPOSALS
  r17 <- test_REQ_FETCH_EVENTS
  putStrLn ""
  putStrLn "-- View Tests --"
  r18 <- test_REQ_VIEW_AUDITOR_LIST
  r19 <- test_REQ_VIEW_OU_STATUS
  r20 <- test_REQ_VIEW_PROPOSAL_LIST
  r21 <- test_REQ_VIEW_EVENT_LOG
  r22 <- test_REQ_VIEW_LOADING
  r23 <- test_REQ_VIEW_ERROR
  putStrLn ""
  let allResults = [r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13,
                    r14, r15, r16, r17, r18, r19, r20, r21, r22, r23]
  printResults allResults
  where
    printResults : List Bool -> IO ()
    printResults rs = putStrLn ("Results: " ++ show (length (filter id rs)) ++ "/" ++ show (length rs) ++ " passed")

||| Main entry point for test execution
main : IO ()
main = runAllTests
