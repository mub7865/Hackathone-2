---
id: "0007"
title: Implement MCP HTTP Transport Architecture
stage: green
date: 2025-12-21
surface: agent
model: claude-sonnet-4-5-20250929
feature: 007-ai-chatbot-phase3
branch: main
user: developer
command: /sp.implement
labels: ["mcp", "http-transport", "agent", "openai-agents-sdk"]
links:
  spec: specs/007-ai-chatbot-phase3/spec.md
  ticket: null
  adr: null
  pr: null
files:
  - phase2/backend/app/services/agent.py
  - phase2/backend/app/services/mcp_server.py
  - phase2/backend/app/main.py
  - phase2/backend/app/api/v1/chat.py
  - specs/007-ai-chatbot-phase3/tasks.md
tests:
  - python -c "from app.services.mcp_server import mcp; print('MCP Server imported OK')"
  - python -c "from app.main import app; print('FastAPI app imported OK')"
  - python -c "from app.services.agent import create_mcp_agent; print('Agent imported OK')"
---

## Prompt

okay ab isko implement karte hain jese humne discus kiya or humne @specs\007-ai-chatbot-phase3\ ko update kiya

(Translation: Now let's implement this as we discussed and updated in the specs)

User wanted to implement the MCP HTTP transport architecture as documented in the updated specs:
- MCP Server mounted at /mcp endpoint via `app.mount("/mcp", mcp.streamable_http_app())`
- Agent connects via `mcp_servers=[MCPServerStreamableHttp(url="/mcp")]`
- Tools receive user_id as parameter (injected via agent instructions)
- Each tool creates its own database session

## Response snapshot

Implemented MCP HTTP transport architecture following the updated specs:

1. **T008: Updated agent.py** - Changed from `MCPServerStdio` to `MCPServerStreamableHttp`
   - `create_mcp_agent(user_id)` now connects via HTTP to `/mcp` endpoint
   - Agent instructions include user_id for tool calls
   - Uses `mcp_servers=[mcp_server]` parameter (correct MCP integration)

2. **T011: Updated main.py** - Mounted MCP Server at `/mcp`
   - Added `app.mount("/mcp", mcp.streamable_http_app())`
   - Imported `mcp` from `app.services.mcp_server`

3. **Updated mcp_server.py** - Tools now accept user_id parameter
   - All 5 tools (add_task, list_tasks, complete_task, delete_task, update_task) accept `user_id` as first param
   - Each tool creates its own database session via `get_db_session()`
   - Proper session commit/rollback/close handling

4. **Updated chat.py** - Pass user_id to create_mcp_agent
   - `create_mcp_agent(current_user)` provides user context
   - Agent instructions include user_id for data isolation

## Outcome

- Impact: Completed T008 and T011 - MCP HTTP transport now properly implemented
- Tests: All import tests pass (mcp_server, main, agent)
- Files: 4 backend files modified, tasks.md updated
- Next prompts: Test with actual chat flow, verify tool calls include user_id
- Reflection: HTTP transport is cleaner than stdio subprocess - shares database connection through session factory

## Evaluation notes (flywheel)

- Failure modes observed: Initial import error for database module (fixed path from app.core.database to app.database)
- Graders run and results (PASS/FAIL): PASS - All Python imports successful
- Prompt variant (if applicable): N/A
- Next experiment: End-to-end test with actual LLM to verify tool discovery and user_id passing
