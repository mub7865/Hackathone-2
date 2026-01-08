import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Routes that require authentication
const protectedRoutes = ['/tasks'];

// Routes that should redirect to /tasks if already authenticated
const authRoutes = ['/login'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // DEBUG: Log pathname
  console.log('DEBUG pathname:', pathname);

  // Forward /api/v1/* requests to backend service
  if (pathname.startsWith('/api/v1/')) {
    const backendUrl = `http://backend-service:8000${pathname}${request.nextUrl.search}`;
    console.log('DEBUG rewrite to:', backendUrl);
    return NextResponse.rewrite(backendUrl);
  }

  // Check for auth token in cookies
  // In production, this would use Better Auth's session cookie
  const authToken = request.cookies.get('auth_token')?.value;
  const isAuthenticated = Boolean(authToken);

  // Check if current route is protected
  const isProtectedRoute = protectedRoutes.some((route) =>
    pathname.startsWith(route)
  );

  // Check if current route is an auth route (login, signup, etc.)
  const isAuthRoute = authRoutes.some((route) =>
    pathname.startsWith(route)
  );

  // Redirect unauthenticated users from protected routes to login
  if (isProtectedRoute && !isAuthenticated) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('redirect', pathname);
    return NextResponse.redirect(loginUrl);
  }

  // Redirect authenticated users from auth routes to tasks
  if (isAuthRoute && isAuthenticated) {
    return NextResponse.redirect(new URL('/tasks', request.url));
  }

  return NextResponse.next();
}

export const config = {
  // Match all routes except static files and _next routes
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|_next).*)',
  ],
};
