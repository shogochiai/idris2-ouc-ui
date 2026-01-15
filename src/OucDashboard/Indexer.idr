module OucDashboard.Indexer

import JS
import OucDashboard.Model

%default covering

-- =============================================================================
-- FFI Bindings for ICP Indexer API (window.oucIndexer)
-- =============================================================================

%foreign "javascript:lambda:() => window.oucIndexer ? window.oucIndexer.fetchAuditors() : Promise.resolve([])"
prim__fetchAuditors : PrimIO AnyPtr

%foreign "javascript:lambda:() => window.oucIndexer ? window.oucIndexer.fetchSubscription() : Promise.resolve(null)"
prim__fetchSubscription : PrimIO AnyPtr

%foreign "javascript:lambda:() => window.oucIndexer ? window.oucIndexer.fetchTreasury() : Promise.resolve(null)"
prim__fetchTreasury : PrimIO AnyPtr

%foreign "javascript:lambda:(limit) => window.oucIndexer ? window.oucIndexer.fetchEvents({limit: limit}) : Promise.resolve({events:[]})"
prim__fetchEvents : Int -> PrimIO AnyPtr

%foreign "javascript:lambda:() => window.oucIndexer ? window.oucIndexer.fetchDashboardData() : Promise.resolve({auditors:[],events:{events:[]},subscription:null,treasury:null})"
prim__fetchDashboardData : PrimIO AnyPtr

-- =============================================================================
-- Promise and JSON Handling
-- =============================================================================

%foreign "javascript:lambda:(p, f) => p.then(x => f(x)()).catch(e => { console.error(e); f(null)(); })"
prim__thenPromise : AnyPtr -> (AnyPtr -> PrimIO ()) -> PrimIO ()

%foreign "javascript:lambda:x => x === null || x === undefined"
prim__isNull : AnyPtr -> Bool

%foreign "javascript:lambda:x => JSON.stringify(x)"
prim__toJsonString : AnyPtr -> String

%foreign "javascript:lambda:x => Array.isArray(x) ? x.length : 0"
prim__arrayLength : AnyPtr -> AnyPtr

%foreign "javascript:lambda:(arr, i) => arr[i]"
prim__arrayGet : AnyPtr -> Int -> AnyPtr

%foreign "javascript:lambda:(obj, key) => obj && obj[key] !== undefined ? obj[key] : null"
prim__getField : AnyPtr -> String -> AnyPtr

%foreign "javascript:lambda:x => typeof x === 'number' ? x : (parseInt(x) || 0)"
prim__toInt : AnyPtr -> Int

%foreign "javascript:lambda:x => typeof x === 'string' ? x : String(x || '')"
prim__toString : AnyPtr -> String

%foreign "javascript:lambda:x => x === true || x === 'true'"
prim__toBool : AnyPtr -> Bool

-- =============================================================================
-- JSON Parsing Helpers
-- =============================================================================

||| Parse a single auditor from JSON object
parseAuditor : AnyPtr -> Auditor
parseAuditor obj =
  let auditorId = prim__toString (prim__getField obj "auditorId")
      name = prim__toString (prim__getField obj "name")
      ousPtr = prim__getField obj "assignedOUs"
      ousLen = prim__toInt (prim__arrayLength ousPtr)
      ous = parseStringArray ousPtr ousLen 0 []
  in MkAuditor auditorId name ous
  where
    parseStringArray : AnyPtr -> Int -> Int -> List String -> List String
    parseStringArray arr len idx acc =
      if idx >= len then reverse acc
      else parseStringArray arr len (idx + 1) (prim__toString (prim__arrayGet arr idx) :: acc)

||| Parse auditor list from JSON array
parseAuditors : AnyPtr -> List Auditor
parseAuditors arr =
  let len = prim__toInt (prim__arrayLength arr)
  in parseAuditorsLoop arr len 0 []
  where
    parseAuditorsLoop : AnyPtr -> Int -> Int -> List Auditor -> List Auditor
    parseAuditorsLoop arr len idx acc =
      if idx >= len then reverse acc
      else parseAuditorsLoop arr len (idx + 1) (parseAuditor (prim__arrayGet arr idx) :: acc)

||| Parse tier from string
parseTier : String -> Tier
parseTier "Archive"  = Archive
parseTier "Economy"  = Economy
parseTier "Standard" = Standard
parseTier "RealTime" = RealTime
parseTier _          = Economy  -- Default

||| Parse subscription from JSON object
parseSubscription : AnyPtr -> Maybe Subscription
parseSubscription obj =
  if prim__isNull obj then Nothing
  else
    let tierStr = prim__toString (prim__getField obj "currentTier")
        expiry = prim__toString (prim__getField obj "expiryDate")
        autoRenew = prim__toBool (prim__getField obj "autoRenew")
    in Just (MkSubscription (parseTier tierStr) expiry autoRenew)

||| Parse treasury from JSON object
parseTreasury : AnyPtr -> Maybe Treasury
parseTreasury obj =
  if prim__isNull obj then Nothing
  else
    let ckEth = cast {to=Nat} (prim__toInt (prim__getField obj "ckEthBalance"))
        icp = cast {to=Nat} (prim__toInt (prim__getField obj "icpBalance"))
        cycles = cast {to=Nat} (prim__toInt (prim__getField obj "cyclesBalance"))
    in Just (MkTreasury ckEth icp cycles)

||| Parse chain from chainId number
parseChain : Int -> Chain
parseChain 1     = Ethereum
parseChain 11155111 = Sepolia
parseChain 8453  = Base
parseChain 42161 = Arbitrum
parseChain 10    = Optimism
parseChain _     = Ethereum  -- Default

||| Parse a single event from JSON object
parseEvent : AnyPtr -> Event
parseEvent obj =
  let timestamp = prim__toString (prim__getField obj "timestamp")
      eventType = prim__toString (prim__getField obj "topic0")
      chainId = prim__toInt (prim__getField obj "chainId")
      details = prim__toString (prim__getField obj "data")
  in MkEvent timestamp eventType (parseChain chainId) details

||| Parse events from response object
parseEvents : AnyPtr -> List Event
parseEvents resp =
  let eventsArr = prim__getField resp "events"
      len = prim__toInt (prim__arrayLength eventsArr)
  in parseEventsLoop eventsArr len 0 []
  where
    parseEventsLoop : AnyPtr -> Int -> Int -> List Event -> List Event
    parseEventsLoop arr len idx acc =
      if idx >= len then reverse acc
      else parseEventsLoop arr len (idx + 1) (parseEvent (prim__arrayGet arr idx) :: acc)

-- =============================================================================
-- High-Level API
-- =============================================================================

||| Fetch auditors from Indexer
export
fetchAuditors : (List Auditor -> IO ()) -> IO ()
fetchAuditors callback = do
  promise <- primIO prim__fetchAuditors
  primIO $ prim__thenPromise promise $ \result => toPrim $ do
    if prim__isNull result
      then callback []
      else callback (parseAuditors result)

||| Fetch subscription from Indexer
export
fetchSubscription : (Maybe Subscription -> IO ()) -> IO ()
fetchSubscription callback = do
  promise <- primIO prim__fetchSubscription
  primIO $ prim__thenPromise promise $ \result => toPrim $ do
    callback (parseSubscription result)

||| Fetch treasury from Indexer
export
fetchTreasury : (Maybe Treasury -> IO ()) -> IO ()
fetchTreasury callback = do
  promise <- primIO prim__fetchTreasury
  primIO $ prim__thenPromise promise $ \result => toPrim $ do
    callback (parseTreasury result)

||| Fetch events from Indexer (limited)
export
fetchEvents : Nat -> (List Event -> IO ()) -> IO ()
fetchEvents limit callback = do
  promise <- primIO $ prim__fetchEvents (cast limit)
  primIO $ prim__thenPromise promise $ \result => toPrim $ do
    if prim__isNull result
      then callback []
      else callback (parseEvents result)

||| Result type for dashboard data fetch
public export
record DashboardData where
  constructor MkDashboardData
  auditors     : List Auditor
  events       : List Event
  subscription : Maybe Subscription
  treasury     : Maybe Treasury

||| Fetch all dashboard data in one call
export
fetchDashboardData : (DashboardData -> IO ()) -> IO ()
fetchDashboardData callback = do
  promise <- primIO prim__fetchDashboardData
  primIO $ prim__thenPromise promise $ \result => toPrim $ do
    if prim__isNull result
      then callback (MkDashboardData [] [] Nothing Nothing)
      else do
        let auditors = parseAuditors (prim__getField result "auditors")
        let events = parseEvents (prim__getField result "events")
        let subscription = parseSubscription (prim__getField result "subscription")
        let treasury = parseTreasury (prim__getField result "treasury")
        callback (MkDashboardData auditors events subscription treasury)
