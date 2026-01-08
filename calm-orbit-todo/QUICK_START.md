# Quick Start Guide - Calm Orbit Todo

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- Python 3.13+
- Docker Desktop
- Minikube
- kubectl
- Helm

## 📁 Project Structure

```
calm-orbit-todo/
├── phase1-console/              # Phase I: Python Console App
├── phase2-3-fullstack/          # Phase II-III: Full-Stack + AI
│   ├── frontend/                # Next.js frontend
│   └── backend/                 # FastAPI backend
├── phase4-k8s-deployment/       # Phase IV: Kubernetes
└── phase5-cloud/                # Phase V: Cloud (Coming Soon)
```

## 🏃 Running the Application

### Option 1: Local Development (Recommended for Development)

**Terminal 1 - Backend:**
```bash
cd calm-orbit-todo/phase2-3-fullstack/backend
pip install -r requirements.txt
uvicorn app.main:app --reload
```
Access: http://localhost:8000

**Terminal 2 - Frontend:**
```bash
cd calm-orbit-todo/phase2-3-fullstack/frontend
npm install
npm run dev
```
Access: http://localhost:3000

### Option 2: Kubernetes (Recommended for Testing Deployment)

**Already Running! ✅**
- Frontend: http://localhost:3000
- Backend: http://localhost:8001

**To redeploy:**
```bash
cd calm-orbit-todo/phase4-k8s-deployment
helm upgrade todo-chatbot ./helm-charts -n todo-app
```

## 🧪 Testing the Application

### 1. Register a New User
```bash
curl -X POST http://localhost:8001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","name":"Test User"}'
```

### 2. Login
```bash
curl -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### 3. Create a Task
```bash
TOKEN="your-token-here"
curl -X POST http://localhost:8001/api/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"My First Task","description":"Test task"}'
```

### 4. List Tasks
```bash
curl -X GET http://localhost:8001/api/v1/tasks \
  -H "Authorization: Bearer $TOKEN"
```

## 🌐 Access URLs

### Local Development
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

### Kubernetes (Current)
- Frontend: http://localhost:3000 (port-forward)
- Backend API: http://localhost:8001 (port-forward)
- Health Check: http://localhost:8001/health

## 🔧 Configuration

### Backend Environment (.env)
Location: `phase2-3-fullstack/backend/.env`
```env
DATABASE_URL=postgresql://user:pass@host.neon.tech/db?sslmode=require
BETTER_AUTH_SECRET=your-secret-key-min-32-chars
JWT_SECRET=your-jwt-secret
OPENAI_API_KEY=sk-proj-...
```

### Frontend Environment (.env.local)
Location: `phase2-3-fullstack/frontend/.env.local`
```env
NEXT_PUBLIC_API_URL=http://localhost:8000
BETTER_AUTH_SECRET=your-secret-key-min-32-chars
DATABASE_URL=postgresql://user:pass@host:5432/db
```

## 🎯 Feature Flags

### Enable Better Auth
```env
# Backend
FEATURE_NEW_AUTH=true

# Frontend
NEXT_PUBLIC_FEATURE_NEW_AUTH=true
```

### Enable ChatKit
```env
# Backend
FEATURE_NEW_CHAT=true

# Frontend
NEXT_PUBLIC_FEATURE_NEW_CHAT=true
```

## 📊 Kubernetes Commands

### Check Status
```bash
kubectl get pods -n todo-app
kubectl get services -n todo-app
```

### View Logs
```bash
kubectl logs -n todo-app deployment/backend-deployment
kubectl logs -n todo-app deployment/frontend-deployment
```

### Restart Deployment
```bash
kubectl rollout restart deployment/backend-deployment -n todo-app
kubectl rollout restart deployment/frontend-deployment -n todo-app
```

## 🐛 Troubleshooting

### Backend Not Connecting to Database
1. Check DATABASE_URL in `phase2-3-fullstack/backend/.env`
2. Verify Neon database is accessible
3. Check backend logs: `kubectl logs -n todo-app deployment/backend-deployment`

### Frontend Not Loading
1. Check if port 3000 is available
2. Verify port-forward is running: `ps aux | grep port-forward`
3. Restart port-forward if needed

### Kubernetes Pods Not Starting
1. Check pod status: `kubectl describe pod -n todo-app <pod-name>`
2. Verify Docker images are loaded: `minikube image ls`
3. Check secrets: `kubectl get secrets -n todo-app`

## 📚 Documentation

- **Main README**: `calm-orbit-todo/README.md`
- **Project Structure**: `calm-orbit-todo/PROJECT_STRUCTURE.md`
- **Phase 2-3 README**: `calm-orbit-todo/phase2-3-fullstack/README.md`
- **API Docs**: http://localhost:8000/docs (when backend is running)

## ✅ Verification Checklist

- [ ] Backend health check responds: `curl http://localhost:8001/health`
- [ ] Frontend loads in browser: http://localhost:3000
- [ ] Can register new user
- [ ] Can login with credentials
- [ ] Can create tasks
- [ ] Can view tasks
- [ ] Can update tasks
- [ ] Can delete tasks
- [ ] Chatbot page accessible: http://localhost:3000/chatbot

## 🎉 You're All Set!

The application is now running and ready for testing. Open http://localhost:3000 in your browser to get started!
