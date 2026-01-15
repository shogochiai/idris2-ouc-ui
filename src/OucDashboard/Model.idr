module OucDashboard.Model

%default total

-- =============================================================================
-- Domain Types
-- =============================================================================

||| Chain identifier
public export
data Chain = Ethereum | Sepolia | Base | Arbitrum | Optimism

public export
Show Chain where
  show Ethereum = "Ethereum"
  show Sepolia  = "Sepolia"
  show Base     = "Base"
  show Arbitrum = "Arbitrum"
  show Optimism = "Optimism"

public export
Eq Chain where
  Ethereum == Ethereum = True
  Sepolia  == Sepolia  = True
  Base     == Base     = True
  Arbitrum == Arbitrum = True
  Optimism == Optimism = True
  _        == _        = False

||| OU sync status
public export
data OUStatus = Active | Syncing | Stale | Error

public export
Show OUStatus where
  show Active  = "Active"
  show Syncing = "Syncing"
  show Stale   = "Stale"
  show Error   = "Error"

public export
Eq OUStatus where
  Active  == Active  = True
  Syncing == Syncing = True
  Stale   == Stale   = True
  Error   == Error   = True
  _       == _       = False

||| Proposal status
public export
data ProposalStatus = Pending | Approved | Rejected | Executed

||| REQ_MODEL_TIER: Subscription tier with sync frequency and monthly cost
public export
data Tier = Archive | Economy | Standard | RealTime

public export
Show Tier where
  show Archive  = "Archive"
  show Economy  = "Economy"
  show Standard = "Standard"
  show RealTime = "Real-time"

public export
Eq Tier where
  Archive  == Archive  = True
  Economy  == Economy  = True
  Standard == Standard = True
  RealTime == RealTime = True
  _        == _        = False

||| Get sync frequency description for a tier
public export
tierSyncFreq : Tier -> String
tierSyncFreq Archive  = "1/day"
tierSyncFreq Economy  = "1/hour"
tierSyncFreq Standard = "1/15min"
tierSyncFreq RealTime = "1/min"

||| Get monthly cost (JPY) for a tier
public export
tierMonthlyCost : Tier -> Nat
tierMonthlyCost Archive  = 3
tierMonthlyCost Economy  = 80
tierMonthlyCost Standard = 300
tierMonthlyCost RealTime = 4500

||| Upgrade event status
public export
data UpgradeStatus = UpgradeProposed | UpgradeApproved | UpgradeRejected | UpgradeExecuted

public export
Show UpgradeStatus where
  show UpgradeProposed = "Proposed"
  show UpgradeApproved = "Approved"
  show UpgradeRejected = "Rejected"
  show UpgradeExecuted = "Executed"

public export
Eq UpgradeStatus where
  UpgradeProposed == UpgradeProposed = True
  UpgradeApproved == UpgradeApproved = True
  UpgradeRejected == UpgradeRejected = True
  UpgradeExecuted == UpgradeExecuted = True
  _               == _               = False

public export
Show ProposalStatus where
  show Pending  = "Pending"
  show Approved = "Approved"
  show Rejected = "Rejected"
  show Executed = "Executed"

public export
Eq ProposalStatus where
  Pending  == Pending  = True
  Approved == Approved = True
  Rejected == Rejected = True
  Executed == Executed = True
  _        == _        = False

-- =============================================================================
-- Entity Types (REQ_MODEL_*)
-- =============================================================================

||| Auditor entity
||| REQ_MODEL_AUDITOR: has id, name, and assigned OU list
public export
record Auditor where
  constructor MkAuditor
  auditorId   : String
  name        : String
  assignedOUs : List String  -- OU addresses

||| Observable Unit entity
||| REQ_MODEL_OU: has address, chain, status, and last sync time
public export
record OU where
  constructor MkOU
  address      : String
  chain        : Chain
  status       : OUStatus
  lastSyncTime : String  -- ISO 8601 timestamp

||| Proposal entity
||| REQ_MODEL_PROPOSAL: has id, description, votes for/against, and status
public export
record Proposal where
  constructor MkProposal
  proposalId  : String
  description : String
  votesFor    : Nat
  votesAgainst: Nat
  status      : ProposalStatus

||| Event entity
||| REQ_MODEL_EVENT: has timestamp, event type, chain, and details
public export
record Event where
  constructor MkEvent
  timestamp : String
  eventType : String
  chain     : Chain
  details   : String

||| REQ_MODEL_SUBSCRIPTION: Subscription with current tier, expiry, and auto-renew
public export
record Subscription where
  constructor MkSubscription
  currentTier : Tier
  expiryDate  : String  -- ISO 8601
  autoRenew   : Bool

||| REQ_MODEL_TREASURY: Treasury balances (ckETH, ICP, Cycles)
public export
record Treasury where
  constructor MkTreasury
  ckEthBalance  : Nat    -- in wei (smallest unit)
  icpBalance    : Nat    -- in e8s (smallest unit)
  cyclesBalance : Nat    -- cycles

||| REQ_MODEL_UPGRADE_EVENT: Upgrade event with status and voting progress
public export
record UpgradeEvent where
  constructor MkUpgradeEvent
  upgradeId   : String
  ouAddress   : String
  status      : UpgradeStatus
  votesFor    : Nat
  votesAgainst: Nat
  timestamp   : String

-- =============================================================================
-- UI State
-- =============================================================================

||| Active tab in the dashboard
public export
data Tab = TabAuditors | TabOUs | TabProposals | TabEvents | TabEconomics | TabTreasury

public export
Show Tab where
  show TabAuditors  = "Auditors"
  show TabOUs       = "OUs"
  show TabProposals = "Proposals"
  show TabEvents    = "Events"
  show TabEconomics = "Economics"
  show TabTreasury  = "Treasury"

public export
Eq Tab where
  TabAuditors  == TabAuditors  = True
  TabOUs       == TabOUs       = True
  TabProposals == TabProposals = True
  TabEvents    == TabEvents    = True
  TabEconomics == TabEconomics = True
  TabTreasury  == TabTreasury  = True
  _            == _            = False

||| Loading state for API calls
public export
data LoadState = Idle | Loading | Loaded | Failed String

||| REQ_MODEL_AUTH: Authentication state for Internet Identity
public export
data AuthState = NotAuthenticated | Authenticating | Authenticated String

public export
Show AuthState where
  show NotAuthenticated    = "Not Authenticated"
  show Authenticating      = "Authenticating..."
  show (Authenticated pid) = "Authenticated: " ++ pid

public export
Eq AuthState where
  NotAuthenticated    == NotAuthenticated    = True
  Authenticating      == Authenticating      = True
  (Authenticated a)   == (Authenticated b)   = a == b
  _                   == _                   = False

public export
Show LoadState where
  show Idle       = "Idle"
  show Loading    = "Loading"
  show Loaded     = "Loaded"
  show (Failed s) = "Failed: " ++ s

public export
Eq LoadState where
  Idle       == Idle       = True
  Loading    == Loading    = True
  Loaded     == Loaded     = True
  (Failed a) == (Failed b) = a == b
  _          == _          = False

-- =============================================================================
-- Application Model
-- =============================================================================

||| Application state
||| REQ_MODEL_INIT: Initial model has empty lists and Loading state
public export
record Model where
  constructor MkModel
  activeTab     : Tab
  loadState     : LoadState
  authState     : AuthState
  auditors      : List Auditor
  ous           : List OU
  proposals     : List Proposal
  events        : List Event
  subscription  : Maybe Subscription
  treasury      : Maybe Treasury
  upgradeEvents : List UpgradeEvent

||| Initial model with empty data
export
initialModel : Model
initialModel = MkModel
  { activeTab     = TabOUs
  , loadState     = Idle
  , authState     = NotAuthenticated
  , auditors      = []
  , ous           = []
  , proposals     = []
  , events        = []
  , subscription  = Nothing
  , treasury      = Nothing
  , upgradeEvents = []
  }
