<!--
Sync Impact Report:
- Version change: 2.0.0 → 2.1.0 (minor update for principle refinements)
- Modified principles: Updated to align with user-specified core principles and standards
- Added sections: Strict SDD, AI-Native Architecture, Progressive Evolution, Documentation First principles
- Removed sections: Previous principle-specific details
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
The system must be designed for AI agents (MCP, OpenAI SDK) from the ground up, not just as an add-on. This includes proper integration with AI tools, agent capabilities, and intelligent automation throughout the architecture.

### Progressive Evolution
The architecture must support evolving from a Monolithic Console App to a Distributed Microservices architecture without complete rewrites. Each phase builds incrementally on the previous one with proper abstraction layers and clear interfaces.

### Documentation First
Every feature, API endpoint, and database schema must be documented in Markdown specs before implementation. This ensures clear communication, proper planning, and maintainable code across all team members and AI agents.

## Key Standards and Constraints

- **Monorepo Structure:** Strict adherence to the provided `hackathon-todo` monorepo structure (frontend, backend, specs folders)
- **Tech Stack Adherence:**
  - Phase I: Python 3.13+, UV, In-Memory
  - Phase II: Next.js 16+ (App Router), FastAPI, SQLModel, Neon DB, Better Auth
  - Phase III: OpenAI ChatKit, Agents SDK, Official MCP Python SDK
  - Phase IV: Docker (Gordon), Minikube, Helm, kubectl-ai
  - Phase V: Kafka (Redpanda), Dapr, DigitalOcean K8s
- **Code Quality:** Type-safe Python and TypeScript. Clean Architecture.
- **Testing:** All critical paths must be testable via the defined specs
- **No "Vibe Coding":** Manual code edits are prohibited unless fixing minor syntax errors. Logic changes require Spec updates
- **Phase Logic:** Do not implement Phase III features in Phase I. Follow the strict progression
- **Deployment:** Deployment specs (Helm, Dockerfiles) must be generated via AI tools (Gordon/kubectl-ai) based on the architectural specs
- **Security:** JWT handling for Better Auth and FastAPI must be strictly typed and secure

## Success Criteria

- **Phase I:** Working Console App managing state in memory
- **Phase II:** Functional Full-Stack Web App with Auth and DB persistence
- **Phase III:** AI Chatbot managing Todo state via Natural Language (MCP)
- **Phase IV:** Successful local deployment on Minikube
- **Phase V:** Distributed Event-Driven system (Kafka/Dapr) on Cloud
- All phases: Proper error handling for invalid operations
- All phases: Clean, readable code with appropriate comments and documentation
- All phases: Adherence to spec-driven development methodology
- All phases: Following the defined tech stack and architecture principles

## Governance

- All development must follow spec-driven methodology using Claude Code across all 5 phases
- Code must adhere to appropriate language standards and include type hints
- Each phase must meet its specific requirements and success criteria
- Error handling required for all operations across all phases
- Strict adherence to the defined tech stack for each phase
- All changes must be tracked with Prompt History Records (PHRs)
- No manual code changes without spec updates (except minor syntax fixes)
- Each phase must be completed before moving to the next
- Architecture must support progressive evolution without major rewrites

**Version**: 2.1.0 | **Ratified**: 2025-12-10 | **Last Amended**: 2025-12-10
