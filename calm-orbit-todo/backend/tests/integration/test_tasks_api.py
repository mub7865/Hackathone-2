"""Integration tests for Tasks API endpoints.

Tests all CRUD operations with authentication and user isolation.
Covers happy paths and key error cases per SC-001 to SC-009.
"""

from uuid import uuid4

import pytest
from httpx import AsyncClient

from tests.integration.conftest import (
    TEST_USER_ID,
    OTHER_USER_ID,
    create_test_token,
)


# =============================================================================
# Helper Functions
# =============================================================================


def get_unique_user_id() -> str:
    """Generate a unique user ID for test isolation."""
    return f"test-user-{uuid4().hex[:8]}"


def get_auth_headers(user_id: str | None = None) -> dict[str, str]:
    """Get Authorization headers for a user.

    If no user_id provided, generates a unique one for test isolation.
    """
    if user_id is None:
        user_id = get_unique_user_id()
    token = create_test_token(user_id)
    return {"Authorization": f"Bearer {token}"}


# =============================================================================
# Test: List Tasks (GET /api/v1/tasks)
# =============================================================================


class TestListTasks:
    """Tests for GET /api/v1/tasks endpoint."""

    async def test_list_tasks_empty(self, client: AsyncClient):
        """List returns empty array for user with no tasks."""
        # Use unique user ID to ensure no pre-existing tasks
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        response = await client.get("/api/v1/tasks", headers=headers)

        assert response.status_code == 200
        assert response.json() == []

    async def test_list_tasks_returns_own_tasks(self, client: AsyncClient):
        """List returns only tasks owned by authenticated user."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create a task first
        create_response = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "My Task"},
        )
        assert create_response.status_code == 201

        # List tasks
        response = await client.get("/api/v1/tasks", headers=headers)

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["title"] == "My Task"

    async def test_list_tasks_default_pagination(self, client: AsyncClient):
        """List uses default pagination (limit=20)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create 25 tasks
        for i in range(25):
            await client.post(
                "/api/v1/tasks",
                headers=headers,
                json={"title": f"Task {i+1:02d}"},
            )

        # List with defaults
        response = await client.get("/api/v1/tasks", headers=headers)

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 20  # Default limit

    async def test_list_tasks_custom_pagination(self, client: AsyncClient):
        """List respects custom offset and limit."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create 10 tasks
        for i in range(10):
            await client.post(
                "/api/v1/tasks",
                headers=headers,
                json={"title": f"Paginated Task {i+1}"},
            )

        # Get page 2 (offset=5, limit=3)
        response = await client.get(
            "/api/v1/tasks?offset=5&limit=3",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3

    async def test_list_tasks_status_filter_pending(self, client: AsyncClient):
        """List filters by status=pending."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create pending and completed tasks
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Pending Task"},
        )

        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Completed Task"},
        )
        task_id = create_resp.json()["id"]

        # Mark as completed
        await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"status": "completed"},
        )

        # Filter by pending
        response = await client.get(
            "/api/v1/tasks?status=pending",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert all(t["status"] == "pending" for t in data)

    async def test_list_tasks_status_filter_completed(self, client: AsyncClient):
        """List filters by status=completed."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create and complete a task
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Will Complete"},
        )
        task_id = create_resp.json()["id"]

        await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"status": "completed"},
        )

        # Filter by completed
        response = await client.get(
            "/api/v1/tasks?status=completed",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert all(t["status"] == "completed" for t in data)

    async def test_list_tasks_invalid_status_returns_422(self, client: AsyncClient):
        """Invalid status value returns 422."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        response = await client.get(
            "/api/v1/tasks?status=invalid",
            headers=headers,
        )

        assert response.status_code == 422

    async def test_list_tasks_no_auth_returns_401(self, client: AsyncClient):
        """Missing auth returns 401."""
        response = await client.get("/api/v1/tasks")

        assert response.status_code == 401
        data = response.json()
        assert data["status"] == 401
        assert "title" in data  # RFC 7807

    async def test_list_tasks_user_isolation(self, client: AsyncClient):
        """User A cannot see User B's tasks."""
        user_a = get_unique_user_id()
        user_b = get_unique_user_id()

        # User A creates a task
        headers_a = get_auth_headers(user_a)
        await client.post(
            "/api/v1/tasks",
            headers=headers_a,
            json={"title": "User A Task"},
        )

        # User B creates a task
        headers_b = get_auth_headers(user_b)
        await client.post(
            "/api/v1/tasks",
            headers=headers_b,
            json={"title": "User B Task"},
        )

        # User A lists tasks - should only see their own
        response = await client.get("/api/v1/tasks", headers=headers_a)
        data = response.json()

        assert len(data) == 1
        assert data[0]["user_id"] == user_a
        assert data[0]["title"] == "User A Task"


# =============================================================================
# Test: Create Task (POST /api/v1/tasks)
# =============================================================================


class TestCreateTask:
    """Tests for POST /api/v1/tasks endpoint."""

    async def test_create_task_success(self, client: AsyncClient):
        """Create task returns 201 with task object."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        response = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "New Task", "description": "Task description"},
        )

        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "New Task"
        assert data["description"] == "Task description"
        assert data["status"] == "pending"
        assert data["user_id"] == user_id
        assert "id" in data
        assert "created_at" in data
        assert "updated_at" in data

    async def test_create_task_minimal(self, client: AsyncClient):
        """Create task with only title (description optional)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        response = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Minimal Task"},
        )

        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Minimal Task"
        assert data["description"] is None

    async def test_create_task_location_header(self, client: AsyncClient):
        """Create task sets Location header."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        response = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Location Test"},
        )

        assert response.status_code == 201
        assert "Location" in response.headers
        task_id = response.json()["id"]
        assert response.headers["Location"] == f"/api/v1/tasks/{task_id}"

    async def test_create_task_missing_title_returns_422(self, client: AsyncClient):
        """Missing title returns 422."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        response = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={},
        )

        assert response.status_code == 422
        data = response.json()
        assert data["status"] == 422
        assert "errors" in data  # RFC 7807 with errors

    async def test_create_task_empty_title_returns_422(self, client: AsyncClient):
        """Empty title returns 422."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        response = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": ""},
        )

        assert response.status_code == 422

    async def test_create_task_no_auth_returns_401(self, client: AsyncClient):
        """Missing auth returns 401."""
        response = await client.post(
            "/api/v1/tasks",
            json={"title": "Unauthorized Task"},
        )

        assert response.status_code == 401

    async def test_create_task_user_id_from_jwt(self, client: AsyncClient):
        """User ID is set from JWT, not request body."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        response = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "JWT User Task"},
        )

        assert response.status_code == 201
        assert response.json()["user_id"] == user_id


# =============================================================================
# Test: Get Task (GET /api/v1/tasks/{id})
# =============================================================================


class TestGetTask:
    """Tests for GET /api/v1/tasks/{id} endpoint."""

    async def test_get_task_success(self, client: AsyncClient):
        """Get own task returns 200."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create a task
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Get Test Task"},
        )
        task_id = create_resp.json()["id"]

        # Get the task
        response = await client.get(f"/api/v1/tasks/{task_id}", headers=headers)

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == task_id
        assert data["title"] == "Get Test Task"

    async def test_get_task_not_found_returns_404(self, client: AsyncClient):
        """Non-existent task returns 404."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        fake_id = str(uuid4())
        response = await client.get(f"/api/v1/tasks/{fake_id}", headers=headers)

        assert response.status_code == 404
        data = response.json()
        assert data["status"] == 404
        assert "title" in data  # RFC 7807

    async def test_get_task_other_user_returns_404(self, client: AsyncClient):
        """Getting other user's task returns 404 (not 403)."""
        user_a = get_unique_user_id()
        user_b = get_unique_user_id()

        # User A creates a task
        headers_a = get_auth_headers(user_a)
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers_a,
            json={"title": "User A Private Task"},
        )
        task_id = create_resp.json()["id"]

        # User B tries to get it
        headers_b = get_auth_headers(user_b)
        response = await client.get(f"/api/v1/tasks/{task_id}", headers=headers_b)

        assert response.status_code == 404  # Not 403!

    async def test_get_task_invalid_uuid_returns_422(self, client: AsyncClient):
        """Invalid UUID format returns 422."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        response = await client.get("/api/v1/tasks/not-a-uuid", headers=headers)

        assert response.status_code == 422

    async def test_get_task_no_auth_returns_401(self, client: AsyncClient):
        """Missing auth returns 401."""
        fake_id = str(uuid4())
        response = await client.get(f"/api/v1/tasks/{fake_id}")

        assert response.status_code == 401


# =============================================================================
# Test: Update Task (PATCH /api/v1/tasks/{id})
# =============================================================================


class TestUpdateTask:
    """Tests for PATCH /api/v1/tasks/{id} endpoint."""

    async def test_update_task_status(self, client: AsyncClient):
        """Update status to completed."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create a task
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Update Status Test"},
        )
        task_id = create_resp.json()["id"]

        # Update status
        response = await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"status": "completed"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"

    async def test_update_task_title_and_description(self, client: AsyncClient):
        """Update title and description."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create a task
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Original Title"},
        )
        task_id = create_resp.json()["id"]

        # Update title and description
        response = await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"title": "Updated Title", "description": "New Description"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        assert data["description"] == "New Description"

    async def test_update_task_partial(self, client: AsyncClient):
        """Partial update (only status) works."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create a task with description
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Partial Update", "description": "Keep this"},
        )
        task_id = create_resp.json()["id"]

        # Update only status
        response = await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"status": "completed"},
        )

        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert data["title"] == "Partial Update"  # Unchanged
        assert data["description"] == "Keep this"  # Unchanged

    async def test_update_task_not_found_returns_404(self, client: AsyncClient):
        """Updating non-existent task returns 404."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        fake_id = str(uuid4())
        response = await client.patch(
            f"/api/v1/tasks/{fake_id}",
            headers=headers,
            json={"status": "completed"},
        )

        assert response.status_code == 404

    async def test_update_task_other_user_returns_404(self, client: AsyncClient):
        """Updating other user's task returns 404."""
        user_a = get_unique_user_id()
        user_b = get_unique_user_id()

        # User A creates a task
        headers_a = get_auth_headers(user_a)
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers_a,
            json={"title": "User A Task"},
        )
        task_id = create_resp.json()["id"]

        # User B tries to update it
        headers_b = get_auth_headers(user_b)
        response = await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers_b,
            json={"status": "completed"},
        )

        assert response.status_code == 404

    async def test_update_task_invalid_status_returns_422(self, client: AsyncClient):
        """Invalid status value returns 422."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create a task
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Invalid Status Test"},
        )
        task_id = create_resp.json()["id"]

        # Try invalid status
        response = await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"status": "invalid_status"},
        )

        assert response.status_code == 422

    async def test_update_task_empty_title_returns_422(self, client: AsyncClient):
        """Empty title returns 422."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create a task
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Empty Title Test"},
        )
        task_id = create_resp.json()["id"]

        # Try empty title
        response = await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"title": ""},
        )

        assert response.status_code == 422

    async def test_update_task_no_auth_returns_401(self, client: AsyncClient):
        """Missing auth returns 401."""
        fake_id = str(uuid4())
        response = await client.patch(
            f"/api/v1/tasks/{fake_id}",
            json={"status": "completed"},
        )

        assert response.status_code == 401


# =============================================================================
# Test: Delete Task (DELETE /api/v1/tasks/{id})
# =============================================================================


class TestDeleteTask:
    """Tests for DELETE /api/v1/tasks/{id} endpoint."""

    async def test_delete_task_success(self, client: AsyncClient):
        """Delete own task returns 204."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create a task
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Delete Me"},
        )
        task_id = create_resp.json()["id"]

        # Delete it
        response = await client.delete(f"/api/v1/tasks/{task_id}", headers=headers)

        assert response.status_code == 204

        # Verify it's gone
        get_resp = await client.get(f"/api/v1/tasks/{task_id}", headers=headers)
        assert get_resp.status_code == 404

    async def test_delete_task_not_found_returns_404(self, client: AsyncClient):
        """Deleting non-existent task returns 404."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)
        fake_id = str(uuid4())
        response = await client.delete(f"/api/v1/tasks/{fake_id}", headers=headers)

        assert response.status_code == 404

    async def test_delete_task_other_user_returns_404(self, client: AsyncClient):
        """Deleting other user's task returns 404."""
        user_a = get_unique_user_id()
        user_b = get_unique_user_id()

        # User A creates a task
        headers_a = get_auth_headers(user_a)
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers_a,
            json={"title": "User A Task"},
        )
        task_id = create_resp.json()["id"]

        # User B tries to delete it
        headers_b = get_auth_headers(user_b)
        response = await client.delete(f"/api/v1/tasks/{task_id}", headers=headers_b)

        assert response.status_code == 404

        # Verify it still exists for User A
        get_resp = await client.get(f"/api/v1/tasks/{task_id}", headers=headers_a)
        assert get_resp.status_code == 200

    async def test_delete_task_no_auth_returns_401(self, client: AsyncClient):
        """Missing auth returns 401."""
        fake_id = str(uuid4())
        response = await client.delete(f"/api/v1/tasks/{fake_id}")

        assert response.status_code == 401


# =============================================================================
# Test: Authentication Errors
# =============================================================================


class TestAuthErrors:
    """Tests for authentication error handling."""

    async def test_invalid_bearer_format(self, client: AsyncClient):
        """Invalid Bearer format returns 401."""
        response = await client.get(
            "/api/v1/tasks",
            headers={"Authorization": "NotBearer token"},
        )

        assert response.status_code == 401

    async def test_malformed_token(self, client: AsyncClient):
        """Malformed JWT returns 401."""
        response = await client.get(
            "/api/v1/tasks",
            headers={"Authorization": "Bearer not.a.valid.jwt.token"},
        )

        assert response.status_code == 401

    async def test_expired_token(self, client: AsyncClient):
        """Expired JWT returns 401."""
        token = create_test_token(TEST_USER_ID, expired=True)
        response = await client.get(
            "/api/v1/tasks",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 401

    async def test_missing_sub_claim(self, client: AsyncClient):
        """Token missing 'sub' claim returns 401."""
        token = create_test_token(TEST_USER_ID, missing_sub=True)
        response = await client.get(
            "/api/v1/tasks",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == 401

    async def test_401_response_format(self, client: AsyncClient):
        """401 responses follow RFC 7807 format."""
        response = await client.get("/api/v1/tasks")

        assert response.status_code == 401
        data = response.json()
        assert "type" in data
        assert "title" in data
        assert "status" in data
        assert data["status"] == 401


# =============================================================================
# Test: Search Tasks (Chunk 4 - FR-001 to FR-006)
# =============================================================================


class TestSearchTasks:
    """Tests for search functionality in GET /api/v1/tasks."""

    async def test_search_by_title(self, client: AsyncClient):
        """Search finds tasks with matching title (FR-001)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create tasks with different titles
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Weekly Report"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Monthly Report"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Buy groceries"},
        )

        # Search for "report"
        response = await client.get(
            "/api/v1/tasks?search=report",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        titles = [t["title"] for t in data]
        assert "Weekly Report" in titles
        assert "Monthly Report" in titles
        assert "Buy groceries" not in titles

    async def test_search_by_description(self, client: AsyncClient):
        """Search finds tasks with matching description (FR-002)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create task with searchable description
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Finance Task", "description": "Review the budget report"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Other Task", "description": "Something else"},
        )

        # Search for "budget"
        response = await client.get(
            "/api/v1/tasks?search=budget",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["title"] == "Finance Task"

    async def test_search_case_insensitive(self, client: AsyncClient):
        """Search is case-insensitive (FR-003)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Weekly Report"},
        )

        # Search with uppercase
        response = await client.get(
            "/api/v1/tasks?search=REPORT",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["title"] == "Weekly Report"

        # Search with mixed case
        response = await client.get(
            "/api/v1/tasks?search=RePoRt",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1

    async def test_search_with_status_filter(self, client: AsyncClient):
        """Search combines with status filter using AND logic (FR-004)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create pending report
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Pending Report"},
        )

        # Create completed report
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Completed Report"},
        )
        task_id = create_resp.json()["id"]
        await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"status": "completed"},
        )

        # Search for "report" with status=pending
        response = await client.get(
            "/api/v1/tasks?search=report&status=pending",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["title"] == "Pending Report"
        assert data[0]["status"] == "pending"

    async def test_search_empty_returns_all(self, client: AsyncClient):
        """Empty search returns all tasks (FR-005)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Task 1"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Task 2"},
        )

        # Empty search parameter
        response = await client.get(
            "/api/v1/tasks?search=",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    async def test_search_whitespace_only_returns_all(self, client: AsyncClient):
        """Whitespace-only search treated as no filter (FR-005)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Task 1"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Task 2"},
        )

        # Whitespace search
        response = await client.get(
            "/api/v1/tasks?search=   ",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    async def test_search_no_matches_returns_empty(self, client: AsyncClient):
        """Search with no matches returns empty list."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Some Task"},
        )

        response = await client.get(
            "/api/v1/tasks?search=nonexistent",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 0

    async def test_search_user_isolation(self, client: AsyncClient):
        """Search only finds tasks belonging to authenticated user."""
        user_a = get_unique_user_id()
        user_b = get_unique_user_id()

        # User A creates a report task
        headers_a = get_auth_headers(user_a)
        await client.post(
            "/api/v1/tasks",
            headers=headers_a,
            json={"title": "User A Report"},
        )

        # User B creates a report task
        headers_b = get_auth_headers(user_b)
        await client.post(
            "/api/v1/tasks",
            headers=headers_b,
            json={"title": "User B Report"},
        )

        # User A searches - should only find their own
        response = await client.get(
            "/api/v1/tasks?search=report",
            headers=headers_a,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["user_id"] == user_a
        assert data[0]["title"] == "User A Report"


# =============================================================================
# Test: Sort Tasks (Chunk 4 - FR-008 to FR-011)
# =============================================================================


class TestSortTasks:
    """Tests for sorting functionality in GET /api/v1/tasks."""

    async def test_default_sort_newest_first(self, client: AsyncClient):
        """Default sort is created_at DESC (FR-010)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create tasks in order
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "First Task"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Second Task"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Third Task"},
        )

        # Get tasks without sort params (default)
        response = await client.get("/api/v1/tasks", headers=headers)

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        # Newest first
        assert data[0]["title"] == "Third Task"
        assert data[1]["title"] == "Second Task"
        assert data[2]["title"] == "First Task"

    async def test_sort_created_at_asc(self, client: AsyncClient):
        """Sort by created_at ascending (oldest first) (FR-008)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "First Task"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Second Task"},
        )

        response = await client.get(
            "/api/v1/tasks?sort=created_at&order=asc",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        # Oldest first
        assert data[0]["title"] == "First Task"
        assert data[1]["title"] == "Second Task"

    async def test_sort_title_asc(self, client: AsyncClient):
        """Sort by title A-Z, case-insensitive (FR-009)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Zebra Task"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "apple Task"},  # lowercase
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Banana Task"},
        )

        response = await client.get(
            "/api/v1/tasks?sort=title&order=asc",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        # A-Z (case-insensitive: apple < Banana < Zebra)
        assert data[0]["title"] == "apple Task"
        assert data[1]["title"] == "Banana Task"
        assert data[2]["title"] == "Zebra Task"

    async def test_sort_title_desc(self, client: AsyncClient):
        """Sort by title Z-A, case-insensitive (FR-009)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Zebra Task"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "apple Task"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Banana Task"},
        )

        response = await client.get(
            "/api/v1/tasks?sort=title&order=desc",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        # Z-A (case-insensitive)
        assert data[0]["title"] == "Zebra Task"
        assert data[1]["title"] == "Banana Task"
        assert data[2]["title"] == "apple Task"

    async def test_sort_with_search_applied(self, client: AsyncClient):
        """Sort applies after search filter (FR-011)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Zebra Report"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Apple Report"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Other Task"},  # Won't match search
        )

        response = await client.get(
            "/api/v1/tasks?search=report&sort=title&order=asc",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2  # Only reports
        assert data[0]["title"] == "Apple Report"
        assert data[1]["title"] == "Zebra Report"

    async def test_invalid_sort_returns_422(self, client: AsyncClient):
        """Invalid sort value returns 422 (FR-023)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        response = await client.get(
            "/api/v1/tasks?sort=invalid_field",
            headers=headers,
        )

        assert response.status_code == 422

    async def test_invalid_order_returns_422(self, client: AsyncClient):
        """Invalid order value returns 422 (FR-023)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        response = await client.get(
            "/api/v1/tasks?order=invalid_order",
            headers=headers,
        )

        assert response.status_code == 422


# =============================================================================
# Test: Search Edge Cases (Chunk 4 - FR-006)
# =============================================================================


class TestSearchEdgeCases:
    """Tests for search edge cases and validation."""

    async def test_search_special_characters(self, client: AsyncClient):
        """Special characters in search don't cause errors."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Task with % percent"},
        )

        # Search with special SQL characters
        response = await client.get(
            "/api/v1/tasks?search=%",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1

    async def test_search_sql_injection_safe(self, client: AsyncClient):
        """Search is safe from SQL injection attempts."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Normal Task"},
        )

        # Attempt SQL injection
        response = await client.get(
            "/api/v1/tasks?search='; DROP TABLE task; --",
            headers=headers,
        )

        # Should return empty (no match) but not error
        assert response.status_code == 200

    async def test_search_max_length_accepted(self, client: AsyncClient):
        """Search at max length (100 chars) is accepted."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Exactly 100 characters
        search_term = "a" * 100

        response = await client.get(
            f"/api/v1/tasks?search={search_term}",
            headers=headers,
        )

        assert response.status_code == 200

    async def test_search_over_max_length_returns_422(self, client: AsyncClient):
        """Search over max length (101 chars) returns 422 (FR-006)."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # 101 characters - over limit
        search_term = "a" * 101

        response = await client.get(
            f"/api/v1/tasks?search={search_term}",
            headers=headers,
        )

        assert response.status_code == 422

    async def test_search_unicode_characters(self, client: AsyncClient):
        """Search with unicode characters works correctly."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "日本語タスク"},
        )

        response = await client.get(
            "/api/v1/tasks?search=日本語",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1


# =============================================================================
# Test: Combined Filters (Chunk 4 - SC-005)
# =============================================================================


class TestCombinedFilters:
    """Tests for combined filter, search, sort, and pagination."""

    async def test_status_search_sort_combined(self, client: AsyncClient):
        """Status + search + sort work together correctly."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create various tasks
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Zebra Report"},
        )
        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Apple Report"},
        )

        # Create and complete a report
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Completed Report"},
        )
        task_id = create_resp.json()["id"]
        await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"status": "completed"},
        )

        # Query: pending + report + title asc
        response = await client.get(
            "/api/v1/tasks?status=pending&search=report&sort=title&order=asc",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert all(t["status"] == "pending" for t in data)
        assert data[0]["title"] == "Apple Report"
        assert data[1]["title"] == "Zebra Report"

    async def test_filters_with_pagination(self, client: AsyncClient):
        """Filters work correctly with pagination."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        # Create 10 report tasks
        for i in range(10):
            await client.post(
                "/api/v1/tasks",
                headers=headers,
                json={"title": f"Report {i+1:02d}"},
            )

        # Create 5 non-report tasks
        for i in range(5):
            await client.post(
                "/api/v1/tasks",
                headers=headers,
                json={"title": f"Other {i+1}"},
            )

        # Search with pagination
        response = await client.get(
            "/api/v1/tasks?search=report&offset=0&limit=5",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5
        assert all("Report" in t["title"] for t in data)

        # Get page 2
        response = await client.get(
            "/api/v1/tasks?search=report&offset=5&limit=5",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 5
        assert all("Report" in t["title"] for t in data)

    async def test_empty_results_with_combined_filters(self, client: AsyncClient):
        """Combined filters returning no results return empty list."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Pending Task"},
        )

        # Create and complete a task
        create_resp = await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Completed Task"},
        )
        task_id = create_resp.json()["id"]
        await client.patch(
            f"/api/v1/tasks/{task_id}",
            headers=headers,
            json={"status": "completed"},
        )

        # Query for completed + "pending" (no match)
        response = await client.get(
            "/api/v1/tasks?status=completed&search=pending",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 0

    async def test_offset_beyond_results(self, client: AsyncClient):
        """Offset beyond total results returns empty list."""
        user_id = get_unique_user_id()
        headers = get_auth_headers(user_id)

        await client.post(
            "/api/v1/tasks",
            headers=headers,
            json={"title": "Only Task"},
        )

        response = await client.get(
            "/api/v1/tasks?offset=100",
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 0
