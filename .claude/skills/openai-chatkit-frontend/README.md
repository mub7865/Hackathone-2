# Skill: openai-chatkit-frontend

## Purpose

This Skill teaches Claude how to build AI chat interfaces using
**OpenAI ChatKit** with **Next.js App Router**.

It standardizes:

- How to install and configure ChatKit in Next.js projects.
- How to implement the ChatKit component with proper hooks.
- How to integrate with custom FastAPI backends.
- How to handle authentication and error states.
- How to style and customize the chat interface.

The goal is to provide a consistent, production-ready pattern for adding
conversational AI interfaces to Next.js applications.

## What this Skill defines

- **SKILL.md** - Rules and patterns for:
  - Installing ChatKit dependencies (React bindings and CDN script).
  - Configuring useChatKit hook with getClientSecret.
  - Implementing ChatKit component with proper styling.
  - Integrating with authentication (Better Auth / JWT).
  - Error handling and loading states.
  - Responsive design patterns.

- **Templates/**
  - `ChatWidget.tsx.tpl`
    Reusable ChatKit component:
    - Uses useChatKit hook for configuration.
    - Fetches client secret from backend.
    - Handles error states gracefully.
    - Supports custom styling via className.

  - `ChatToggle.tsx.tpl`
    Floating chat button with toggle:
    - Fixed position button to open/close chat.
    - Animated panel appearance.
    - Accessible keyboard support.

  - `chat-page.tsx.tpl`
    Dedicated chat page:
    - Full-page chat layout.
    - Authentication check.
    - Responsive container.

  - `chatkit-session-api.ts.tpl`
    Next.js API route (if needed):
    - Proxies session creation to backend.
    - Handles authentication tokens.

- **Examples/**
  - `chatkit-integration-example.md`
    Complete example showing:
    - Step-by-step ChatKit setup.
    - Integration with existing Todo app.
    - Custom backend connection.
    - Authentication flow.

## When to enable this Skill

Enable this Skill in any frontend project where:

- You need to add an **AI chat interface** to a Next.js application.
- You want to use **OpenAI ChatKit** for a polished chat UI.
- You're connecting to a **custom backend** with AI agent capabilities.
- You need **real-time streaming** chat responses.
- You're building on top of an existing **authenticated application**.

## How to integrate in a project

Typical integration steps:

1. Install ChatKit React bindings:
   ```bash
   npm install @openai/chatkit-react
   ```

2. Add ChatKit script to your root layout (`app/layout.tsx`):
   ```tsx
   <Script
     src="https://cdn.platform.openai.com/deployments/chatkit/chatkit.js"
     strategy="beforeInteractive"
   />
   ```

3. Create ChatWidget component from `ChatWidget.tsx.tpl`:
   - Configure getClientSecret to fetch from your backend.
   - Add error handling and loading states.

4. Create backend session endpoint (FastAPI):
   - Return client_secret for ChatKit authentication.

5. Add ChatWidget to your pages:
   - As a dedicated chat page.
   - As a floating toggle button.
   - As an embedded component.

After this, Claude should consistently generate ChatKit integration code that
matches the same structure, making your chat UIs easier to maintain and extend.

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `@openai/chatkit-react` | React bindings for ChatKit |
| `chatkit.js` (CDN) | Core ChatKit functionality |
| `next` | React framework with App Router |
| `tailwindcss` | Styling (optional but recommended) |

## Related Skills

- `openai-agents-sdk-mcp-backend` - For the backend AI agent.
- `nextjs-16-app-router-structure` - For Next.js project structure.
- `nextjs-better-auth-jwt-usage` - For authentication integration.
- `nextjs-frontend-api-client-patterns` - For API client setup.
