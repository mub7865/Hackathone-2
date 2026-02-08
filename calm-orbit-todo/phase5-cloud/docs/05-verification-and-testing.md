# Verification and Testing Guide

**Time Required**: 30-45 minutes
**Purpose**: Verify all features work correctly in cloud deployment

---

## What We're Testing

This guide will verify:
1. ✅ Basic functionality (CRUD operations)
2. ✅ Authentication (Better Auth)
3. ✅ Phase 5 features (Recurring, Reminders, Priorities, Tags, Due Dates)
4. ✅ Event-driven architecture (Kafka events)
5. ✅ Database persistence
6. ✅ Performance and stability

---

## Prerequisites

✅ Application deployed to DOKS (from Guide 04)
✅ Backend and Frontend LoadBalancers working
✅ Access to kubectl and browser

---

## Step 1: Basic Health Checks

### 1.1 Check All Pods are Running

```bash
# Check pod status
kubectl get pods -n todo-app

# Expected output:
# NAME                                   READY   STATUS    RESTARTS   AGE
# backend-deployment-abc123-def456       1/1     Running   0          30m
# backend-deployment-abc123-ghi789       1/1     Running   0          30m
# frontend-deployment-abc123-jkl012     1/1     Running   0          25m
# frontend-deployment-abc123-mno345     1/1     Running   0          25m
```

**✅ Pass Criteria**: All pods show `Running` status and `1/1` ready.

### 1.2 Check Services

```bash
# Check services
kubectl get services -n todo-app

# Expected output:
# NAME               TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)        AGE
# backend-service    LoadBalancer   10.245.123.45    143.198.123.45    80:30001/TCP   30m
# frontend-service   LoadBalancer   10.245.67.89     143.198.67.89     80:30000/TCP   25m
```

**✅ Pass Criteria**: Both services have EXTERNAL-IP assigned.

### 1.3 Test Backend Health Endpoint

```bash
# Get backend IP
export BACKEND_IP=$(kubectl get service backend-service -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test health
curl http://$BACKEND_IP/health

# Expected output:
# {"status":"healthy","version":"1.3.2","database":"connected","kafka":"connected"}
```

**✅ Pass Criteria**: Returns healthy status with database and Kafka connected.

### 1.4 Test Frontend Accessibility

```bash
# Get frontend IP
export FRONTEND_IP=$(kubectl get service frontend-service -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test frontend
curl -I http://$FRONTEND_IP

# Expected output:
# HTTP/1.1 200 OK
# Content-Type: text/html
```

**✅ Pass Criteria**: Returns 200 OK status.

---

## Step 2: Authentication Testing

### 2.1 Open Frontend in Browser

```bash
# Display frontend URL
echo "Frontend URL: http://$FRONTEND_IP"
```

Open this URL in your browser.

### 2.2 Test Sign Up

1. **Click "Sign Up" or "Register"**
2. **Enter Details**:
   - Email: `test@example.com`
   - Password: `TestPassword123!`
   - Name: `Test User`
3. **Submit Form**
4. **Expected**: Successfully redirected to dashboard or login page

**✅ Pass Criteria**: Account created successfully, no errors.

### 2.3 Test Login

1. **Click "Login"**
2. **Enter Credentials**:
   - Email: `test@example.com`
   - Password: `TestPassword123!`
3. **Submit Form**
4. **Expected**: Successfully logged in, see dashboard with tasks

**✅ Pass Criteria**: Login successful, JWT token stored, dashboard visible.

### 2.4 Verify JWT Token

Open browser DevTools (F12):
1. Go to **Application** tab → **Local Storage**
2. Look for JWT token or session data
3. **Expected**: Token present and valid

**✅ Pass Criteria**: Authentication token exists.

### 2.5 Test Logout

1. **Click "Logout" button**
2. **Expected**: Redirected to login page, token cleared

**✅ Pass Criteria**: Logout successful, can't access protected pages.

---

## Step 3: Basic CRUD Operations Testing

### 3.1 Create Task

1. **Login** (if not already logged in)
2. **Click "Add Task" or "New Task"**
3. **Enter Task Details**:
   - Title: `Test Task 1`
   - Description: `This is a test task`
4. **Submit**
5. **Expected**: Task appears in task list

**✅ Pass Criteria**: Task created and visible in list.

### 3.2 Read Tasks

1. **View Task List**
2. **Expected**: See the task you just created

**✅ Pass Criteria**: Task list displays correctly.

### 3.3 Update Task

1. **Click on task** or **Edit button**
2. **Change Title**: `Test Task 1 - Updated`
3. **Save**
4. **Expected**: Task title updated in list

**✅ Pass Criteria**: Task updated successfully.

### 3.4 Complete Task

1. **Click checkbox** or **Mark as Complete**
2. **Expected**: Task marked as completed (strikethrough or moved to completed section)

**✅ Pass Criteria**: Task status changed to completed.

### 3.5 Delete Task

1. **Click Delete button** on task
2. **Confirm deletion** (if prompted)
3. **Expected**: Task removed from list

**✅ Pass Criteria**: Task deleted successfully.

---

## Step 4: Phase 5 Features Testing

### 4.1 Test Priorities

**Create High Priority Task**:
1. **Click "Add Task"**
2. **Enter**:
   - Title: `High Priority Task`
   - Priority: Select **"High"**
3. **Submit**
4. **Expected**: Task shows high priority indicator (red color/icon)

**Create Medium Priority Task**:
1. **Create another task** with Priority: **"Medium"**
2. **Expected**: Shows medium priority indicator (yellow/orange)

**Create Low Priority Task**:
1. **Create another task** with Priority: **"Low"**
2. **Expected**: Shows low priority indicator (green/gray)

**✅ Pass Criteria**: All three priority levels work and display correctly.

### 4.2 Test Tags

**Create Task with Tags**:
1. **Click "Add Task"**
2. **Enter**:
   - Title: `Tagged Task`
   - Tags: `work`, `urgent`, `meeting`
3. **Submit**
4. **Expected**: Task shows all three tags

**Filter by Tag** (if implemented):
1. **Click on a tag** (e.g., `work`)
2. **Expected**: Only tasks with that tag are shown

**✅ Pass Criteria**: Tags are saved and displayed correctly.

### 4.3 Test Due Dates

**Create Task with Due Date**:
1. **Click "Add Task"**
2. **Enter**:
   - Title: `Task with Due Date`
   - Due Date: Select tomorrow's date
3. **Submit**
4. **Expected**: Task shows due date

**Create Overdue Task**:
1. **Create task** with Due Date: Yesterday's date
2. **Expected**: Task shows as overdue (red indicator)

**✅ Pass Criteria**: Due dates are saved and displayed, overdue tasks highlighted.

### 4.4 Test Reminders

**Create Task with Reminder**:
1. **Click "Add Task"**
2. **Enter**:
   - Title: `Task with Reminder`
   - Due Date: Tomorrow
   - Remind At: Tomorrow at 9:00 AM
3. **Submit**
4. **Expected**: Task shows reminder time

**Verify Reminder in Database**:
```bash
# Check backend logs for reminder scheduler
kubectl logs deployment/backend-deployment -n todo-app | grep -i reminder

# Expected output:
# INFO: Reminder scheduler started
# INFO: Checking for upcoming reminders...
# INFO: Found 1 reminder to send
```

**✅ Pass Criteria**: Reminder is saved and scheduler is processing reminders.

### 4.5 Test Recurring Tasks

**Create Daily Recurring Task**:
1. **Click "Add Task"**
2. **Enter**:
   - Title: `Daily Standup`
   - Recurring: **"Daily"**
   - Start Date: Today
3. **Submit**
4. **Expected**: Task created with recurring indicator

**Verify Recurring Pattern in Database**:
```bash
# Check backend logs for recurring scheduler
kubectl logs deployment/backend-deployment -n todo-app | grep -i recurring

# Expected output:
# INFO: Recurring task scheduler started
# INFO: Checking for recurring patterns...
# INFO: Found 1 recurring pattern to process
# INFO: Generated new task instance for pattern: ...
```

**Wait for Next Instance** (optional - may take time):
- If you set up a recurring task for every minute (for testing), wait 1 minute
- Check if new task instance is created automatically

**✅ Pass Criteria**: Recurring pattern saved, scheduler is running.

---

## Step 5: Event-Driven Architecture Testing

### 5.1 Monitor Kafka Events

Open a terminal and watch backend logs:

```bash
# Watch logs in real-time
kubectl logs -f deployment/backend-deployment -n todo-app --tail=50
```

Keep this terminal open while performing actions in the UI.

### 5.2 Test Task Events

**Create a Task** in the UI and watch logs:

**Expected Log Output**:
```
INFO: Task created: task_id=abc-123-def-456
INFO: Publishing task event to Kafka topic: task-events
INFO: Task event published successfully
INFO: Task event consumed from Kafka
INFO: Processing task created event
INFO: Audit log created for task creation
```

**✅ Pass Criteria**: See event published to Kafka and consumed by consumer.

### 5.3 Test Recurring Task Events

**Create a Recurring Task** and watch logs:

**Expected Log Output**:
```
INFO: Recurring pattern created: pattern_id=xyz-789-uvw-012
INFO: Publishing recurring task event to Kafka topic: recurring-task-events
INFO: Recurring task event published successfully
INFO: Recurring task event consumed from Kafka
INFO: Processing recurring pattern created event
```

**✅ Pass Criteria**: Recurring task events flow through Kafka.

### 5.4 Test Reminder Events

**Create a Task with Reminder** and watch logs:

**Expected Log Output**:
```
INFO: Task with reminder created: task_id=abc-123-def-456
INFO: Publishing reminder event to Kafka topic: reminder-events
INFO: Reminder event published successfully
INFO: Reminder event consumed from Kafka
INFO: Reminder scheduled for: 2024-01-16 09:00:00
```

**✅ Pass Criteria**: Reminder events are published and consumed.

### 5.5 Verify Kafka Topics in Redpanda Cloud

```bash
# List topics (if rpk is configured)
rpk topic list

# Expected output:
# NAME                    PARTITIONS  REPLICAS
# task-events             3           3
# recurring-task-events   3           3
# reminder-events         3           3
# notification-events     3           3

# Check message count in topics
rpk topic describe task-events
```

**✅ Pass Criteria**: All 4 topics exist and have messages.

---

## Step 6: Database Persistence Testing

### 6.1 Verify Data in Database

**Check Task Count**:
```bash
# Connect to backend pod
kubectl exec -it deployment/backend-deployment -n todo-app -- /bin/bash

# Inside pod, run Python
python3 << 'EOF'
import asyncio
from app.database import get_engine
from sqlalchemy import text

async def check_data():
    engine = get_engine()
    async with engine.begin() as conn:
        # Count tasks
        result = await conn.execute(text("SELECT COUNT(*) FROM task"))
        task_count = result.scalar()
        print(f"Total tasks: {task_count}")

        # Count recurring patterns
        result = await conn.execute(text("SELECT COUNT(*) FROM recurring_patterns"))
        pattern_count = result.scalar()
        print(f"Total recurring patterns: {pattern_count}")

        # Count audit logs
        result = await conn.execute(text("SELECT COUNT(*) FROM audit_log"))
        audit_count = result.scalar()
        print(f"Total audit logs: {audit_count}")

asyncio.run(check_data())
EOF

# Exit pod
exit
```

**Expected Output**:
```
Total tasks: 10
Total recurring patterns: 2
Total audit logs: 15
```

**✅ Pass Criteria**: Data is persisted in database.

### 6.2 Test Data Persistence After Pod Restart

**Restart Backend Pods**:
```bash
# Restart deployment
kubectl rollout restart deployment/backend-deployment -n todo-app

# Wait for rollout to complete
kubectl rollout status deployment/backend-deployment -n todo-app

# Check pods
kubectl get pods -n todo-app
```

**Verify Data Still Exists**:
1. **Refresh frontend** in browser
2. **Expected**: All tasks still visible
3. **Check database** again (repeat Step 6.1)

**✅ Pass Criteria**: Data persists after pod restart (stored in Neon, not in pods).

---

## Step 7: Performance Testing

### 7.1 Test Response Times

**Backend API Response Time**:
```bash
# Test health endpoint
time curl http://$BACKEND_IP/health

# Expected: < 200ms
```

**Frontend Load Time**:
```bash
# Test frontend
time curl http://$FRONTEND_IP

# Expected: < 500ms
```

**✅ Pass Criteria**: Response times are acceptable (< 1 second).

### 7.2 Test Concurrent Requests

**Load Test Backend** (using Apache Bench):
```bash
# Install ab (if not installed)
sudo apt-get install apache2-utils -y

# Run load test (100 requests, 10 concurrent)
ab -n 100 -c 10 http://$BACKEND_IP/health

# Check results
```

**Expected Output**:
```
Requests per second:    50-100 [#/sec]
Time per request:       10-20 [ms]
Failed requests:        0
```

**✅ Pass Criteria**: No failed requests, reasonable throughput.

### 7.3 Test Under Load

**Create Multiple Tasks Quickly**:
1. **Open frontend**
2. **Create 10 tasks** as fast as possible
3. **Expected**: All tasks created successfully, no errors

**Check Backend Logs**:
```bash
kubectl logs deployment/backend-deployment -n todo-app --tail=50
```

**Expected**: No errors, all events processed.

**✅ Pass Criteria**: System handles burst of requests without errors.

---

## Step 8: Stability Testing

### 8.1 Check Pod Restarts

```bash
# Check restart count
kubectl get pods -n todo-app

# Look at RESTARTS column
# Expected: 0 or very low number (< 3)
```

**✅ Pass Criteria**: Pods are stable, no frequent restarts.

### 8.2 Check Resource Usage

```bash
# Check pod resource usage
kubectl top pods -n todo-app

# Expected output:
# NAME                                   CPU(cores)   MEMORY(bytes)
# backend-deployment-abc123-def456       50m          400Mi
# backend-deployment-abc123-ghi789       50m          400Mi
# frontend-deployment-abc123-jkl012     20m          200Mi
# frontend-deployment-abc123-mno345     20m          200Mi
```

**✅ Pass Criteria**:
- Backend: < 500m CPU, < 1Gi memory
- Frontend: < 250m CPU, < 512Mi memory

### 8.3 Check Node Health

```bash
# Check node resource usage
kubectl top nodes

# Expected output:
# NAME                   CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# worker-pool-abc123     300m         15%    1000Mi          50%
# worker-pool-def456     300m         15%    1000Mi          50%
```

**✅ Pass Criteria**: Nodes not overloaded (< 80% CPU and memory).

### 8.4 Long-Running Test

**Leave Application Running**:
1. **Keep frontend open** in browser
2. **Perform actions** every few minutes
3. **Monitor for 30 minutes**
4. **Expected**: No crashes, no errors

**✅ Pass Criteria**: Application remains stable over time.

---

## Step 9: Final Verification Checklist

### 9.1 Phase 5 Features Checklist

- [ ] **Recurring Tasks**: Can create daily/weekly/monthly recurring tasks
- [ ] **Reminders**: Can set reminders for tasks
- [ ] **Priorities**: Can set high/medium/low priority
- [ ] **Tags**: Can add multiple tags to tasks
- [ ] **Due Dates**: Can set due dates, overdue tasks highlighted

### 9.2 Event-Driven Architecture Checklist

- [ ] **Kafka Integration**: Events published to Redpanda Cloud
- [ ] **Event Producers**: Task events, recurring events, reminder events
- [ ] **Event Consumers**: All consumers running and processing events
- [ ] **Schedulers**: Recurring scheduler and reminder scheduler running
- [ ] **Audit Logs**: All actions logged in audit_log table

### 9.3 Deployment Checklist

- [ ] **DOKS Cluster**: Running with 2 nodes
- [ ] **Backend**: 2 replicas running, LoadBalancer working
- [ ] **Frontend**: 2 replicas running, LoadBalancer working
- [ ] **Database**: Neon Postgres connected, all tables exist
- [ ] **Kafka**: Redpanda Cloud connected, all topics exist
- [ ] **Secrets**: All Kubernetes secrets configured correctly

### 9.4 Functionality Checklist

- [ ] **Authentication**: Sign up, login, logout working
- [ ] **CRUD Operations**: Create, read, update, delete tasks
- [ ] **User Isolation**: Users only see their own tasks
- [ ] **Data Persistence**: Data survives pod restarts
- [ ] **Error Handling**: Proper error messages displayed

### 9.5 Performance Checklist

- [ ] **Response Times**: < 1 second for most operations
- [ ] **Stability**: No frequent pod restarts
- [ ] **Resource Usage**: Within limits (not overloaded)
- [ ] **Concurrent Users**: Can handle multiple users

---

## Step 10: Hackathon Submission Preparation

### 10.1 Gather Deployment Information

Create a file: `deployment-info.txt`

```bash
cat > deployment-info.txt << EOF
CALM ORBIT TODO - PHASE 5 CLOUD DEPLOYMENT
==========================================

DEPLOYMENT DATE: $(date)

CLOUD INFRASTRUCTURE:
- Platform: Digital Ocean Kubernetes (DOKS)
- Region: NYC3
- Nodes: 2 × Basic (2GB RAM, 1 vCPU)
- Kubernetes Version: $(kubectl version --short | grep Server)

APPLICATION URLS:
- Frontend: http://$FRONTEND_IP
- Backend API: http://$BACKEND_IP
- API Documentation: http://$BACKEND_IP/docs

SERVICES:
- Backend: 2 replicas, LoadBalancer
- Frontend: 2 replicas, LoadBalancer

DATABASE:
- Provider: Neon Serverless PostgreSQL
- Tables: 9 (including 4 Phase 5 tables)

EVENT STREAMING:
- Provider: Redpanda Cloud
- Topics: 4 (task-events, recurring-task-events, reminder-events, notification-events)
- Consumers: 3 (task, recurring, reminder)
- Schedulers: 2 (recurring, reminder)

PHASE 5 FEATURES IMPLEMENTED:
✅ Recurring Tasks (daily, weekly, monthly)
✅ Reminders (scheduled notifications)
✅ Priorities (high, medium, low)
✅ Tags (multiple tags per task)
✅ Due Dates (with overdue detection)

EVENT-DRIVEN ARCHITECTURE:
✅ Kafka/Redpanda integration
✅ Event producers for all actions
✅ Event consumers processing events
✅ Background schedulers for recurring tasks and reminders
✅ Audit logging for all operations

TESTING RESULTS:
✅ All CRUD operations working
✅ Authentication working (Better Auth)
✅ Phase 5 features working
✅ Event-driven architecture working
✅ Data persistence verified
✅ Performance acceptable
✅ Stability verified (no crashes)

COST:
- Monthly: ~$48 (covered by $200 free credit)
- Remaining credit: ~$195
- Can run for 4+ months on free credit

REPOSITORY:
- GitHub: [Your GitHub URL]
- Branch: 008-cloud-event-driven-phase5

DEMO CREDENTIALS:
- Email: test@example.com
- Password: TestPassword123!
EOF

cat deployment-info.txt
```

### 10.2 Take Screenshots

Take screenshots of:
1. **Frontend Dashboard** with tasks
2. **Task with Phase 5 features** (priority, tags, due date, recurring)
3. **Backend API Docs** (Swagger UI)
4. **Kubernetes Dashboard** showing pods
5. **Backend Logs** showing Kafka events
6. **Redpanda Cloud Dashboard** showing topics

Save in: `calm-orbit-todo/phase5-cloud/docs/screenshots/`

### 10.3 Create Demo Video (Optional)

Record a 2-3 minute video showing:
1. **Login** to application
2. **Create task** with Phase 5 features
3. **Show Kafka events** in backend logs
4. **Show recurring task** being generated
5. **Show Kubernetes pods** running

### 10.4 Update README

Update `calm-orbit-todo/phase5-cloud/README.md` with:
- Deployment URLs
- Demo credentials
- Architecture diagram
- Features list
- Testing results

---

## Troubleshooting Common Issues

### Issue 1: Tasks Not Appearing After Creation

**Check**:
```bash
# Check backend logs
kubectl logs deployment/backend-deployment -n todo-app | grep -i error

# Check database connection
kubectl logs deployment/backend-deployment -n todo-app | grep -i database
```

**Solution**: Verify DATABASE_URL secret is correct.

### Issue 2: Kafka Events Not Processing

**Check**:
```bash
# Check Kafka connection
kubectl logs deployment/backend-deployment -n todo-app | grep -i kafka

# Check consumer status
kubectl logs deployment/backend-deployment -n todo-app | grep -i consumer
```

**Solution**: Verify Kafka credentials in secret.

### Issue 3: Recurring Tasks Not Generating

**Check**:
```bash
# Check scheduler logs
kubectl logs deployment/backend-deployment -n todo-app | grep -i "recurring scheduler"

# Check recurring patterns table
kubectl exec -it deployment/backend-deployment -n todo-app -- python3 -c "
import asyncio
from app.database import get_engine
from sqlalchemy import text

async def check():
    engine = get_engine()
    async with engine.begin() as conn:
        result = await conn.execute(text('SELECT COUNT(*) FROM recurring_patterns'))
        print(f'Recurring patterns: {result.scalar()}')

asyncio.run(check())
"
```

**Solution**: Verify recurring_patterns table exists and scheduler is running.

### Issue 4: Frontend Can't Connect to Backend

**Check**:
```bash
# Check frontend environment variables
kubectl describe deployment frontend-deployment -n todo-app | grep NEXT_PUBLIC_API_URL

# Test backend from internet
curl http://$BACKEND_IP/health
```

**Solution**: Update NEXT_PUBLIC_API_URL in frontend deployment.

### Issue 5: Authentication Not Working

**Check**:
```bash
# Check auth secret
kubectl get secret auth-secret -n todo-app -o yaml

# Check frontend logs
kubectl logs deployment/frontend-deployment -n todo-app
```

**Solution**: Verify BETTER_AUTH_SECRET is set correctly.

---

## Performance Benchmarks

### Expected Performance

| Metric | Target | Acceptable | Poor |
|--------|--------|------------|------|
| Health endpoint | < 100ms | < 200ms | > 500ms |
| Task creation | < 300ms | < 500ms | > 1s |
| Task list load | < 500ms | < 1s | > 2s |
| Frontend load | < 1s | < 2s | > 5s |
| Kafka event processing | < 100ms | < 200ms | > 500ms |

### Load Testing Results

**Expected Capacity**:
- Concurrent users: 50-100
- Requests per second: 100-200
- Tasks per user: 1000+
- Kafka messages per second: 500+

---

## Final Checklist for Hackathon Submission

### Documentation
- [ ] README.md updated with deployment info
- [ ] Architecture diagram included
- [ ] API documentation accessible
- [ ] Screenshots taken
- [ ] Demo video recorded (optional)

### Code
- [ ] All code committed to GitHub
- [ ] Branch: 008-cloud-event-driven-phase5
- [ ] No secrets in code (using Kubernetes secrets)
- [ ] Clean code, no debug statements

### Deployment
- [ ] Application running in DOKS
- [ ] All pods healthy
- [ ] LoadBalancers working
- [ ] URLs accessible from internet

### Features
- [ ] All Phase 5 features working
- [ ] Event-driven architecture working
- [ ] Authentication working
- [ ] CRUD operations working

### Testing
- [ ] All tests passed
- [ ] Performance acceptable
- [ ] Stability verified
- [ ] No critical bugs

### Presentation
- [ ] Demo credentials ready
- [ ] Deployment info document ready
- [ ] Screenshots ready
- [ ] Video ready (optional)

---

## Success Criteria

Your deployment is successful if:

✅ **All pods are running** without frequent restarts
✅ **Frontend is accessible** from internet
✅ **Backend API is accessible** from internet
✅ **Authentication works** (sign up, login, logout)
✅ **CRUD operations work** (create, read, update, delete tasks)
✅ **Phase 5 features work** (recurring, reminders, priorities, tags, due dates)
✅ **Kafka events are flowing** (published and consumed)
✅ **Schedulers are running** (recurring and reminder)
✅ **Data persists** after pod restarts
✅ **Performance is acceptable** (< 1s response times)
✅ **No critical errors** in logs

---

## Next Steps After Hackathon

### If You Want to Keep Running

**Monitor Costs**:
```bash
# Check balance weekly
doctl balance get

# Set up billing alerts
# Go to: https://cloud.digitalocean.com/billing
```

**Optimize Costs**:
- Reduce to 1 replica per deployment (saves $12/month)
- Use NodePort instead of LoadBalancer (saves $24/month)
- Scale down nodes during off-hours

### If You Want to Shut Down

**Delete Everything**:
```bash
# Delete DOKS cluster (stops all charges)
doctl kubernetes cluster delete hackathon-todo-cluster

# Delete container registry
doctl registry delete hackathon-todo-registry

# Delete Redpanda Cloud cluster
# Go to: https://cloud.redpanda.com/
# Delete cluster manually

# Keep Neon database (free tier)
# Or delete if not needed
```

**Backup Data First**:
```bash
# Export database
kubectl exec -it deployment/backend-deployment -n todo-app -- pg_dump $DATABASE_URL > backup.sql

# Save to local machine
```

---

## Congratulations! 🎉

You've successfully:
- ✅ Deployed a full-stack application to Kubernetes
- ✅ Implemented event-driven architecture with Kafka
- ✅ Set up cloud infrastructure (DOKS, Redpanda Cloud, Neon)
- ✅ Verified all Phase 5 features working
- ✅ Completed comprehensive testing

**Your application is now running in the cloud and ready for hackathon submission!**

---

## Quick Reference

### Important URLs
```bash
# Display all URLs
echo "Frontend: http://$FRONTEND_IP"
echo "Backend: http://$BACKEND_IP"
echo "API Docs: http://$BACKEND_IP/docs"
```

### Important Commands
```bash
# Check status
kubectl get all -n todo-app

# View logs
kubectl logs -f deployment/backend-deployment -n todo-app
kubectl logs -f deployment/frontend-deployment -n todo-app

# Check health
curl http://$BACKEND_IP/health

# Check costs
doctl balance get

# Restart if needed
kubectl rollout restart deployment/backend-deployment -n todo-app
kubectl rollout restart deployment/frontend-deployment -n todo-app
```

### Demo Credentials
```
Email: test@example.com
Password: TestPassword123!
```

---

**Status**: ✅ Verification complete!
**Time Taken**: ~30-45 minutes
**Result**: Application fully tested and ready for demo
