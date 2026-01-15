// Internet Identity Authentication Module
// Called from Idris2 via FFI

import { AuthClient } from "@dfinity/auth-client";

let authClient = null;
let identity = null;

// Initialize auth client
export async function initAuth() {
  authClient = await AuthClient.create();
  if (await authClient.isAuthenticated()) {
    identity = authClient.getIdentity();
    return identity.getPrincipal().toText();
  }
  return null;
}

// Login with Internet Identity
export async function login() {
  if (!authClient) {
    authClient = await AuthClient.create();
  }

  return new Promise((resolve) => {
    authClient.login({
      identityProvider: process.env.DFX_NETWORK === "ic"
        ? "https://identity.ic0.app"
        : `http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943`,
      onSuccess: () => {
        identity = authClient.getIdentity();
        resolve(identity.getPrincipal().toText());
      },
      onError: (err) => {
        console.error("Login failed:", err);
        resolve(null);
      },
    });
  });
}

// Logout
export async function logout() {
  if (authClient) {
    await authClient.logout();
    identity = null;
  }
}

// Check if authenticated
export async function isAuthenticated() {
  if (!authClient) return false;
  return await authClient.isAuthenticated();
}

// Get current principal
export function getPrincipal() {
  if (!identity) return null;
  return identity.getPrincipal().toText();
}

// Get identity for agent
export function getIdentity() {
  return identity;
}

// Expose to global scope for Idris2 FFI
if (typeof window !== 'undefined') {
  window.oucAuth = {
    initAuth,
    login,
    logout,
    isAuthenticated,
    getPrincipal,
    getIdentity
  };
}
