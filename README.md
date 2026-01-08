# Calm Orbit Todo - Hackathon II Project

A progressive todo application built using Spec-Driven Development, evolving from a simple console app to a cloud-native AI chatbot.

## Project Structure

```
calm-orbit-todo/
├── phase1-console/              # Phase I: Python Console App
├── phase2-3-fullstack/          # Phase II-III: Full-Stack Web App + AI Chatbot
│   ├── frontend/                # Next.js 16 frontend
│   └── backend/                 # FastAPI backend with AI
├── phase4-k8s-deployment/       # Phase IV: Kubernetes/Helm Deployment
└── phase5-cloud/                # Phase V: Advanced Cloud Deployment (Coming Soon)
```

## Phases Overview

### Phase I: Console App ✅
- In-memory Python todo application
- Basic CRUD operations
- Location: `phase1-console/`

### Phase II: Full-Stack Web App ✅
- Next.js 16 frontend with App Router
- FastAPI backend with SQLModel
- Neon PostgreSQL database
- Better Auth authentication
- Location: `phase2-3-fullstack/`

### Phase III: AI Chatbot ✅
- OpenAI ChatKit integration
- OpenAI Agents SDK
- Official MCP SDK
- Natural language task management
- Location: `phase2-3-fullstack/` (integrated with Phase II)

### Phase IV: Kubernetes Deployment ✅
- Docker containerization
- Helm charts
- Minikube local deployment
- Location: `phase4-k8s-deployment/`

### Phase V: Cloud Deployment 🚧
- Kafka event streaming
- Dapr distributed runtime
- DigitalOcean DOKS deployment
- Location: `phase5-cloud/` (Coming Soon)

## Quick Start

### Phase II-III: Full-Stack Application

**Frontend:**
```bash
cd phase2-3-fullstack/frontend
npm install
npm run dev
```

**Backend:**
```bash
cd phase2-3-fullstack/backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Phase IV: Kubernetes Deployment

```bash
cd phase4-k8s-deployment
helm install todo-chatbot ./helm-charts -n todo-app --create-namespace
```

## Technology Stack

- **Frontend**: Next.js 16, TypeScript, Tailwind CSS, OpenAI ChatKit
- **Backend**: Python 3.13+, FastAPI, SQLModel, OpenAI Agents SDK
- **Database**: Neon Serverless PostgreSQL
- **Authentication**: Better Auth with JWT
- **Deployment**: Docker, Kubernetes, Helm
- **AI**: OpenAI Agents SDK, MCP Protocol

## Features

### Basic Level (Implemented)
- ✅ Add Task
- ✅ Delete Task
- ✅ Update Task
- ✅ View Task List
- ✅ Mark as Complete

### AI Chatbot (Implemented)
- ✅ Natural language task management
- ✅ Conversational interface
- ✅ MCP tools integration
- ✅ Stateless architecture

### Cloud Native (Implemented)
- ✅ Docker containerization
- ✅ Kubernetes deployment
- ✅ Helm charts
- ✅ Horizontal scalability

## Access URLs

**Local Development:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000

**Kubernetes (Minikube):**
- Frontend: http://localhost:3000 (via port-forward)
- Backend API: http://localhost:8001 (via port-forward)

## Environment Variables

See `.env.example` files in respective directories for required configuration.

## Documentation

- Project specs: `/specs/`
- Implementation history: `/history/`
- Claude Code instructions: `CLAUDE.md` files
- Quick Start: `QUICK_START.md`
- Project Structure: `PROJECT_STRUCTURE.md`

## License

MIT License - Hackathon II Project
