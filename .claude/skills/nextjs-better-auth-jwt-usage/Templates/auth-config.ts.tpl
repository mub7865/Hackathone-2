/**
 * Standard Better Auth configuration for a Next.js 16+ App Router project.
 *
 * PURPOSE:
 * - Create a single auth instance for the whole app.
 * - Enable the JWT plugin so other services (e.g. a backend API) can verify users.
 * - Read secrets and URLs from environment variables, not hard-coded strings.
 *
 * NOTE:
 * - Adjust imports and options according to the Better Auth version and docs.
 */

import { createAuth } from "better-auth"; // adjust import if package name differs
// import { jwtPlugin } from "better-auth/jwt"; // example: JWT plugin import (check docs)

const BETTER_AUTH_SECRET = process.env.BETTER_AUTH_SECRET;
if (!BETTER_AUTH_SECRET) {
  throw new Error("BETTER_AUTH_SECRET is not set");
}

export const auth = createAuth({
  secret: BETTER_AUTH_SECRET,
  // Example DB config placeholder:
  // database: {
  //   type: "postgres",
  //   url: process.env.DATABASE_URL!,
  // },
  // Example: register JWT plugin if using it:
  // plugins: [
  //   jwtPlugin({
  //     // Configure JWT options here (issuer, audience, expiry, etc.)
  //   }),
  // ],
});

/**
 * Helper to get the current session/user on the server.
 * Use this in server components, server actions, or middleware.
 */
export async function getServerAuthContext() {
  const session = await auth.getSession();
  const user = session?.user ?? null;

  return {
    session,
    user,
    isAuthenticated: !!user,
  };
}
