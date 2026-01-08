# Data Model: Hackathon Compliance Fixes

**Feature**: 009-compliance-fixes
**Date**: 2026-01-07
**Status**: Design Complete

## Overview

This feature preserves the existing database schema while integrating Better Auth and ChatKit. No database migrations are required. The implementation uses custom adapters and configuration to map Better Auth's expected schema to the existing structure.

---

## Existing Database Schema (Preserved)

### Users Table

**Table Name**: `users`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | User unique identifier |
| email | VARCHAR(255) | UNIQUE, NOT NULL | User email address |
| hashed_password | VARCHAR(255) | NOT NULL | Bcrypt-hashed password |
| name | VARCHAR(255) | NULL | User display name |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Account creation timestamp |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes**:
- PRIMARY KEY on `id`
- UNIQUE INDEX on `email`

**Relationships**:
- One-to-many with `tasks` (user_id foreign key)
- One-to-many with `conversations` (user_id foreign key)

---

### Tasks Table

**Table Name**: `tasks`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Task unique identifier |
| user_id | UUID | FOREIGN KEY (users.id), NOT NULL | Owner of the task |
| title | VARCHAR(255) | NOT NULL | Task title |
| description | TEXT | NULL | Task description |
| status | VARCHAR(50) | NOT NULL, DEFAULT 'pending' | Task status (pending, completed) |
| priority | VARCHAR(50) | NULL | Task priority (low, medium, high) |
| due_date | TIMESTAMP | NULL | Task due date |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Task creation timestamp |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes**:
- PRIMARY KEY on `id`
- INDEX on `user_id`
- INDEX on `status`

**Relationships**:
- Many-to-one with `users` (user_id foreign key)

---

### Conversations Table

**Table Name**: `conversations`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Conversation unique identifier |
| user_id | UUID | FOREIGN KEY (users.id), NOT NULL | Owner of the conversation |
| title | VARCHAR(255) | NULL | Conversation title |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Conversation creation timestamp |
| updated_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes**:
- PRIMARY KEY on `id`
- INDEX on `user_id`

**Relationships**:
- Many-to-one with `users` (user_id foreign key)
- One-to-many with `messages` (conversation_id foreign key)

---

### Messages Table

**Table Name**: `messages`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INTEGER | PRIMARY KEY, AUTOINCREMENT | Message unique identifier |
| conversation_id | INTEGER | FOREIGN KEY (conversations.id), NOT NULL | Parent conversation |
| role | VARCHAR(50) | NOT NULL | Message role (user, assistant, system) |
| content | TEXT | NOT NULL | Message content |
| tool_calls | JSON | NULL | Tool calls made by assistant |
| created_at | TIMESTAMP | NOT NULL, DEFAULT NOW() | Message creation timestamp |

**Indexes**:
- PRIMARY KEY on `id`
- INDEX on `conversation_id`

**Relationships**:
- Many-to-one with `conversations` (conversation_id foreign key)

---

## Better Auth Expected Schema (NOT Implemented)

Better Auth expects a different schema structure with separate user and account tables:

### Better Auth User Table (Expected)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | User unique identifier |
| email | VARCHAR | User email |
| name | VARCHAR | User display name |
| emailVerified | BOOLEAN | Email verification status |
| image | VARCHAR | User avatar URL |
| createdAt | TIMESTAMP | Account creation |
| updatedAt | TIMESTAMP | Last update |

### Better Auth Account Table (Expected)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Account unique identifier |
| userId | UUID | Foreign key to user table |
| providerId | VARCHAR | Auth provider (e.g., "credential", "google") |
| accountId | VARCHAR | Provider-specific account ID |
| password | VARCHAR | Hashed password (for credential provider) |
| accessToken | TEXT | OAuth access token |
| refreshToken | TEXT | OAuth refresh token |
| expiresAt | TIMESTAMP | Token expiration |
| createdAt | TIMESTAMP | Account creation |
| updatedAt | TIMESTAMP | Last update |

---

## Schema Mapping Strategy

### Approach: Custom Adapter with Virtual Account Table

**Decision**: Use custom database adapter to map Better Auth's account queries to the existing users table.

**Mapping**:

| Better Auth Query | Mapped To | Notes |
|-------------------|-----------|-------|
| `user.findByEmail(email)` | `SELECT * FROM users WHERE email = ?` | Direct mapping |
| `user.findById(id)` | `SELECT * FROM users WHERE id = ?` | Direct mapping |
| `account.findByUserId(userId)` | `SELECT id as userId, 'credential' as providerId, hashed_password as password FROM users WHERE id = ?` | Virtual account record |
| `account.updatePassword(userId, password)` | `UPDATE users SET hashed_password = ? WHERE id = ?` | Direct mapping to users table |

**Implementation**:
```typescript
// lib/auth/custom-adapter.ts
export const customAdapter = {
  user: {
    findByEmail: async (email: string) => {
      // Query users table
      return await db.query('SELECT * FROM users WHERE email = ?', [email]);
    },
    create: async (data: UserData) => {
      // Insert into users table
      return await db.query('INSERT INTO users (email, name, hashed_password) VALUES (?, ?, ?)',
        [data.email, data.name, data.password]);
    }
  },
  account: {
    findByUserId: async (userId: string) => {
      // Virtual account record from users table
      const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);
      return {
        userId: user.id,
        providerId: 'credential',
        password: user.hashed_password
      };
    },
    updatePassword: async (userId: string, password: string) => {
      // Update users table directly
      return await db.query('UPDATE users SET hashed_password = ? WHERE id = ?',
        [password, userId]);
    }
  }
};
```

**Rationale**: This approach preserves the existing schema while providing Better Auth compatibility. No data migration required, zero downtime, maintains backward compatibility.

---

## JWT Token Structure

### Custom JWT (Legacy)

**Claims**:
```json
{
  "sub": "user-uuid-here",
  "iat": 1704672000,
  "exp": 1704758400
}
```

**Signing**:
- Algorithm: HS256
- Secret: `JWT_SECRET` environment variable

---

### Better Auth JWT (New)

**Claims**:
```json
{
  "sub": "user-uuid-here",
  "iss": "better-auth",
  "iat": 1704672000,
  "exp": 1704758400,
  "email": "user@example.com",
  "role": "user"
}
```

**Signing**:
- Algorithm: HS256
- Secret: `BETTER_AUTH_SECRET` environment variable
- Issuer: "better-auth"

**Compatibility**: Both token types include `user_id` in the `sub` claim, ensuring backend compatibility.

---

## Feature Flag Configuration

### Feature Flags (Non-Persistent)

Feature flags are stored in environment variables and ConfigMaps, not in the database.

**Environment Variables**:
```bash
FEATURE_NEW_AUTH=false
FEATURE_NEW_CHAT=false
ROLLBACK_AUTH=false
ROLLBACK_CHAT=false
AUTH_MIGRATION_ENABLED=true
ENABLE_LEGACY_TOKENS=true
LEGACY_TOKEN_CUTOFF_DATE=2026-01-15T00:00:00Z
```

**Kubernetes ConfigMap**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
data:
  FEATURE_NEW_AUTH: "false"
  FEATURE_NEW_CHAT: "false"
  ROLLBACK_AUTH: "false"
  ROLLBACK_CHAT: "false"
```

---

## State Transitions

### User Authentication State

```
[Unauthenticated]
    |
    | POST /api/v1/auth/register (Better Auth)
    v
[Registered] --> [Email Verified] (optional)
    |
    | POST /api/v1/auth/login (Better Auth)
    v
[Authenticated]
    |
    | JWT Token Issued (Better Auth or Legacy)
    v
[Active Session]
    |
    | Token Expires or POST /api/v1/auth/logout
    v
[Unauthenticated]
```

### Task Status Transitions

```
[pending] --> [completed] --> [deleted]
    ^            |
    |____________|
    (can revert to pending)
```

### Conversation State

```
[New Conversation]
    |
    | POST /api/v1/chat (first message)
    v
[Active Conversation]
    |
    | POST /api/v1/chat (subsequent messages)
    v
[Conversation with History]
    |
    | DELETE /api/v1/conversations/:id
    v
[Deleted]
```

---

## Validation Rules

### User Entity

- **email**: Must be valid email format, unique across users table
- **password**: Minimum 8 characters, must contain at least one uppercase, one lowercase, one number
- **name**: Optional, max 255 characters

### Task Entity

- **title**: Required, max 255 characters
- **status**: Must be one of: "pending", "completed"
- **priority**: Must be one of: "low", "medium", "high" (if provided)
- **due_date**: Must be future date (if provided)

### Message Entity

- **role**: Must be one of: "user", "assistant", "system"
- **content**: Required, max 10,000 characters
- **conversation_id**: Must reference existing conversation owned by authenticated user

---

## Data Integrity Constraints

### User Isolation

- All queries must filter by `user_id` from authenticated JWT token
- Users can only access their own tasks, conversations, and messages
- Backend enforces user isolation at the dependency injection level

### Referential Integrity

- Tasks reference users via `user_id` foreign key (CASCADE DELETE)
- Conversations reference users via `user_id` foreign key (CASCADE DELETE)
- Messages reference conversations via `conversation_id` foreign key (CASCADE DELETE)

### Concurrency

- Optimistic locking via `updated_at` timestamp
- Last-write-wins strategy for concurrent updates
- No distributed transactions required (single database)

---

## Migration Strategy

### Phase 1: No Schema Changes

- ✅ Existing schema preserved
- ✅ Custom adapter maps Better Auth to existing structure
- ✅ Zero data migration required
- ✅ Zero downtime deployment

### Phase 2: Dual Token Support (7 Days)

- ✅ Both custom JWT and Better Auth JWT accepted
- ✅ New logins issue Better Auth tokens
- ✅ Existing sessions continue with custom tokens
- ✅ Gradual migration without forced re-login

### Phase 3: Legacy Token Deprecation (Day 8+)

- ✅ Custom JWT tokens rejected
- ✅ Users with expired tokens must re-login
- ✅ Better Auth becomes sole authentication mechanism

---

## Performance Considerations

### Indexing Strategy

- ✅ Existing indexes on `user_id`, `email`, `status` maintained
- ✅ No new indexes required
- ✅ Query performance unchanged

### Caching Strategy

- JWT tokens cached in memory (FastAPI dependency cache)
- Feature flags cached with 5-second TTL
- No database caching changes required

---

## Security Considerations

### Password Storage

- ✅ Bcrypt hashing maintained (10 rounds)
- ✅ Better Auth configured to use bcrypt
- ✅ No password migration required

### Token Security

- ✅ JWT secrets stored in environment variables
- ✅ Different secrets for custom and Better Auth tokens
- ✅ Token expiration enforced (15 minutes for Better Auth)
- ✅ Refresh token rotation (Better Auth default)

### User Isolation

- ✅ All queries filtered by authenticated user_id
- ✅ Foreign key constraints enforce data ownership
- ✅ Backend dependencies inject user_id from JWT

---

## Summary

**Schema Changes**: None required
**Data Migration**: None required
**Backward Compatibility**: 100% maintained
**Deployment Risk**: Low (feature flags enable instant rollback)
**Implementation Complexity**: Medium (custom adapter required)

**Key Design Decisions**:
1. Preserve existing schema (zero data loss)
2. Use custom adapter for Better Auth compatibility
3. Dual token validation for gradual migration
4. Feature flags for instant rollback capability
5. Environment-based configuration (no database changes)

---

**Status**: ✅ Design Complete
**Next**: Generate API contracts in `/contracts/` directory
