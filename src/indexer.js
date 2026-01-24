// OUC Canister API Client
// Called from Idris2 via FFI
// Uses @dfinity/agent for Candid calls to OUC canister

import { Actor, HttpAgent } from "@dfinity/agent";

// OUC Canister ID (local: lqy7q-dh777-77777-aaaaq-cai, IC mainnet: nrkou-hqaaa-aaaah-qq6qa-cai)
const OUC_CANISTER_ID = typeof window !== 'undefined' && window.OUC_CANISTER_ID
  ? window.OUC_CANISTER_ID
  : "lqy7q-dh777-77777-aaaaq-cai";  // Default to local

// Legacy: Indexer HTTP API (for backwards compatibility)
const INDEXER_CANISTER_ID = "bkyz2-fmaaa-aaaaa-qaaaq-cai";

// OUC Candid Interface (IDL)
const oucIdlFactory = ({ IDL }) => {
  return IDL.Service({
    // Indexer Integration (5.3.1) - returns JSON text
    getAuditors: IDL.Func([], [IDL.Text], ['query']),
    getSubscription: IDL.Func([], [IDL.Text], ['query']),
    getTreasury: IDL.Func([], [IDL.Text], ['query']),
    // Indexer Query Methods (CMD 30-33)
    getOucEvents: IDL.Func([IDL.Nat], [IDL.Nat], ['query']),
    getProposalEvents: IDL.Func([IDL.Nat], [IDL.Nat], ['query']),
    getDashboardSummary: IDL.Func([], [IDL.Nat], ['query']),
    storeTestEvent: IDL.Func([IDL.Nat, IDL.Nat], [IDL.Nat], []),
    // Original Query Methods
    getVersion: IDL.Func([], [IDL.Nat], ['query']),
    getProposalCount: IDL.Func([], [IDL.Nat], ['query']),
    getAuditorCount: IDL.Func([], [IDL.Nat], ['query']),
  });
};

// Create agent and actor
let agent = null;
let oucActor = null;

// Detect if running on IC mainnet or local
function isMainnet() {
  return typeof window !== 'undefined' && window.location?.hostname?.endsWith('.ic0.app');
}

async function getOucActor() {
  // For local development, always create fresh actor to handle dfx restarts
  if (!isMainnet()) {
    const host = "http://localhost:4943";
    const freshAgent = new HttpAgent({ host });
    await freshAgent.fetchRootKey().catch(e => console.warn("fetchRootKey failed:", e));
    return Actor.createActor(oucIdlFactory, {
      agent: freshAgent,
      canisterId: OUC_CANISTER_ID,
    });
  }

  // For mainnet, cache the actor
  if (oucActor) return oucActor;

  agent = new HttpAgent({ host: "https://ic0.app" });

  oucActor = Actor.createActor(oucIdlFactory, {
    agent,
    canisterId: OUC_CANISTER_ID,
  });

  return oucActor;
}

// Build base URL for Indexer HTTP API (legacy)
function getBaseUrl() {
  if (isMainnet()) {
    return `https://${INDEXER_CANISTER_ID}.raw.ic0.app`;
  }
  return `http://${INDEXER_CANISTER_ID}.localhost:4943`;
}

// Generic fetch helper with error handling (legacy HTTP API)
async function fetchJson(path) {
  const url = `${getBaseUrl()}${path}`;
  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return await response.json();
  } catch (err) {
    console.error(`Fetch error for ${path}:`, err);
    throw err;
  }
}

// =============================================================================
// OUC Candid APIs (Direct canister calls)
// =============================================================================

// Fetch OUC events count via Candid
export async function fetchOucEventsCount(limit = 10) {
  try {
    const actor = await getOucActor();
    const count = await actor.getOucEvents(BigInt(limit));
    return { eventCount: Number(count) };
  } catch (err) {
    console.error("OUC getOucEvents error:", err);
    throw err;
  }
}

// Fetch proposal events count via Candid
export async function fetchProposalEventsCount(proposalId) {
  try {
    const actor = await getOucActor();
    const count = await actor.getProposalEvents(BigInt(proposalId));
    return { eventCount: Number(count) };
  } catch (err) {
    console.error("OUC getProposalEvents error:", err);
    throw err;
  }
}

// Fetch dashboard summary via Candid
export async function fetchDashboardSummaryFromOuc() {
  try {
    const actor = await getOucActor();
    const totalEvents = await actor.getDashboardSummary();
    const proposalCount = await actor.getProposalCount();
    const auditorCount = await actor.getAuditorCount();
    return {
      totalEventCount: Number(totalEvents),
      proposalCount: Number(proposalCount),
      auditorCount: Number(auditorCount)
    };
  } catch (err) {
    console.error("OUC getDashboardSummary error:", err);
    throw err;
  }
}

// Store test event via Candid (for testing)
export async function storeTestEvent(blockNumber, eventType) {
  try {
    const actor = await getOucActor();
    const newCount = await actor.storeTestEvent(BigInt(blockNumber), BigInt(eventType));
    return { newEventCount: Number(newCount) };
  } catch (err) {
    console.error("OUC storeTestEvent error:", err);
    throw err;
  }
}

// =============================================================================
// Legacy Event APIs (HTTP to Indexer)
// =============================================================================

// Fetch events with optional filters (legacy HTTP)
export async function fetchEvents(params = {}) {
  const query = new URLSearchParams();
  if (params.contract) query.set("contract", params.contract);
  if (params.topic) query.set("topic", params.topic);
  if (params.chain) query.set("chain", params.chain);
  if (params.from) query.set("from", params.from);
  if (params.to) query.set("to", params.to);
  if (params.cursor) query.set("cursor", params.cursor);
  if (params.limit) query.set("limit", params.limit);

  const queryStr = query.toString();
  const path = queryStr ? `/events?${queryStr}` : "/events";
  return await fetchJson(path);
}

// Fetch single event by ID (legacy HTTP)
export async function fetchEventById(eventId) {
  return await fetchJson(`/events/${eventId}`);
}

// Fetch indexer stats (legacy HTTP)
export async function fetchStats() {
  return await fetchJson("/stats");
}

// Fetch health status (legacy HTTP)
export async function fetchHealth() {
  return await fetchJson("/health");
}

// =============================================================================
// OUC APIs (synced from OUC Canister)
// =============================================================================

// Fetch all auditors from OUC Canister via Candid
export async function fetchAuditors() {
  try {
    const actor = await getOucActor();
    const jsonText = await actor.getAuditors();
    return JSON.parse(jsonText);
  } catch (err) {
    console.error("OUC getAuditors error:", err);
    return [];
  }
}

// Fetch single auditor by ID (filter from list)
export async function fetchAuditorById(auditorId) {
  const auditors = await fetchAuditors();
  return auditors.find(a => a.auditorId === auditorId) || null;
}

// Fetch subscription info from OUC Canister via Candid
export async function fetchSubscription() {
  try {
    const actor = await getOucActor();
    const jsonText = await actor.getSubscription();
    return JSON.parse(jsonText);
  } catch (err) {
    console.error("OUC getSubscription error:", err);
    return null;
  }
}

// Fetch treasury balances from OUC Canister via Candid
export async function fetchTreasury() {
  try {
    const actor = await getOucActor();
    const jsonText = await actor.getTreasury();
    return JSON.parse(jsonText);
  } catch (err) {
    console.error("OUC getTreasury error:", err);
    return null;
  }
}

// Fetch OUC sync status (placeholder)
export async function fetchOucStatus() {
  return { status: "ok", lastSync: new Date().toISOString() };
}

// =============================================================================
// Tier Management APIs (write operations via Indexer → OUC)
// =============================================================================

// Request tier change (Indexer forwards to OUC canister)
export async function changeTier(newTier) {
  const url = `${getBaseUrl()}/subscription/tier`;
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ tier: newTier })
    });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return await response.json();
  } catch (err) {
    console.error("Tier change error:", err);
    throw err;
  }
}

// Toggle auto-renew setting
export async function setAutoRenew(enabled) {
  const url = `${getBaseUrl()}/subscription/auto-renew`;
  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ autoRenew: enabled })
    });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    return await response.json();
  } catch (err) {
    console.error("Auto-renew toggle error:", err);
    throw err;
  }
}

// =============================================================================
// Aggregated fetch for dashboard initialization
// =============================================================================

// Fetch all dashboard data in parallel
export async function fetchDashboardData() {
  const results = await Promise.allSettled([
    fetchAuditors(),
    // Skip fetchEvents - legacy HTTP API not available, use empty array
    Promise.resolve({ events: [] }),
    fetchSubscription(),
    fetchTreasury(),
    fetchOucStatus()
  ]);

  return {
    auditors: results[0].status === "fulfilled" ? results[0].value : [],
    events: results[1].status === "fulfilled" ? results[1].value : { events: [] },
    subscription: results[2].status === "fulfilled" ? results[2].value : null,
    treasury: results[3].status === "fulfilled" ? results[3].value : null,
    oucStatus: results[4].status === "fulfilled" ? results[4].value : null
  };
}

// =============================================================================
// Real-time Monitoring (Polling)
// =============================================================================

let pollingInterval = null;
let lastEventIds = new Set();

// Start periodic polling
export function startPolling(intervalMs, callback) {
  if (pollingInterval) {
    clearInterval(pollingInterval);
  }

  pollingInterval = setInterval(async () => {
    try {
      const data = await fetchDashboardData();
      callback(data);
    } catch (err) {
      console.error("Polling error:", err);
    }
  }, intervalMs);

  // Immediate first poll
  fetchDashboardData().then(callback).catch(console.error);
}

// Stop polling
export function stopPolling() {
  if (pollingInterval) {
    clearInterval(pollingInterval);
    pollingInterval = null;
  }
}

// Detect new events (returns events not seen before)
export function detectNewEvents(events) {
  const newEvents = [];
  const currentIds = new Set();

  for (const event of events) {
    const id = event.eventId || `${event.txHash}-${event.logIndex}`;
    currentIds.add(id);
    if (!lastEventIds.has(id)) {
      newEvents.push(event);
    }
  }

  lastEventIds = currentIds;
  return newEvents;
}

// Get polling status
export function isPolling() {
  return pollingInterval !== null;
}

// =============================================================================
// Expose to global scope for Idris2 FFI
// =============================================================================

if (typeof window !== 'undefined') {
  window.oucIndexer = {
    // OUC Candid APIs (new)
    fetchOucEventsCount,
    fetchProposalEventsCount,
    fetchDashboardSummaryFromOuc,
    storeTestEvent,
    // Legacy Query APIs (HTTP)
    fetchEvents,
    fetchEventById,
    fetchStats,
    fetchHealth,
    fetchAuditors,
    fetchAuditorById,
    fetchSubscription,
    fetchTreasury,
    fetchOucStatus,
    fetchDashboardData,
    // Write APIs
    changeTier,
    setAutoRenew,
    // Polling APIs
    startPolling,
    stopPolling,
    detectNewEvents,
    isPolling
  };
}
