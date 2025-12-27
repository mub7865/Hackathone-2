/**
 * Better Auth client configuration
 * Provides authentication utilities for the frontend
 */

// Session interface matching Better Auth
export interface Session {
  user: {
    id: string;
    email: string;
    name?: string;
  };
  accessToken: string;
  expiresAt: string;
}

// Auth state
interface AuthState {
  session: Session | null;
  isLoading: boolean;
}

// Track if auth has been initialized (MUST be declared before use)
let authInitialized = false;

// In-memory auth state (will be replaced with Better Auth hooks in production)
let authState: AuthState = {
  session: null,
  isLoading: true,
};

// Auth state listeners
type AuthListener = (state: AuthState) => void;
const listeners: Set<AuthListener> = new Set();

/**
 * Get the current session
 */
export function getSession(): Session | null {
  return authState.session;
}

/**
 * Check if user is authenticated
 */
export function isAuthenticated(): boolean {
  return authState.session !== null;
}

/**
 * Get the current access token
 */
export async function getAccessToken(): Promise<string | null> {
  const session = getSession();
  if (!session) {
    return null;
  }

  // Check if token is expired
  const expiresAt = new Date(session.expiresAt);
  if (expiresAt <= new Date()) {
    // Token expired, clear session
    await signOut();
    return null;
  }

  return session.accessToken;
}

/**
 * Set the session (called after successful login)
 */
export function setSession(session: Session | null): void {
  authState = {
    session,
    isLoading: false,
  };
  // Mark as initialized since we have a valid session from login
  if (session !== null) {
    authInitialized = true;
  }
  notifyListeners();
}

/**
 * Sign out the user
 */
export async function signOut(): Promise<void> {
  authState = {
    session: null,
    isLoading: false,
  };
  // Clear persisted session
  if (typeof window !== 'undefined') {
    localStorage.removeItem('auth_session');
    document.cookie = 'auth_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
  }
  // Reset initialization so next login can re-initialize
  authInitialized = false;
  notifyListeners();
}

// API base URL for auth endpoints
const API_BASE_URL = typeof window !== 'undefined'
  ? (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000')
  : 'http://localhost:8000';

// Auth response from backend
interface AuthResponse {
  user: {
    id: string;
    email: string;
    name: string | null;
    created_at: string;
  };
  access_token: string;
  token_type: string;
  expires_at: string;
}

/**
 * Sign in with email and password
 * Calls POST /api/v1/auth/login and establishes session
 */
export async function signIn(email: string, password: string): Promise<Session> {
  const response = await fetch(`${API_BASE_URL}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => null);
    throw new Error(errorData?.detail || 'Invalid email or password');
  }

  const data: AuthResponse = await response.json();

  const session: Session = {
    user: {
      id: data.user.id,
      email: data.user.email,
      name: data.user.name || undefined,
    },
    accessToken: data.access_token,
    expiresAt: data.expires_at,
  };

  // Persist session
  persistSession(session);

  return session;
}

/**
 * Sign up with email, password, and optional name
 * Calls POST /api/v1/auth/register and establishes session
 */
export async function signUp(email: string, password: string, name?: string): Promise<Session> {
  const response = await fetch(`${API_BASE_URL}/api/v1/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, name: name || null }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => null);
    throw new Error(errorData?.detail || 'Registration failed');
  }

  const data: AuthResponse = await response.json();

  const session: Session = {
    user: {
      id: data.user.id,
      email: data.user.email,
      name: data.user.name || undefined,
    },
    accessToken: data.access_token,
    expiresAt: data.expires_at,
  };

  // Persist session
  persistSession(session);

  return session;
}

/**
 * Persist session to localStorage, cookie, and in-memory state
 */
function persistSession(session: Session): void {
  // Update in-memory state
  setSession(session);

  // Persist to localStorage
  if (typeof window !== 'undefined') {
    localStorage.setItem('auth_session', JSON.stringify(session));
    // Set cookie for middleware authentication check (24 hour expiry)
    document.cookie = `auth_token=${session.accessToken}; path=/; max-age=${60 * 60 * 24}; SameSite=Lax`;
  }
}

/**
 * Subscribe to auth state changes
 */
export function onAuthStateChange(listener: AuthListener): () => void {
  listeners.add(listener);
  // Immediately call with current state
  listener(authState);
  // Return unsubscribe function
  return () => {
    listeners.delete(listener);
  };
}

/**
 * Initialize auth state (check for existing session)
 * Only runs once - subsequent calls are no-ops if session already exists
 */
export async function initAuth(): Promise<void> {
  // Skip if already initialized and has session (e.g., after login)
  if (authInitialized && authState.session !== null) {
    // Just ensure isLoading is false
    if (authState.isLoading) {
      authState.isLoading = false;
      notifyListeners();
    }
    return;
  }

  // Skip if already initialized and not loading
  if (authInitialized && !authState.isLoading) {
    return;
  }

  authState.isLoading = true;
  notifyListeners();

  try {
    // In production, this would check for existing session with Better Auth
    // For now, we'll check localStorage for a persisted session
    const stored = typeof window !== 'undefined'
      ? localStorage.getItem('auth_session')
      : null;

    if (stored) {
      const session = JSON.parse(stored) as Session;
      const expiresAt = new Date(session.expiresAt);

      if (expiresAt > new Date()) {
        authState.session = session;
      } else {
        localStorage.removeItem('auth_session');
      }
    }
  } catch {
    // Ignore parsing errors
  } finally {
    authInitialized = true;
    authState.isLoading = false;
    notifyListeners();
  }
}

function notifyListeners(): void {
  listeners.forEach((listener) => listener(authState));
}
