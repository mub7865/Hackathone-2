# Testing Guide: Cloud-Native Event-Driven Todo Application

**Version**: 1.0
**Last Updated**: 2026-01-12
**Target**: Development and QA Teams

This guide provides comprehensive testing strategies and examples for the Todo Application.

---

## Table of Contents

1. [Testing Strategy](#testing-strategy)
2. [Unit Testing](#unit-testing)
3. [Integration Testing](#integration-testing)
4. [End-to-End Testing](#end-to-end-testing)
5. [API Testing](#api-testing)
6. [Event Testing](#event-testing)
7. [Performance Testing](#performance-testing)
8. [Security Testing](#security-testing)
9. [Test Coverage](#test-coverage)
10. [CI/CD Integration](#cicd-integration)

---

## Testing Strategy

### Testing Pyramid

```
        /\
       /  \
      / E2E \
     /______\
    /        \
   /Integration\
  /____________\
 /              \
/   Unit Tests   \
/________________\
```

**Distribution**:
- **Unit Tests**: 70% - Fast, isolated, test individual functions
- **Integration Tests**: 20% - Test component interactions
- **End-to-End Tests**: 10% - Test complete user flows

### Test Types

| Type | Purpose | Speed | Coverage |
|------|---------|-------|----------|
| Unit | Test individual functions | Fast | High |
| Integration | Test component interactions | Medium | Medium |
| E2E | Test complete user flows | Slow | Low |
| API | Test API endpoints | Fast | High |
| Performance | Test system performance | Slow | N/A |
| Security | Test security vulnerabilities | Medium | N/A |

---

## Unit Testing

### Backend Unit Tests (Python + Pytest)

**Setup**:
```bash
cd backend
pip install pytest pytest-asyncio pytest-cov httpx
```

**Test Structure**:
```
backend/tests/
├── __init__.py
├── conftest.py              # Shared fixtures
├── unit/
│   ├── test_models.py       # Model tests
│   ├── test_services.py     # Service tests
│   ├── test_schemas.py      # Schema validation tests
│   └── test_utils.py        # Utility function tests
├── integration/
│   ├── test_api.py          # API endpoint tests
│   ├── test_database.py     # Database integration tests
│   └── test_events.py       # Event processing tests
└── e2e/
    └── test_workflows.py    # End-to-end workflow tests
```

**Example: Model Tests**:
```python
# tests/unit/test_models.py
import pytest
from datetime import datetime
from app.models.task import Task, TaskStatus, TaskPriority

def test_task_creation():
    """Test task model creation"""
    task = Task(
        user_id="user123",
        title="Test task",
        status=TaskStatus.PENDING,
        priority=TaskPriority.HIGH,
    )

    assert task.user_id == "user123"
    assert task.title == "Test task"
    assert task.status == TaskStatus.PENDING
    assert task.priority == TaskPriority.HIGH
    assert task.created_at is not None

def test_task_validation():
    """Test task validation"""
    with pytest.raises(ValueError):
        Task(
            user_id="",  # Empty user_id should fail
            title="Test task",
        )

def test_task_status_transition():
    """Test task status transitions"""
    task = Task(
        user_id="user123",
        title="Test task",
        status=TaskStatus.PENDING,
    )

    # Valid transition
    task.status = TaskStatus.IN_PROGRESS
    assert task.status == TaskStatus.IN_PROGRESS

    # Valid transition
    task.status = TaskStatus.COMPLETED
    assert task.status == TaskStatus.COMPLETED
```

**Example: Service Tests**:
```python
# tests/unit/test_services.py
import pytest
from unittest.mock import AsyncMock, MagicMock
from app.services.task_service import TaskService
from app.models.task import Task, TaskStatus

@pytest.fixture
def mock_db_session():
    """Mock database session"""
    session = AsyncMock()
    return session

@pytest.fixture
def task_service(mock_db_session):
    """Task service with mocked database"""
    return TaskService(mock_db_session)

@pytest.mark.asyncio
async def test_create_task(task_service, mock_db_session):
    """Test task creation service"""
    task_data = {
        "user_id": "user123",
        "title": "Test task",
        "status": TaskStatus.PENDING,
    }

    task = await task_service.create_task(task_data)

    assert task.title == "Test task"
    assert task.status == TaskStatus.PENDING
    mock_db_session.add.assert_called_once()
    mock_db_session.commit.assert_called_once()

@pytest.mark.asyncio
async def test_get_user_tasks(task_service, mock_db_session):
    """Test getting user tasks"""
    # Mock database response
    mock_tasks = [
        Task(user_id="user123", title="Task 1"),
        Task(user_id="user123", title="Task 2"),
    ]
    mock_db_session.execute.return_value.scalars.return_value.all.return_value = mock_tasks

    tasks = await task_service.get_user_tasks("user123")

    assert len(tasks) == 2
    assert tasks[0].title == "Task 1"
    assert tasks[1].title == "Task 2"
```

**Example: Schema Tests**:
```python
# tests/unit/test_schemas.py
import pytest
from pydantic import ValidationError
from app.schemas.task import TaskCreate, TaskUpdate

def test_task_create_schema():
    """Test task creation schema validation"""
    # Valid data
    data = {
        "title": "Test task",
        "priority": "high",
        "tags": ["urgent", "important"],
    }
    task = TaskCreate(**data)
    assert task.title == "Test task"
    assert task.priority == "high"

def test_task_create_validation():
    """Test task creation validation"""
    # Missing required field
    with pytest.raises(ValidationError) as exc_info:
        TaskCreate(priority="high")  # Missing title

    assert "title" in str(exc_info.value)

    # Invalid priority
    with pytest.raises(ValidationError):
        TaskCreate(title="Test", priority="invalid")

    # Too many tags
    with pytest.raises(ValidationError):
        TaskCreate(title="Test", tags=["tag"] * 11)  # Max 10 tags
```

**Running Unit Tests**:
```bash
# Run all unit tests
pytest tests/unit/ -v

# Run with coverage
pytest tests/unit/ -v --cov=app --cov-report=html

# Run specific test file
pytest tests/unit/test_models.py -v

# Run specific test
pytest tests/unit/test_models.py::test_task_creation -v

# Run tests matching pattern
pytest tests/unit/ -k "task" -v
```

### Frontend Unit Tests (Jest + React Testing Library)

**Setup**:
```bash
cd frontend
npm install --save-dev @testing-library/react @testing-library/jest-dom @testing-library/user-event
```

**Test Structure**:
```
frontend/src/
├── components/
│   ├── TaskList.tsx
│   └── __tests__/
│       └── TaskList.test.tsx
├── hooks/
│   ├── useTasks.ts
│   └── __tests__/
│       └── useTasks.test.ts
└── utils/
    ├── api.ts
    └── __tests__/
        └── api.test.ts
```

**Example: Component Tests**:
```typescript
// components/__tests__/TaskList.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import TaskList from '../TaskList';

describe('TaskList', () => {
  const mockTasks = [
    { id: '1', title: 'Task 1', status: 'pending', priority: 'high' },
    { id: '2', title: 'Task 2', status: 'completed', priority: 'low' },
  ];

  it('renders task list', () => {
    render(<TaskList tasks={mockTasks} />);

    expect(screen.getByText('Task 1')).toBeInTheDocument();
    expect(screen.getByText('Task 2')).toBeInTheDocument();
  });

  it('filters tasks by status', () => {
    render(<TaskList tasks={mockTasks} />);

    const filterButton = screen.getByText('Pending');
    fireEvent.click(filterButton);

    expect(screen.getByText('Task 1')).toBeInTheDocument();
    expect(screen.queryByText('Task 2')).not.toBeInTheDocument();
  });

  it('calls onTaskClick when task is clicked', () => {
    const onTaskClick = jest.fn();
    render(<TaskList tasks={mockTasks} onTaskClick={onTaskClick} />);

    const task = screen.getByText('Task 1');
    fireEvent.click(task);

    expect(onTaskClick).toHaveBeenCalledWith('1');
  });
});
```

**Example: Hook Tests**:
```typescript
// hooks/__tests__/useTasks.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useTasks } from '../useTasks';

// Mock API
jest.mock('@/utils/api', () => ({
  fetchTasks: jest.fn(),
}));

describe('useTasks', () => {
  it('fetches tasks on mount', async () => {
    const mockTasks = [{ id: '1', title: 'Task 1' }];
    (fetchTasks as jest.Mock).mockResolvedValue(mockTasks);

    const { result } = renderHook(() => useTasks());

    await waitFor(() => {
      expect(result.current.tasks).toEqual(mockTasks);
      expect(result.current.loading).toBe(false);
    });
  });

  it('handles fetch error', async () => {
    (fetchTasks as jest.Mock).mockRejectedValue(new Error('API Error'));

    const { result } = renderHook(() => useTasks());

    await waitFor(() => {
      expect(result.current.error).toBe('API Error');
      expect(result.current.loading).toBe(false);
    });
  });
});
```

**Running Frontend Tests**:
```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run in watch mode
npm test -- --watch

# Run specific test file
npm test TaskList.test.tsx
```

---

## Integration Testing

### API Integration Tests

**Example: API Endpoint Tests**:
```python
# tests/integration/test_api.py
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.fixture
async def client():
    """Test client"""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.fixture
async def auth_token(client):
    """Get authentication token"""
    response = await client.post("/api/v1/auth/login", json={
        "email": "test@example.com",
        "password": "password123"
    })
    return response.json()["access_token"]

@pytest.mark.asyncio
async def test_create_task(client, auth_token):
    """Test task creation endpoint"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = await client.post(
        "/api/v1/tasks",
        json={
            "title": "Test task",
            "priority": "high",
            "tags": ["test"]
        },
        headers=headers
    )

    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test task"
    assert data["priority"] == "high"
    assert "id" in data

@pytest.mark.asyncio
async def test_list_tasks(client, auth_token):
    """Test task listing endpoint"""
    headers = {"Authorization": f"Bearer {auth_token}"}

    # Create test tasks
    for i in range(3):
        await client.post(
            "/api/v1/tasks",
            json={"title": f"Task {i}"},
            headers=headers
        )

    # List tasks
    response = await client.get("/api/v1/tasks", headers=headers)

    assert response.status_code == 200
    data = response.json()
    assert len(data["tasks"]) >= 3

@pytest.mark.asyncio
async def test_update_task(client, auth_token):
    """Test task update endpoint"""
    headers = {"Authorization": f"Bearer {auth_token}"}

    # Create task
    create_response = await client.post(
        "/api/v1/tasks",
        json={"title": "Original title"},
        headers=headers
    )
    task_id = create_response.json()["id"]

    # Update task
    update_response = await client.patch(
        f"/api/v1/tasks/{task_id}",
        json={"title": "Updated title", "status": "in_progress"},
        headers=headers
    )

    assert update_response.status_code == 200
    data = update_response.json()
    assert data["title"] == "Updated title"
    assert data["status"] == "in_progress"

@pytest.mark.asyncio
async def test_delete_task(client, auth_token):
    """Test task deletion endpoint"""
    headers = {"Authorization": f"Bearer {auth_token}"}

    # Create task
    create_response = await client.post(
        "/api/v1/tasks",
        json={"title": "To be deleted"},
        headers=headers
    )
    task_id = create_response.json()["id"]

    # Delete task
    delete_response = await client.delete(
        f"/api/v1/tasks/{task_id}",
        headers=headers
    )

    assert delete_response.status_code == 204

    # Verify deletion
    get_response = await client.get(
        f"/api/v1/tasks/{task_id}",
        headers=headers
    )
    assert get_response.status_code == 404
```

### Database Integration Tests

**Example: Database Tests**:
```python
# tests/integration/test_database.py
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.models.task import Task
from app.core.database import Base

@pytest.fixture
async def test_db():
    """Test database"""
    engine = create_async_engine(
        "postgresql+asyncpg://postgres:postgres@localhost:5432/test_db",
        echo=True
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async with async_session() as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()

@pytest.mark.asyncio
async def test_task_crud(test_db):
    """Test task CRUD operations"""
    # Create
    task = Task(
        user_id="user123",
        title="Test task",
        status="pending"
    )
    test_db.add(task)
    await test_db.commit()
    await test_db.refresh(task)

    assert task.id is not None

    # Read
    result = await test_db.get(Task, task.id)
    assert result.title == "Test task"

    # Update
    result.title = "Updated task"
    await test_db.commit()
    await test_db.refresh(result)
    assert result.title == "Updated task"

    # Delete
    await test_db.delete(result)
    await test_db.commit()

    deleted = await test_db.get(Task, task.id)
    assert deleted is None
```

---

## End-to-End Testing

### Playwright E2E Tests

**Setup**:
```bash
npm install --save-dev @playwright/test
npx playwright install
```

**Example: E2E Tests**:
```typescript
// e2e/tasks.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Task Management', () => {
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto('http://localhost:3000/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'password123');
    await page.click('button[type="submit"]');
    await page.waitForURL('http://localhost:3000/tasks');
  });

  test('create new task', async ({ page }) => {
    // Click create button
    await page.click('button:has-text("Create Task")');

    // Fill form
    await page.fill('[name="title"]', 'E2E Test Task');
    await page.selectOption('[name="priority"]', 'high');
    await page.fill('[name="tags"]', 'test, e2e');

    // Submit
    await page.click('button:has-text("Save")');

    // Verify task appears in list
    await expect(page.locator('text=E2E Test Task')).toBeVisible();
  });

  test('complete task', async ({ page }) => {
    // Find task checkbox
    const taskCheckbox = page.locator('[data-testid="task-checkbox"]').first();

    // Mark as complete
    await taskCheckbox.click();

    // Verify task is marked complete
    await expect(taskCheckbox).toBeChecked();
  });

  test('filter tasks by priority', async ({ page }) => {
    // Click high priority filter
    await page.click('button:has-text("High Priority")');

    // Verify only high priority tasks shown
    const tasks = page.locator('[data-priority="high"]');
    await expect(tasks).toHaveCount(await tasks.count());
  });

  test('search tasks', async ({ page }) => {
    // Enter search query
    await page.fill('[placeholder="Search tasks..."]', 'documentation');

    // Wait for results
    await page.waitForTimeout(500);

    // Verify filtered results
    const results = page.locator('[data-testid="task-item"]');
    const count = await results.count();

    for (let i = 0; i < count; i++) {
      const text = await results.nth(i).textContent();
      expect(text?.toLowerCase()).toContain('documentation');
    }
  });
});
```

**Running E2E Tests**:
```bash
# Run all E2E tests
npx playwright test

# Run in headed mode
npx playwright test --headed

# Run specific test
npx playwright test tasks.spec.ts

# Debug mode
npx playwright test --debug
```

---

## API Testing

### Postman/Newman Tests

**Example: Postman Collection**:
```json
{
  "info": {
    "name": "Todo API Tests",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Authentication",
      "item": [
        {
          "name": "Login",
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "pm.test('Status code is 200', function () {",
                  "    pm.response.to.have.status(200);",
                  "});",
                  "",
                  "pm.test('Response has access token', function () {",
                  "    var jsonData = pm.response.json();",
                  "    pm.expect(jsonData).to.have.property('access_token');",
                  "    pm.environment.set('access_token', jsonData.access_token);",
                  "});"
                ]
              }
            }
          ],
          "request": {
            "method": "POST",
            "header": [],
            "body": {
              "mode": "raw",
              "raw": "{\"email\":\"test@example.com\",\"password\":\"password123\"}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{base_url}}/api/v1/auth/login",
              "host": ["{{base_url}}"],
              "path": ["api", "v1", "auth", "login"]
            }
          }
        }
      ]
    },
    {
      "name": "Tasks",
      "item": [
        {
          "name": "Create Task",
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "pm.test('Status code is 201', function () {",
                  "    pm.response.to.have.status(201);",
                  "});",
                  "",
                  "pm.test('Task created successfully', function () {",
                  "    var jsonData = pm.response.json();",
                  "    pm.expect(jsonData).to.have.property('id');",
                  "    pm.expect(jsonData.title).to.eql('API Test Task');",
                  "    pm.environment.set('task_id', jsonData.id);",
                  "});"
                ]
              }
            }
          ],
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{access_token}}"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\"title\":\"API Test Task\",\"priority\":\"high\"}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{base_url}}/api/v1/tasks",
              "host": ["{{base_url}}"],
              "path": ["api", "v1", "tasks"]
            }
          }
        }
      ]
    }
  ]
}
```

**Running with Newman**:
```bash
newman run todo-api-tests.json -e environment.json
```

---

## Event Testing

### Kafka Event Tests

**Example: Event Producer Tests**:
```python
# tests/integration/test_events.py
import pytest
from app.events.producers.event_producers import TaskEventProducer
from app.events.consumers.event_consumers import TaskEventConsumer

@pytest.mark.asyncio
async def test_event_publishing():
    """Test event publishing"""
    producer = TaskEventProducer()

    event_data = {
        "task_id": "123",
        "user_id": "user123",
        "title": "Test task"
    }

    # Publish event
    success = await producer.publish_task_created(event_data)

    assert success is True

@pytest.mark.asyncio
async def test_event_consumption():
    """Test event consumption"""
    consumer = TaskEventConsumer()
    events_received = []

    # Register handler
    async def test_handler(data):
        events_received.append(data)

    consumer.register_handler("task.created", test_handler)

    # Publish event
    producer = TaskEventProducer()
    await producer.publish_task_created({"task_id": "123"})

    # Consume events (with timeout)
    await asyncio.wait_for(consumer.consume_one(), timeout=5.0)

    # Verify event received
    assert len(events_received) == 1
    assert events_received[0]["task_id"] == "123"

@pytest.mark.asyncio
async def test_event_idempotency():
    """Test event idempotency"""
    from app.events.idempotency import IdempotencyService

    idempotency = IdempotencyService(db_session)

    event_id = "test-event-123"
    consumer_group = "test-consumer"

    # First processing
    is_processed = await idempotency.is_processed(event_id, consumer_group)
    assert is_processed is False

    # Mark as processed
    await idempotency.mark_processed(event_id, "task.created", consumer_group)

    # Second check
    is_processed = await idempotency.is_processed(event_id, consumer_group)
    assert is_processed is True
```

---

## Performance Testing

See [Performance Optimization Guide](performance-optimization.md) for detailed performance testing strategies.

---

## Security Testing

See [Security Hardening Checklist](security-hardening.md) for security testing procedures.

---

## Test Coverage

### Measuring Coverage

**Backend Coverage**:
```bash
pytest tests/ --cov=app --cov-report=html --cov-report=term
```

**Frontend Coverage**:
```bash
npm test -- --coverage
```

### Coverage Goals

- **Overall**: 80%+
- **Critical Paths**: 95%+
- **Models**: 90%+
- **Services**: 85%+
- **API Endpoints**: 90%+
- **Utils**: 80%+

### Coverage Report

```
Name                      Stmts   Miss  Cover
---------------------------------------------
app/__init__.py              10      0   100%
app/models/task.py           45      3    93%
app/services/task.py         78      8    90%
app/api/v1/tasks.py          92     12    87%
app/utils/helpers.py         34      5    85%
---------------------------------------------
TOTAL                       259     28    89%
```

---

## CI/CD Integration

### GitHub Actions Test Workflow

Already implemented in `.github/workflows/test.yml`:
- Backend tests with PostgreSQL and Redis
- Frontend tests with Node.js
- Integration tests with Kafka
- Coverage reporting to Codecov

### Pre-commit Hooks

**Setup**:
```bash
pip install pre-commit
pre-commit install
```

**.pre-commit-config.yaml**:
```yaml
repos:
  - repo: local
    hooks:
      - id: pytest
        name: pytest
        entry: pytest
        language: system
        pass_filenames: false
        always_run: true
        args: [tests/unit/, -v]

      - id: jest
        name: jest
        entry: npm test
        language: system
        pass_filenames: false
        always_run: true
```

---

## Testing Best Practices

### General Principles

1. **Test Behavior, Not Implementation**: Focus on what the code does, not how
2. **Keep Tests Independent**: Each test should run in isolation
3. **Use Descriptive Names**: Test names should describe what they test
4. **Follow AAA Pattern**: Arrange, Act, Assert
5. **Mock External Dependencies**: Don't rely on external services
6. **Test Edge Cases**: Test boundary conditions and error cases
7. **Keep Tests Fast**: Unit tests should run in milliseconds
8. **Maintain Tests**: Update tests when code changes

### Test Naming Convention

```python
def test_<function_name>_<scenario>_<expected_result>():
    """Test description"""
    pass

# Examples:
def test_create_task_with_valid_data_returns_task():
    pass

def test_create_task_with_missing_title_raises_validation_error():
    pass

def test_get_user_tasks_with_no_tasks_returns_empty_list():
    pass
```

### Test Organization

```python
class TestTaskService:
    """Tests for TaskService"""

    def test_create_task(self):
        """Test task creation"""
        pass

    def test_get_task(self):
        """Test getting task by ID"""
        pass

    def test_update_task(self):
        """Test task update"""
        pass

    def test_delete_task(self):
        """Test task deletion"""
        pass
```

---

## Testing Checklist

### Before Committing
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Code coverage meets minimum threshold (80%)
- [ ] No failing tests
- [ ] No skipped tests without reason
- [ ] Tests are independent and can run in any order
- [ ] Test names are descriptive
- [ ] Edge cases are tested

### Before Deploying
- [ ] All tests pass in CI/CD
- [ ] Integration tests pass with production-like environment
- [ ] Performance tests meet targets
- [ ] Security tests pass
- [ ] E2E tests pass
- [ ] Load tests completed successfully
- [ ] No known critical bugs

---

## Troubleshooting Tests

### Common Issues

**Tests Fail Intermittently**:
- Check for race conditions
- Ensure tests are independent
- Check for shared state
- Add proper waits/timeouts

**Tests Are Slow**:
- Mock external dependencies
- Use in-memory database for unit tests
- Parallelize test execution
- Optimize database queries

**Coverage Is Low**:
- Identify untested code paths
- Add tests for edge cases
- Test error handling
- Test all branches

---

## Resources

- [Pytest Documentation](https://docs.pytest.org/)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [React Testing Library](https://testing-library.com/docs/react-testing-library/intro/)
- [Playwright Documentation](https://playwright.dev/)
- [Testing Best Practices](https://testingjavascript.com/)

---

**Remember**: Good tests are an investment in code quality and maintainability!
