/**
 * Central API configuration for Next.js 16+ frontends.
 *
 * PURPOSE:
 * - Provide a single source of truth for API base URL and related settings.
 * - Make it easy to switch between local, staging, and production backends.
 * - Avoid hard-coding URLs or magic strings across components.
 *
 * HOW TO USE:
 * - Import `API_BASE_URL` and other config values from this module.
 * - Pass `API_BASE_URL` into createApiClient(...) when building the client.
 */

type Environment = "development" | "test" | "production";

const NODE_ENV = (process.env.NODE_ENV ?? "development") as Environment;

/**
 * Derive the API base URL from environment variables.
 *
 * You can adapt this logic to your needs:
 * - Use NEXT_PUBLIC_API_BASE_URL for browser-safe URLs.
 * - Use a server-only env var for server components.
 */
const PUBLIC_API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

export const API_BASE_URL: string = PUBLIC_API_BASE_URL;

/**
 * Optional: other API-related config flags.
 */
export const API_CONFIG = {
  env: NODE_ENV,
  baseUrl: API_BASE_URL,
  // Example flags:
  // timeoutMs: 15000,
  // enableLogging: NODE_ENV === "development",
};
