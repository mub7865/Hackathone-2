<!--
Sync Impact Report:
- Version change: 2.1.0 → 3.0.0 (major update for comprehensive hackathon requirements)
- Modified principles: Expanded with Feature Levels, Stateless Architecture, Event-Driven patterns
- Added sections:
  - Feature Level Progression (Basic, Intermediate, Advanced)
  - Stateless Architecture Requirements (Phase III)
  - Event-Driven Architecture (Phase V)
  - AIOps Tools Specification
  - MCP Tools Requirements
  - Dapr Building Blocks
  - Bonus Features (Reusable Intelligence, Cloud-Native Blueprints)
- Removed sections: None (all previous content preserved)
- Templates requiring updates:
  - ✅ plan-template.md: Constitution Check section updated for new principles
  - ✅ spec-template.md: Requirements aligned with new principles
  - ✅ tasks-template.md: Task categorization updated for new principles
- Follow-up TODOs: None
-->

# The Evolution of Todo [Hackathon II] - From Console to Cloud-Native AI Constitution

## Core Principles

### Strict Spec-Driven Development (SDD)
No code is written without a corresponding approved specification in the `specs/` folder. All changes must be made to specs first, then implemented by AI. This ensures clear requirements and testable outcomes throughout the multi-phase evolution from console app to cloud-native deployment.

### AI-Native Architecture
The system must be designed for AI agents (MCP, OpenAI SDK) from the ground up, not just as an add-on. This includes proper integration with AI tools, agent capabilities, and intelligent automation throughout the architecture. All deployment and infrastructure operations must leverage AIOps tools (Gordon, kubectl-ai, kagent).

### Progressive Evolution
The architecture must support evolving from a Monolithic Console App to a Distributed Microservices architecture without complete rewrites. Each phase builds incrementally on the previous one with proper abstraction layers and clear interfaces.

### Documentation First
Every feature, API endpoint, and database schema must be documented in Markdown specs before implementation. This ensures clear communication, proper planning, and maintainable code across all team members and AI agents.

### Stateless Architecture (Phase III+)
All services must be stateless with state persisted to database. Chat endpoints must not hold conversation state in memory. MCP tools must be stateless and store all state in the database. This enables horizontal scaling and resilience.

### Event-Driven Architecture (Phase V)
Services must communicate through events (Kafka) rather than direct API calls. This enables loose coupling, scalability, and independent service evolution. All task operations must publish events for consumption by specialized services (notifications, recurring tasks, audit logs).

## Feature Level Progression

### Basic Level (Phases I-III)
Core essentials - quick to build, essential for any MVP:
1. **Add Task** - Create new todo items
2. **Delete Task** - Remove tasks from the list
3. **Update Task** - Modify existing task details
4. **View Task List** - Display all tasks
5. **Mark as Complete** - Toggle task completion status

### Intermediate Level (Phase V)
Organization & usability features:
1. **Priorities & Tags/Categories** - Assign levels (high/medium/low) or labels (work/home)
2. **Search & Filter** - Search by keyword; filter by status, priority, or date
3. **Sort Tasks** - Reorder by due date, priority, or alphabetically

### Advanced Level (Phase V)
Intelligent features:
1. **Recurring Tasks** - Auto-reschedule repeating tasks (e.g., "weekly meeting")
2. **Due Dates & Time Reminders** - Set deadlines with date/time pickers; browser notifications

## Key Standards and Constraints

### Monorepo Structure
Strict adherence to the provided `hackathon-todo` monorepo structure:
```
hackathon-todo/
├── .specify/              # Spec-Kit Plus configuration
├── specs/                 # All specifications
│   ├── features/         # Feature specs
│   ├── api/              # API endpoint specs
│   ├── database/         # Schema specs
│   └── ui/               # UI component specs
├── frontend/             # Next.js application
├── backend/              # FastAPI application
├── CLAUDE.md             # Root Claude Code instructions
└── README.md
```

### Tech Stack Adherence

**Phase I: Console App**
- Python 3.13+
- UV package manager
- In-Memory storage
- Claude Code + Spec-Kit Plus

**Phase II: Full-Stack Web App**
- Frontend: Next.js 16+ (App Router), TypeScript, Tailwind CSS
- Backend: Python FastAPI, SQLModel ORM
- Database: Neon Serverless PostgreSQL
- Authentication: Better Auth with JWT
- Deployment: Vercel (frontend), Backend API hosting

**Phase III: AI Chatbot**
- Frontend: OpenAI ChatKit
- AI Framework: OpenAI Agents SDK
- MCP Server: Official MCP Python SDK
- Architecture: Stateless chat endpoint with database-persisted conversation state
- Database Models: Task, Conversation, Message

**Phase IV: Local Kubernetes**
- Containerization: Docker with Docker Desktop
- AIOps: Docker AI Agent (Gordon) for intelligent Docker operations
- Orchestration: Kubernetes (Minikube)
- Package Manager: Helm Charts
- AI DevOps: kubectl-ai and kagent for intelligent K8s operations
- Deployment: Local Minikube cluster

**Phase V: Cloud Deployment**
- Event Streaming: Kafka (Redpanda Cloud Serverless)
- Distributed Runtime: Dapr (Pub/Sub, State, Bindings, Secrets, Service Invocation)
- Cloud Platform: DigitalOcean Kubernetes (DOKS) or Google Cloud (GKE) or Azure (AKS)
- CI/CD: GitHub Actions
- Monitoring: Prometheus, Grafana

### AIOps Tools Requirements

**Docker AI Agent (Gordon) - Phase IV**
- Use for intelligent Docker operations
- Generate Dockerfiles via AI assistance
- Optimize container builds
- Troubleshoot container issues
- Command: `docker ai "What can you do?"`

**kubectl-ai - Phase IV**
- Use for intelligent Kubernetes operations
- Generate K8s manifests via natural language
- Deploy and scale applications
- Troubleshoot pod failures
- Command: `kubectl-ai "deploy the todo frontend with 2 replicas"`

**kagent - Phase IV**
- Use for advanced cluster management
- Analyze cluster health
- Optimize resource allocation
- Advanced troubleshooting
- Command: `kagent "analyze the cluster health"`

### MCP Tools Requirements (Phase III)

All 5 MCP tools must be implemented as stateless functions that interact with the database:

1. **add_task**
   - Parameters: user_id (string, required), title (string, required), description (string, optional)
   - Returns: task_id, status, title
   - Behavior: Create new task in database

2. **list_tasks**
   - Parameters: user_id (string, required), status (string, optional: "all", "pending", "completed")
   - Returns: Array of task objects
   - Behavior: Retrieve tasks from database with filtering

3. **complete_task**
   - Parameters: user_id (string, required), task_id (integer, required)
   - Returns: task_id, status, title
   - Behavior: Mark task as complete in database

4. **delete_task**
   - Parameters: user_id (string, required), task_id (integer, required)
   - Returns: task_id, status, title
   - Behavior: Remove task from database

5. **update_task**
   - Parameters: user_id (string, required), task_id (integer, required), title (string, optional), description (string, optional)
   - Returns: task_id, status, title
   - Behavior: Modify task in database

**Agent Behavior Specification:**
- Task Creation: When user mentions adding/creating/remembering something, use add_task
- Task Listing: When user asks to see/show/list tasks, use list_tasks with appropriate filter
- Task Completion: When user says done/complete/finished, use complete_task
- Task Deletion: When user says delete/remove/cancel, use delete_task
- Task Update: When user says change/update/rename, use update_task
- Confirmation: Always confirm actions with friendly response
- Error Handling: Gracefully handle task not found and other errors

### Stateless Architecture Requirements (Phase III)

**Chat Endpoint Flow:**
1. Receive user message
2. Fetch conversation history from database
3. Build message array for agent (history + new message)
4. Store user message in database
5. Run agent with MCP tools
6. Agent invokes appropriate MCP tool(s)
7. Store assistant response in database
8. Return response to client
9. Server holds NO state (ready for next request)

**Benefits:**
- Scalability: Any server instance can handle any request
- Resilience: Server restarts don't lose conversation state
- Horizontal scaling: Load balancer can route to any backend
- Testability: Each request is independent and reproducible

### Event-Driven Architecture (Phase V)

**Kafka Topics:**

| Topic | Producer | Consumer | Purpose |
|-------|----------|----------|---------|
| **task-events** | Chat API (MCP Tools) | Recurring Task Service, Audit Service | All task CRUD operations |
| **reminders** | Chat API (when due date set) | Notification Service | Scheduled reminder triggers |
| **task-updates** | Chat API | WebSocket Service | Real-time client sync |

**Event Schema - Task Event:**
- event_type: string ("created", "updated", "completed", "deleted")
- task_id: integer
- task_data: object (full task object)
- user_id: string
- timestamp: datetime

**Event Schema - Reminder Event:**
- task_id: integer
- title: string
- due_at: datetime
- remind_at: datetime
- user_id: string

**Use Cases:**
1. **Reminder/Notification System**: Task with due date → Kafka → Notification Service → User Device
2. **Recurring Task Engine**: Task completed → Kafka → Recurring Task Service → Creates next occurrence
3. **Activity/Audit Log**: All operations → Kafka → Audit Service → Complete history
4. **Real-time Sync**: Task changed → Kafka → WebSocket Service → All connected clients

### Dapr Building Blocks (Phase V)

**Required Dapr Components:**

1. **Pub/Sub (pubsub.kafka)**
   - Purpose: Kafka abstraction for event streaming
   - Usage: Publish/subscribe without Kafka client code
   - Topics: task-events, reminders, task-updates

2. **State Management (state.postgresql)**
   - Purpose: Conversation state storage
   - Usage: Alternative to direct DB calls
   - Benefits: Abstracted state operations

3. **Service Invocation**
   - Purpose: Frontend → Backend communication
   - Usage: Built-in service discovery, retries, mTLS
   - Benefits: Automatic discovery, no hardcoded URLs

4. **Bindings (bindings.cron)**
   - Purpose: Scheduled reminder checks
   - Usage: Trigger reminder checks on schedule
   - Schedule: Every 5 minutes (configurable)

5. **Secrets Management (secretstores.kubernetes)**
   - Purpose: Secure credential storage
   - Usage: API keys, DB credentials
   - Benefits: No secrets in code or env vars

**Dapr Benefits:**
- Single HTTP API for all infrastructure
- Swap backends (Kafka → RabbitMQ) with config change
- Built-in retries and circuit breakers
- Automatic service discovery
- Vendor lock-in prevention

### Code Quality Standards

- **Type Safety**: Type-safe Python (type hints) and TypeScript
- **Clean Architecture**: Separation of concerns, dependency injection
- **Error Handling**: Comprehensive error handling with proper HTTP status codes
- **Testing**: All critical paths must be testable via defined specs
- **Documentation**: Inline comments for complex logic, comprehensive README files
- **Security**: JWT validation, input sanitization, SQL injection prevention

### Deployment Standards

- **Dockerfiles**: Multi-stage builds, non-root users, minimal base images
- **Kubernetes Manifests**: Resource limits, health probes, HPA, PDB
- **Helm Charts**: Parameterized deployments, multi-environment support
- **CI/CD**: Automated testing, security scanning, deployment pipelines
- **Monitoring**: Prometheus metrics, Grafana dashboards, alerting

### Security Requirements

- **Authentication**: Better Auth with JWT tokens
- **Authorization**: User isolation (users can only access their own data)
- **API Security**: JWT validation on all protected endpoints
- **Secrets Management**: No secrets in code, use environment variables or Dapr secrets
- **Database Security**: Parameterized queries (SQLModel handles this)
- **Container Security**: Non-root users, vulnerability scanning

## Bonus Features (Optional - Extra Points)

### Reusable Intelligence (+200 Points)
Create and use reusable intelligence via Claude Code:
- **Subagents**: Specialized agents for specific domains (backend, frontend, DevOps, testing)
- **Agent Skills**: Reusable patterns and templates for common tasks
- **Benefits**: Faster development, consistent patterns, knowledge reuse
- **Location**: `.claude/agents/` and `.claude/skills/` directories
- **Examples**: backend-api-agent, database-agent, devops-agent, testing-agent

### Cloud-Native Blueprints (+200 Points)
Create and use Cloud-Native Blueprints via Agent Skills:
- **Deployment Blueprints**: Spec-driven deployment patterns
- **Infrastructure as Code**: Terraform/Helm templates
- **AIOps Integration**: kubectl-ai and kagent patterns
- **Benefits**: Repeatable deployments, infrastructure automation
- **Location**: `.claude/skills/` with deployment-specific templates
- **Examples**: kubernetes-deployment-patterns, docker-containerization, cloud-deployment

### Multi-language Support (+100 Points)
- Support Urdu in chatbot
- Localization framework
- Language detection and switching

### Voice Commands (+200 Points)
- Add voice input for todo commands
- Speech-to-text integration
- Voice feedback

## Success Criteria

### Phase I: Console App (100 Points)
- ✅ Working Console App managing state in memory
- ✅ All 5 Basic Level features implemented
- ✅ Spec-driven development with Claude Code
- ✅ Clean Python code with type hints
- ✅ Proper error handling

### Phase II: Full-Stack Web App (150 Points)
- ✅ Functional Full-Stack Web App with Auth and DB persistence
- ✅ All 5 Basic Level features as web application
- ✅ RESTful API endpoints
- ✅ Responsive frontend interface
- ✅ Better Auth with JWT integration
- ✅ User isolation (users see only their own tasks)
- ✅ Deployed on Vercel (frontend) and backend hosting

### Phase III: AI Chatbot (200 Points)
- ✅ AI Chatbot managing Todo state via Natural Language
- ✅ OpenAI ChatKit frontend
- ✅ OpenAI Agents SDK integration
- ✅ Official MCP Python SDK with 5 required tools
- ✅ Stateless chat endpoint with database-persisted state
- ✅ Natural language understanding for all Basic Level operations
- ✅ Conversation history maintained across sessions

### Phase IV: Local Kubernetes (250 Points)
- ✅ Successful local deployment on Minikube
- ✅ Docker containerization with Gordon AI assistance
- ✅ Helm charts for deployment
- ✅ kubectl-ai and kagent usage for K8s operations
- ✅ Health probes, resource limits, HPA configured
- ✅ All Phase III features working in K8s environment

### Phase V: Cloud Deployment (300 Points)
- ✅ Distributed Event-Driven system (Kafka/Dapr) on Cloud
- ✅ All Advanced Level features implemented (Recurring Tasks, Reminders)
- ✅ All Intermediate Level features implemented (Priorities, Tags, Search, Filter, Sort)
- ✅ Kafka (Redpanda Cloud) integration with 3 topics
- ✅ Dapr with all 5 building blocks (Pub/Sub, State, Service Invocation, Bindings, Secrets)
- ✅ Deployed on DigitalOcean K8s (DOKS) or GKE or AKS
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Monitoring and logging configured

### All Phases
- ✅ Proper error handling for invalid operations
- ✅ Clean, readable code with appropriate comments and documentation
- ✅ Adherence to spec-driven development methodology
- ✅ Following the defined tech stack and architecture principles
- ✅ Comprehensive README with setup instructions
- ✅ Demo video (max 90 seconds)

## Governance

### Development Process
- All development must follow spec-driven methodology using Claude Code across all 5 phases
- Code must adhere to appropriate language standards and include type hints
- Each phase must meet its specific requirements and success criteria
- Error handling required for all operations across all phases
- Strict adherence to the defined tech stack for each phase

### Change Management
- All changes must be tracked with Prompt History Records (PHRs)
- No manual code changes without spec updates (except minor syntax fixes)
- Logic changes require Spec updates first, then implementation
- Each phase must be completed before moving to the next
- Architecture must support progressive evolution without major rewrites

### Quality Assurance
- All critical paths must be testable
- Type safety enforced (Python type hints, TypeScript)
- Security best practices followed (JWT, input validation, secrets management)
- Performance requirements met (stateless architecture, horizontal scaling)
- Documentation complete (specs, README, inline comments)

### AIOps Integration
- Use Gordon for Docker operations (Phase IV+)
- Use kubectl-ai for Kubernetes operations (Phase IV+)
- Use kagent for advanced cluster management (Phase IV+)
- Generate infrastructure via AI tools, not manual YAML writing
- Document AI-generated configurations in specs

### Bonus Features (Optional)
- Reusable Intelligence: Create subagents and skills (+200 points)
- Cloud-Native Blueprints: Create deployment blueprints (+200 points)
- Multi-language Support: Add Urdu support (+100 points)
- Voice Commands: Add voice input (+200 points)

### Submission Requirements
- Public GitHub repository with all source code
- Deployed application links (Vercel, backend API, K8s)
- Demo video (max 90 seconds)
- WhatsApp number for presentation invitation

**Version**: 3.0.0 | **Ratified**: 2026-01-10 | **Last Amended**: 2026-01-10
