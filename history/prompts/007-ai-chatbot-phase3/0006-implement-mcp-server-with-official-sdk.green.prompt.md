---
id: "0006"
title: "Implement MCP Server with Official SDK"
stage: green
date: 2025-12-20
surface: agent
model: claude-sonnet-4-5-20250929
feature: 007-ai-chatbot-phase3
branch: main
user: developer
command: /sp.implement
labels: ["mcp-server", "official-sdk", "hackathon-fix", "phase3"]
links:
  spec: specs/007-ai-chatbot-phase3/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - phase2/backend/app/services/mcp_server.py
  - phase2/backend/app/services/agent.py
  - phase2/backend/app/api/v1/chat.py
  - specs/007-ai-chatbot-phase3/tasks.md
tests:
  - "python -c 'from app.services.mcp_server import mcp; print(mcp.name)'"
  - "python -c 'from app.services.agent import get_agent; print([t.name for t in get_agent().tools])'"
  - "python -c 'from app.main import app; print(\"FastAPI app loaded\")'"
---

## Prompt

okay ab jo humse mistak hoi thi uske baad humne @specs\007-ai-chatbot-phase3\ ko updated karliya ab isko implement karo

User requested implementation of MCP Server using Official MCP SDK (@mcp.tool() decorator) instead of previously used @function_tool from OpenAI Agents SDK. The specs were already updated to reflect the correct approach.

## Response snapshot

Created MCP Server implementation with Official MCP SDK:

1. **mcp_server.py** (NEW): FastMCP server with 5 tools using @mcp.tool() decorator
   - add_task, list_tasks, complete_task, delete_task, update_task
   - Context management for database session and user isolation

2. **agent.py** (UPDATED): Imports MCP tool implementations and wraps them with @function_tool
   - Same logic, dual compliance (MCP standard + Agent SDK)
   - No separate HTTP server needed

3. **chat.py** (UPDATED): Import paths adjusted to use new module

Architecture: MCP Server embedded in FastAPI, agent uses wrapped MCP tools, works on Vercel without separate deployment.

## Outcome

- ✅ Impact: Fixed hackathon requirement - MCP Server now uses Official MCP SDK (@mcp.tool())
- 🧪 Tests: All imports verified working, FastAPI app loads with correct routes
- 📁 Files: 3 files modified/created
- 🔁 Next prompts: Test chatbot end-to-end, deploy to Vercel
- 🧠 Reflection: Embedded MCP server approach meets both hackathon spec and deployment constraints

## Evaluation notes (flywheel)

- Failure modes observed: Initial mcp.get_tools() attempt failed - FastMCP uses list_tools() not get_tools()
- Graders run and results (PASS/FAIL): PASS - All imports work, tools list correct
- Prompt variant (if applicable): N/A
- Next experiment (smallest change to try): Test actual chat endpoint with API call
