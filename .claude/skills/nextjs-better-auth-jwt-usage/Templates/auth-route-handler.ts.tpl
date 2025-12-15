/**
 * Standard Better Auth route handler for Next.js App Router.
 *
 * PURPOSE:
 * - Mount the Better Auth HTTP handler under a catch-all API route.
 * - Handle login, signup, logout, and other auth-related requests.
 *
 * EXPECTED LOCATION:
 * - Place this file as `app/api/auth/[...all]/route.ts` (or similar),
 *   adjusting imports as needed.
 */

import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth-config"; // adjust path to match auth-config.ts

// Better Auth typically exposes a handler factory for Next.js.
// The exact API may differ; adapt according to the official docs.
const handler = auth.createNextRouteHandler?.() ?? null;

if (!handler) {
  throw new Error(
    "Better Auth route handler factory (createNextRouteHandler) is not available. " +
      "Check the Better Auth Next.js integration docs and update this template.",
  );
}

export async function GET(req: NextRequest) {
  return handler.GET?.(req, NextResponse) ?? NextResponse.json(
    { message: "GET not implemented by Better Auth handler" },
    { status: 501 },
  );
}

export async function POST(req: NextRequest) {
  return handler.POST?.(req, NextResponse) ?? NextResponse.json(
    { message: "POST not implemented by Better Auth handler" },
    { status: 501 },
  );
}

export async function PUT(req: NextRequest) {
  return handler.PUT?.(req, NextResponse) ?? NextResponse.json(
    { message: "PUT not implemented by Better Auth handler" },
    { status: 501 },
  );
}

export async function PATCH(req: NextRequest) {
  return handler.PATCH?.(req, NextResponse) ?? NextResponse.json(
    { message: "PATCH not implemented by Better Auth handler" },
    { status: 501 },
  );
}

export async function DELETE(req: NextRequest) {
  return handler.DELETE?.(req, NextResponse) ?? NextResponse.json(
    { message: "DELETE not implemented by Better Auth handler" },
    { status: 501 },
  );
}

export const dynamic = "force-dynamic";
