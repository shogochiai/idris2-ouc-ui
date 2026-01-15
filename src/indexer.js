// ICP Indexer API Client
// Called from Idris2 via FFI

// Indexer canister ID (configurable via environment)
const INDEXER_CANISTER_ID = process.env.INDEXER_CANISTER_ID || "bkyz2-fmaaa-aaaaa-qaaaq-cai";

// Build base URL for Indexer HTTP API
function getBaseUrl() {
  if (process.env.DFX_NETWORK === "ic") {
    return `https://${INDEXER_CANISTER_ID}.raw.ic0.app`;
  }
  return `http://${INDEXER_CANISTER_ID}.localhost:4943`;
}

// Generic fetch helper with error handling
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
// Event APIs
// =============================================================================

// Fetch events with optional filters
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

// Fetch single event by ID
export async function fetchEventById(eventId) {
  return await fetchJson(`/events/${eventId}`);
}

// Fetch indexer stats
export async function fetchStats() {
  return await fetchJson("/stats");
}

// Fetch health status
export async function fetchHealth() {
  return await fetchJson("/health");
}

// =============================================================================
// OUC APIs (synced from OUC Canister)
// =============================================================================

// Fetch all auditors
export async function fetchAuditors() {
  return await fetchJson("/auditors");
}

// Fetch single auditor by ID
export async function fetchAuditorById(auditorId) {
  return await fetchJson(`/auditors/${auditorId}`);
}

// Fetch subscription info
export async function fetchSubscription() {
  return await fetchJson("/subscription");
}

// Fetch treasury balances
export async function fetchTreasury() {
  return await fetchJson("/treasury");
}

// Fetch OUC sync status
export async function fetchOucStatus() {
  return await fetchJson("/ouc/status");
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
    fetchEvents({ limit: 50 }),
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
    // Query APIs
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
