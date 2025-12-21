# Data Model: AI-Powered Todo Chatbot (Phase III)

**Feature**: 007-ai-chatbot-phase3
**Date**: 2025-12-18

---

## Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────────┐       ┌─────────────────┐
│      User       │       │    Conversation     │       │     Message     │
│  (Better Auth)  │       │                     │       │                 │
├─────────────────┤       ├─────────────────────┤       ├─────────────────┤
│ id: string (PK) │──1:N──│ id: int (PK)        │──1:N──│ id: int (PK)    │
│ email: string   │       │ user_id: string(FK) │       │ conversation_id │
│ name: string    │       │ title: string(100)  │       │ role: string    │
│ ...             │       │ created_at: datetime│       │ content: text   │
└─────────────────┘       │ updated_at: datetime│       │ created_at      │
                          └─────────────────────┘       └─────────────────┘
        │
        │ 1:N
        ▼
┌─────────────────┐
│      Task       │
│   (Existing)    │
├─────────────────┤
│ id: int (PK)    │
│ user_id: string │
│ title: string   │
│ description     │
│ completed: bool │
│ created_at      │
│ updated_at      │
└─────────────────┘
```

---

## New Entities

### 1. Conversation

Represents a chat session between a user and the AI assistant.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | Integer | PK, Auto-increment | Unique conversation identifier |
| user_id | String | NOT NULL, Indexed | Reference to Better Auth user |
| title | String(100) | Nullable | Auto-generated from first message (50 chars truncated) |
| created_at | DateTime | NOT NULL, Default NOW | When conversation started |
| updated_at | DateTime | NOT NULL, Default NOW | Last activity timestamp |

**Indexes:**
- `idx_conversations_user_id` on `user_id` (for listing user's conversations)
- `idx_conversations_updated_at` on `updated_at` (for sorting by recent)

**Relationships:**
- Belongs to User (via user_id string match)
- Has many Messages (cascade delete)

**SQLModel Definition:**
```python
from sqlmodel import SQLModel, Field
from datetime import datetime
from typing import Optional

class Conversation(SQLModel, table=True):
    __tablename__ = "conversations"

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: str = Field(index=True, nullable=False)
    title: Optional[str] = Field(max_length=100, default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
```

---

### 2. Message

Represents a single message in a conversation.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | Integer | PK, Auto-increment | Unique message identifier |
| conversation_id | Integer | FK, NOT NULL, Indexed | Reference to parent conversation |
| role | String(20) | NOT NULL | "user" or "assistant" |
| content | Text | NOT NULL | Message content |
| created_at | DateTime | NOT NULL, Default NOW | When message was sent |

**Indexes:**
- `idx_messages_conversation_id` on `conversation_id` (for loading conversation messages)

**Relationships:**
- Belongs to Conversation (cascade delete when conversation deleted)

**Validation Rules:**
- `role` must be one of: "user", "assistant"
- `content` cannot be empty

**SQLModel Definition:**
```python
from sqlmodel import SQLModel, Field
from datetime import datetime
from typing import Optional

class Message(SQLModel, table=True):
    __tablename__ = "messages"

    id: Optional[int] = Field(default=None, primary_key=True)
    conversation_id: int = Field(foreign_key="conversations.id", index=True, nullable=False)
    role: str = Field(max_length=20, nullable=False)  # "user" or "assistant"
    content: str = Field(nullable=False)
    created_at: datetime = Field(default_factory=datetime.utcnow)
```

---

## Existing Entity (Reference)

### Task (from Phase II)

Already exists in database. MCP tools will interact with this entity.

| Field | Type | Description |
|-------|------|-------------|
| id | Integer | PK |
| user_id | String | Owner reference |
| title | String | Task title |
| description | String | Optional description |
| completed | Boolean | Completion status |
| created_at | DateTime | Creation timestamp |
| updated_at | DateTime | Last update timestamp |

---

## State Transitions

### Conversation Lifecycle

```
[New Chat Click] → CREATED (title=null)
       │
       ▼
[First Message] → ACTIVE (title=truncated message)
       │
       ▼
[Continue Chat] → ACTIVE (updated_at refreshed)
       │
       ▼
[Delete] → DELETED (cascade removes all messages)
```

### Message Lifecycle

```
[User Sends] → CREATED (role="user")
       │
       ▼
[AI Responds] → CREATED (role="assistant")
```

---

## Data Volume Assumptions

| Entity | Expected Volume | Notes |
|--------|-----------------|-------|
| Users | 50-100 | Hackathon demo scale |
| Conversations per User | 10-50 | Average usage |
| Messages per Conversation | 20-100 | Typical chat length |
| Total Messages | ~50,000 max | Within Neon free tier |

---

## Migration Notes

### Alembic Migration Required

```python
# New migration for Phase III
def upgrade():
    # Create conversations table
    op.create_table(
        'conversations',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('user_id', sa.String(), nullable=False, index=True),
        sa.Column('title', sa.String(100), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now()),
    )

    # Create messages table with cascade delete
    op.create_table(
        'messages',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('conversation_id', sa.Integer(),
                  sa.ForeignKey('conversations.id', ondelete='CASCADE'),
                  nullable=False, index=True),
        sa.Column('role', sa.String(20), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now()),
    )

def downgrade():
    op.drop_table('messages')
    op.drop_table('conversations')
```
