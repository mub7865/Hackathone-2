# Contract: Better Auth Configuration

**Feature**: 009-compliance-fixes
**Date**: 2026-01-07
**Type**: Authentication Configuration Contract

## Overview

This contract defines the Better Auth configuration for integrating with the existing user authentication system while preserving bcrypt password compatibility and existing database schema.

---

## Configuration Interface

### Server-Side Configuration

**File**: `lib/auth/config.ts`

```typescript
import { betterAuth } from "better-auth";
import { jwt } from "better-auth/plugins";
import bcrypt from "bcrypt";
import { customAdapter } from "./custom-adapter";

export const auth = betterAuth({
  // Database configuration
  database: customAdapter,

  // User model mapping
  user: {
    modelName: "users",
    fields: {
      email: "email",
      name: "name"
    },
    additionalFields: {
      role: {
        type: "string",
        required: false,
        defaultValue: "user"
      }
    }
  },

  // ID generation strategy
  generateId: "uuid",

  // Email and password authentication
  emailAndPassword: {
    enabled: true,
    password: {
      // Custom bcrypt hash function
      hash: async (password: string): Promise<string> => {
        return await bcrypt.hash(password, 10);
      },
      // Custom bcrypt verify function
      verify: async ({ hash, password }: { hash: string; password: string }): Promise<boolean> => {
        return await bcrypt.compare(password, hash);
      }
    },
    // Password validation rules
    minPasswordLength: 8,
    requireUppercase: true,
    requireLowercase: true,
    requireNumber: true
  },

  // JWT plugin configuration
  plugins: [
    jwt({
      jwt: {
        // User ID in "sub" claim (backend compatibility)
        getSubject: (user) => user.id,

        // Custom JWT payload
        definePayload: ({ user }) => ({
          id: user.id,
          email: user.email,
          role: user.role || "user"
        }),

        // JWT configuration
        issuer: "better-auth",
        audience: "calm-orbit-todo",
        expirationTime: "15 minutes",
        algorithm: "HS256"
      }
    })
  ],

  // Session configuration
  session: {
    expiresIn: 60 * 60 * 24 * 7, // 7 days
    updateAge: 60 * 60 * 24 // Update session every 24 hours
  },

  // Base URL for callbacks
  baseURL: process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000",

  // Secret for signing tokens
  secret: process.env.BETTER_AUTH_SECRET || ""
});
```

---

## Custom Database Adapter

**File**: `lib/auth/custom-adapter.ts`

```typescript
import { db } from "@/lib/db";

export const customAdapter = {
  // User operations
  user: {
    findByEmail: async (email: string) => {
      const result = await db.query(
        'SELECT id, email, name, created_at as "createdAt", updated_at as "updatedAt" FROM users WHERE email = $1',
        [email]
      );
      return result.rows[0] || null;
    },

    findById: async (id: string) => {
      const result = await db.query(
        'SELECT id, email, name, created_at as "createdAt", updated_at as "updatedAt" FROM users WHERE id = $1',
        [id]
      );
      return result.rows[0] || null;
    },

    create: async (data: { email: string; name?: string; password: string }) => {
      const result = await db.query(
        'INSERT INTO users (id, email, name, hashed_password, created_at, updated_at) VALUES (gen_random_uuid(), $1, $2, $3, NOW(), NOW()) RETURNING id, email, name, created_at as "createdAt", updated_at as "updatedAt"',
        [data.email, data.name || null, data.password]
      );
      return result.rows[0];
    },

    update: async (id: string, data: Partial<{ email: string; name: string }>) => {
      const updates: string[] = [];
      const values: any[] = [];
      let paramIndex = 1;

      if (data.email) {
        updates.push(`email = $${paramIndex++}`);
        values.push(data.email);
      }
      if (data.name !== undefined) {
        updates.push(`name = $${paramIndex++}`);
        values.push(data.name);
      }

      updates.push(`updated_at = NOW()`);
      values.push(id);

      const result = await db.query(
        `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING id, email, name, created_at as "createdAt", updated_at as "updatedAt"`,
        values
      );
      return result.rows[0];
    }
  },

  // Account operations (virtual mapping to users table)
  account: {
    findByUserId: async (userId: string) => {
      const result = await db.query(
        'SELECT id as "userId", $1 as "providerId", hashed_password as password FROM users WHERE id = $2',
        ['credential', userId]
      );
      return result.rows[0] || null;
    },

    updatePassword: async (userId: string, password: string) => {
      await db.query(
        'UPDATE users SET hashed_password = $1, updated_at = NOW() WHERE id = $2',
        [password, userId]
      );
    }
  }
};
```

---

## Client-Side Configuration

**File**: `lib/auth/client.ts`

```typescript
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  baseURL: process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000"
});

// Export specific methods for convenience
export const {
  signIn,
  signUp,
  signOut,
  useSession,
  getSession,
  updateUser,
  changePassword
} = authClient;
```

---

## API Route Handler

**File**: `app/api/auth/[...all]/route.ts`

```typescript
import { auth } from "@/lib/auth/config";
import { toNextJsHandler } from "better-auth/next-js";

export const { POST, GET } = toNextJsHandler(auth);
```

---

## Environment Variables

**Required Environment Variables**:

```bash
# Better Auth Configuration
BETTER_AUTH_SECRET=your-secret-key-here-min-32-chars
NEXT_PUBLIC_API_URL=http://localhost:3000

# Database Connection (existing)
DATABASE_URL=postgresql://user:pass@host:5432/db

# Legacy JWT (for dual token support)
JWT_SECRET=your-legacy-jwt-secret
JWT_ALGORITHM=HS256
```

---

## Authentication Flow

### Registration Flow

```
Client                    Better Auth                Database
  |                           |                          |
  | POST /api/auth/register   |                          |
  |-------------------------->|                          |
  |                           | Hash password (bcrypt)   |
  |                           |------------------------->|
  |                           | INSERT INTO users        |
  |                           |<-------------------------|
  |                           | Create session           |
  | 201 Created + JWT token   |                          |
  |<--------------------------|                          |
```

### Login Flow

```
Client                    Better Auth                Database
  |                           |                          |
  | POST /api/auth/login      |                          |
  |-------------------------->|                          |
  |                           | SELECT FROM users        |
  |                           |------------------------->|
  |                           | Verify password (bcrypt) |
  |                           |<-------------------------|
  |                           | Generate JWT token       |
  | 200 OK + JWT token        |                          |
  |<--------------------------|                          |
```

### Session Validation Flow

```
Client                    Better Auth                Database
  |                           |                          |
  | GET /api/v1/tasks         |                          |
  | Authorization: Bearer JWT |                          |
  |-------------------------->|                          |
  |                           | Verify JWT signature     |
  |                           | Extract user_id from sub |
  |                           | SELECT FROM users        |
  |                           |------------------------->|
  |                           |<-------------------------|
  | 200 OK + tasks data       |                          |
  |<--------------------------|                          |
```

---

## JWT Token Structure

### Better Auth JWT Payload

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "iss": "better-auth",
  "aud": "calm-orbit-todo",
  "iat": 1704672000,
  "exp": 1704672900,
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "role": "user"
}
```

### Token Claims

- **sub**: User ID (UUID) - used by backend for user identification
- **iss**: Issuer ("better-auth") - used for token type identification
- **aud**: Audience ("calm-orbit-todo") - application identifier
- **iat**: Issued at timestamp
- **exp**: Expiration timestamp (15 minutes from iat)
- **id**: User ID (duplicate of sub for convenience)
- **email**: User email address
- **role**: User role (default: "user")

---

## Error Handling

### Authentication Errors

```typescript
// Invalid credentials
{
  "error": "INVALID_CREDENTIALS",
  "message": "Invalid email or password"
}

// Email already exists
{
  "error": "EMAIL_ALREADY_EXISTS",
  "message": "An account with this email already exists"
}

// Invalid token
{
  "error": "INVALID_TOKEN",
  "message": "The provided token is invalid or expired"
}

// Weak password
{
  "error": "WEAK_PASSWORD",
  "message": "Password must be at least 8 characters and contain uppercase, lowercase, and number"
}
```

---

## Testing Contract

### Unit Tests

```typescript
describe("Better Auth Configuration", () => {
  it("should hash passwords using bcrypt", async () => {
    const password = "SecurePass123!";
    const hash = await auth.config.emailAndPassword.password.hash(password);
    expect(hash).toMatch(/^\$2[aby]\$/); // bcrypt hash format
  });

  it("should verify bcrypt passwords", async () => {
    const password = "SecurePass123!";
    const hash = await bcrypt.hash(password, 10);
    const isValid = await auth.config.emailAndPassword.password.verify({ hash, password });
    expect(isValid).toBe(true);
  });

  it("should generate JWT with user_id in sub claim", async () => {
    const user = { id: "test-uuid", email: "test@example.com", role: "user" };
    const token = await auth.generateToken(user);
    const decoded = jwt.decode(token);
    expect(decoded.sub).toBe("test-uuid");
  });
});
```

---

## Migration Compatibility

### Existing User Login

1. User submits email and password to Better Auth
2. Better Auth queries users table via custom adapter
3. Better Auth verifies password using bcrypt.compare()
4. Password matches existing hashed_password → login succeeds
5. Better Auth issues new JWT token with "better-auth" issuer

**Result**: Existing users can log in without password reset

### New User Registration

1. User submits email, password, and name to Better Auth
2. Better Auth hashes password using bcrypt.hash()
3. Better Auth inserts into users table via custom adapter
4. New user record created with bcrypt-hashed password
5. Better Auth issues JWT token

**Result**: New users follow same password hashing as existing users

---

## Security Considerations

1. **Password Hashing**: Bcrypt with 10 rounds (existing standard)
2. **JWT Signing**: HS256 algorithm with 32+ character secret
3. **Token Expiration**: 15 minutes (short-lived for security)
4. **Session Duration**: 7 days (refresh token rotation)
5. **HTTPS Only**: Tokens transmitted over HTTPS in production
6. **Secret Management**: Secrets stored in environment variables, never committed

---

## Rollback Strategy

If Better Auth integration fails:

1. Set `ROLLBACK_AUTH=true` in environment
2. Application falls back to legacy JWT authentication
3. Existing sessions continue to work
4. No data loss or user impact

---

**Contract Status**: ✅ Complete
**Implementation Files**: 4 files (config.ts, custom-adapter.ts, client.ts, route.ts)
**Dependencies**: better-auth, better-auth/plugins, bcrypt
