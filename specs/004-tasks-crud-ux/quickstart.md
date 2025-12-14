# Quickstart: Tasks CRUD UX (Web App)

**Feature**: 004-tasks-crud-ux
**Date**: 2025-12-13
**Purpose**: Get the Tasks frontend running quickly

---

## Prerequisites

1. **Backend running**: The Tasks API at `http://localhost:8000/api/v1/tasks` must be operational
2. **Node.js 18+**: Required for Next.js 16
3. **Better Auth configured**: Auth client assumed pre-wired (per spec constraints)

---

## Quick Setup

```bash
# Navigate to frontend directory
cd phase2/frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

The app will be available at `http://localhost:3000`.

---

## Key Routes

| Route | Purpose | Auth Required |
|-------|---------|---------------|
| `/tasks` | Main tasks page with list, filters, CRUD actions | Yes |
| `/login` | Login page (assumed to exist) | No |

---

## Environment Variables

Create `.env.local` in `phase2/frontend/`:

```env
# Backend API URL
NEXT_PUBLIC_API_URL=http://localhost:8000

# Better Auth (assumed pre-configured)
# Add any Better Auth env vars here
```

---

## Testing the Flow

1. **Start backend**: Ensure FastAPI server is running on port 8000
2. **Start frontend**: `npm run dev` in `phase2/frontend`
3. **Login**: Navigate to `/login` and authenticate
4. **View tasks**: You'll be redirected to `/tasks` showing pending tasks
5. **Create task**: Click "Add Task", enter title, submit
6. **Complete task**: Click checkbox on a pending task
7. **Edit task**: Click edit icon, modify fields, save
8. **Delete task**: Click delete icon, confirm in modal

---

## Development Commands

```bash
# Development server with hot reload
npm run dev

# Type checking
npm run type-check

# Linting
npm run lint

# Build for production
npm run build

# Run tests
npm run test
```

---

## File Structure Overview

```
phase2/frontend/
├── app/
│   ├── (authenticated)/
│   │   ├── layout.tsx       # Auth-protected layout
│   │   └── tasks/
│   │       └── page.tsx     # Tasks page
│   ├── login/
│   │   └── page.tsx         # Login page (assumed)
│   ├── layout.tsx           # Root layout
│   └── page.tsx             # Home (redirects to /tasks)
├── components/
│   ├── tasks/
│   │   ├── TaskList.tsx
│   │   ├── TaskItem.tsx
│   │   ├── TaskForm.tsx
│   │   ├── TaskFilterTabs.tsx
│   │   ├── DeleteConfirmModal.tsx
│   │   └── EmptyState.tsx
│   └── ui/
│       ├── Modal.tsx
│       ├── Button.tsx
│       ├── Input.tsx
│       └── Toast.tsx
├── lib/
│   ├── api/
│   │   └── tasks.ts         # Typed API client
│   └── auth/
│       └── client.ts        # Better Auth client
├── hooks/
│   └── useTasks.ts          # Task list hook
└── types/
    └── task.ts              # TypeScript types
```

---

## Troubleshooting

### "Unauthorized" errors
- Check that you're logged in (session exists)
- Verify JWT token is being sent in Authorization header
- Check backend logs for auth validation errors

### Tasks not loading
- Verify backend is running: `curl http://localhost:8000/api/v1/tasks`
- Check browser console for CORS errors
- Verify `NEXT_PUBLIC_API_URL` is set correctly

### Form validation not working
- Check browser console for JavaScript errors
- Ensure controlled input components are used
- Verify character counter is updating on input

---

## Next Steps

After completing this feature:
1. Run `/sp.tasks` to generate implementation tasks
2. Implement tasks in order (P1 stories first)
3. Test each user flow against acceptance scenarios
