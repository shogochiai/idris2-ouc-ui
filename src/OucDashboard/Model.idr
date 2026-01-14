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

-- =============================================================================
-- UI State
-- =============================================================================

||| Active tab in the dashboard
public export
data Tab = TabAuditors | TabOUs | TabProposals | TabEvents

public export
Show Tab where
  show TabAuditors  = "Auditors"
  show TabOUs       = "OUs"
  show TabProposals = "Proposals"
  show TabEvents    = "Events"

public export
Eq Tab where
  TabAuditors  == TabAuditors  = True
  TabOUs       == TabOUs       = True
  TabProposals == TabProposals = True
  TabEvents    == TabEvents    = True
  _            == _            = False

||| Loading state for API calls
public export
data LoadState = Idle | Loading | Loaded | Failed String

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
  activeTab   : Tab
  loadState   : LoadState
  auditors    : List Auditor
  ous         : List OU
  proposals   : List Proposal
  events      : List Event

||| Initial model with empty data
export
initialModel : Model
initialModel = MkModel
  { activeTab   = TabOUs
  , loadState   = Idle
  , auditors    = []
  , ous         = []
  , proposals   = []
  , events      = []
  }
