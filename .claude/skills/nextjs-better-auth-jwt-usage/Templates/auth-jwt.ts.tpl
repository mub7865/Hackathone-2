/**
 * Better Auth JWT helper for Next.js 16+ frontends.
 *
 * PURPOSE:
 * - Provide a single place to obtain a JWT for the currently
 *   authenticated user from Better Auth.
 * - Feed that JWT into the frontend API client (e.g. createApiClient)
 *   via a `getAuthToken` function.
 *
 * NOTE:
 * - The exact API for obtaining a JWT depends on the Better Auth
 *   version and its JWT plugin. Adapt this template to the official docs.
 */

"use server";

import { auth } from "@/lib/auth-config"; // adjust path to match your project

/**
 * Returns a JWT token string for the currently authenticated user,
 * or null if there is no valid session.
 *
 * HOW IT IS USED:
 * - Pass this function (or a wrapper) to `createApiClient({ getAuthToken })`
 *   so that all frontend → backend API calls share the same logic for
 *   attaching the Authorization header.
 */
export async function getAuthTokenForCurrentUser(): Promise<string | null> {
  // Example placeholder logic; replace with real Better Auth JWT API.

  const session = await auth.getSession();
  if (!session?.user) {
    return null;
  }

  // Depending on Better Auth's JWT plugin, this might be:
  // - a direct helper like `auth.getJwtForUser(session.user.id)`
  // - or an API call to a custom endpoint.
  //
  // Replace the placeholder below with the actual implementation.

  const fakeToken = null as string | null;

  if (!fakeToken) {
    // No JWT currently available; caller should handle the unauthenticated case.
    return null;
  }

  return fakeToken;
}
