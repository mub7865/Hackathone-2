# Phase II-III: Next.js Frontend

## Overview
Full-stack web application frontend with AI chatbot integration.

## Features

### Phase II Features
- User authentication (Better Auth)
- Task CRUD operations
- Responsive UI with Tailwind CSS
- Real-time updates

### Phase III Features
- OpenAI ChatKit integration
- Natural language task management
- Conversational interface
- Feature flag support

## Technology Stack
- Next.js 16 (App Router)
- TypeScript
- Tailwind CSS
- Better Auth
- OpenAI ChatKit

## Setup

```bash
cd phase2-3-fullstack-frontend
npm install
```

## Environment Variables

Create `.env.local`:
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
BETTER_AUTH_SECRET=your-secret-key-here-min-32-chars
DATABASE_URL=postgresql://user:pass@host:5432/db

# Feature Flags
NEXT_PUBLIC_FEATURE_NEW_AUTH=false
NEXT_PUBLIC_FEATURE_NEW_CHAT=false
```

## Running

```bash
npm run dev
```

Access at: http://localhost:3000

## Features Toggle

Enable Better Auth:
```env
NEXT_PUBLIC_FEATURE_NEW_AUTH=true
```

Enable ChatKit:
```env
NEXT_PUBLIC_FEATURE_NEW_CHAT=true
```

## Project Structure

```
phase2-3-fullstack-frontend/
├── app/                    # Next.js App Router pages
├── components/             # React components
│   ├── chat/              # ChatKit components
│   ├── layout/            # Layout components
│   ├── tasks/             # Task management components
│   └── ui/                # Base UI components
├── lib/                   # Utilities
│   ├── api/               # API client
│   ├── auth/              # Authentication
│   └── features/          # Feature flags
└── types/                 # TypeScript types
```
