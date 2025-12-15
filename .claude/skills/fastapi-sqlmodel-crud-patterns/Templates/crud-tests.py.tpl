"""
Basic pytest template for testing FastAPI + SQLModel CRUD endpoints.

PURPOSE:
- Encourage consistent testing patterns for CRUD APIs.
- Cover happy paths and common error cases.

HOW TO USE:
- Adjust resource names, URLs, and payloads for your domain.
- Integrate with your test client and test database fixtures.
"""

from fastapi.testclient import TestClient
from sqlmodel import SQLModel, Session, create_engine
import pytest

from app.main import app  # adjust as needed
from app.db import get_session  # adjust as needed


@pytest.fixture(name="test_client")
def fixture_test_client():
  # Example: in-memory SQLite for tests; adjust for your project.
  test_engine = create_engine("sqlite://", connect_args={"check_same_thread": False})
  SQLModel.metadata.create_all(test_engine)

  def override_get_session():
    with Session(test_engine) as session:
      yield session

  app.dependency_overrides[get_session] = override_get_session

  with TestClient(app) as client:
    yield client

  app.dependency_overrides.clear()


def test_create_resource(test_client: TestClient):
  response = test_client.post(
    "/resources",
    json={"name": "example"},  # adjust payload
  )
  assert response.status_code == 201
  data = response.json()
  assert data["id"] is not None
  assert data["name"] == "example"


def test_list_resources(test_client: TestClient):
  response = test_client.get("/resources")
  assert response.status_code == 200
  assert isinstance(response.json(), list)


def test_get_resource_not_found(test_client: TestClient):
  response = test_client.get("/resources/9999")
  assert response.status_code == 404
