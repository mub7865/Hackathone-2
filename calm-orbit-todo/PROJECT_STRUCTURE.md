# Calm Orbit Todo - Project Structure

## Directory Organization

```
hackathon-2/
├── .claude/                           # Claude Code agents and skills
├── .specify/                          # Spec-Kit Plus configuration
├── specs/                             # Feature specifications
├── history/                           # Prompt history records
├── CLAUDE.md                          # Root Claude Code instructions
├── Hackathon II - Todo Spec-Driven Development.md
│
└── calm-orbit-todo/                   # 🎯 MAIN PROJECT (All Phases)
    │
    ├── README.md                      # Project overview
    ├── PROJECT_STRUCTURE.md           # This file
    ├── QUICK_START.md                 # Quick start guide
    │
    ├── phase1-console/                # ✅ Phase I: Python Console App
    │   ├── src/                       # Source code
    │   ├── tests/                     # Unit tests
    │   └── README.md                  # Phase 1 documentation
    │
    ├── phase2-3-fullstack/            # ✅ Phase II-III: Full-Stack + AI
    │   │
    │   ├── README.md                  # Phase 2-3 overview
    │   │
    │   ├── frontend/                  # Next.js Frontend
    │   │   ├── app/                   # Next.js App Router
    │   │   ├── components/            # React components
    │   │   │   ├── chat/              # ChatKit components
    │   │   │   ├── layout/            # Layout components
    │   │   │   ├── tasks/             # Task components
    │   │   │   └── ui/                # Base UI components
    │   │   ├── lib/                   # Utilities
    │   │   │   ├── api/               # API client
    │   │   │   ├── auth/              # Authentication
    │   │   │   └── features/          # Feature flags
    │   │   ├── .env.local             # Environment variables
    │   │   ├── Dockerfile             # Docker image config
    │   │   └── README.md              # Frontend documentation
    │   │
    │   └── backend/                   # FastAPI Backend
    │       ├── app/                   # Application code
    │       │   ├── api/               # REST API routes
    │       │   ├── core/              # Core functionality
    │       │   ├── models/            # Database models
    │       │   ├── schemas/           # Pydantic schemas
    │       │   └── services/          # Business logic
    │       │       ├── agent.py       # OpenAI Agents SDK
    │       │       ├── mcp_server.py  # MCP server
    │       │       └── mcp_tools.py   # MCP tools
    │       ├── alembic/               # Database migrations
    │       ├── tests/                 # Test suite
    │       ├── .env                   # Environment variables
    │       ├── Dockerfile             # Docker image config
    │       └── README.md              # Backend documentation
    │
    ├── phase4-k8s-deployment/         # ✅ Phase IV: Kubernetes
    │   ├── helm-charts/               # Helm chart
    │   │   ├── templates/             # K8s manifests
    │   │   ├── Chart.yaml             # Chart metadata
    │   │   └── values.yaml            # Configuration
    │   ├── backend.Dockerfile         # Backend Docker config
    │   ├── frontend.Dockerfile        # Frontend Docker config
    │   └── README.md                  # Deployment guide
    │
    └── phase5-cloud/                  # 🚧 Phase V: Cloud (Coming Soon)
        └── README.md                  # Phase 5 placeholder
```

## Phase Status

| Phase | Status | Location | Description |
|-------|--------|----------|-------------|
| **Phase I** | ✅ Complete | `phase1-console/` | Python console app with in-memory storage |
| **Phase II** | ✅ Complete | `phase2-3-fullstack/` | Full-stack web app with database |
| **Phase III** | ✅ Complete | `phase2-3-fullstack/` | AI chatbot with MCP tools |
| **Phase IV** | ✅ Complete | `phase4-k8s-deployment/` | Kubernetes deployment |
| **Phase V** | 🚧 Planned | `phase5-cloud/` | Cloud deployment with Kafka/Dapr |

## Quick Navigation

### Development
- **Frontend Dev**: `cd phase2-3-fullstack/frontend && npm run dev`
- **Backend Dev**: `cd phase2-3-fullstack/backend && uvicorn app.main:app --reload`

### Kubernetes
- **Deploy**: `cd phase4-k8s-deployment && helm install todo-chatbot ./helm-charts -n todo-app`
- **Access**: Port-forward to localhost:3000 (frontend) and localhost:8001 (backend)

### Documentation
- **Specs**: `/specs/` directory
- **History**: `/history/prompts/` directory
- **Phase READMEs**: Each phase directory has its own README.md

## Key Files

- `CLAUDE.md` - Root Claude Code instructions
- `calm-orbit-todo/README.md` - Main project overview
- `phase*/README.md` - Phase-specific documentation
- `.env` / `.env.local` - Environment configuration (not in git)

## Technology Stack by Phase

### Phase I
- Python 3.13+, UV

### Phase II-III
- **Frontend**: Next.js 16, TypeScript, Tailwind CSS, Better Auth, OpenAI ChatKit
- **Backend**: FastAPI, SQLModel, OpenAI Agents SDK, Official MCP SDK
- **Database**: Neon Serverless PostgreSQL

### Phase IV
- Docker, Kubernetes, Minikube, Helm

### Phase V (Planned)
- Kafka (Redpanda Cloud), Dapr, DigitalOcean DOKS
