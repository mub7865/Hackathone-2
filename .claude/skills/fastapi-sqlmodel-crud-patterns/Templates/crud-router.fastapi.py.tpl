"""
Generic FastAPI + SQLModel CRUD router template.

PURPOSE:
- Provide a standard pattern for CRUD endpoints for any resource.
- Keep resource-specific logic in one module under routers/.
- Use the shared get_session() dependency.

HOW TO USE:
- Copy/adapt this template for each resource (e.g. Task, Item, Project).
- Replace `Resource`, `ResourceCreate`, `ResourceUpdate`, and the
  path prefix with domain-specific names.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from app.db import get_session  # adjust import path
from app.models import Resource, ResourceCreate, ResourceUpdate  # adjust names/imports


router = APIRouter(
  prefix="/resources",  # e.g. "/tasks"
  tags=["resources"],   # e.g. ["tasks"]
)


def _get_resource_or_404(
  session: Session,
  resource_id: int,
) -> Resource:
  statement = select(Resource).where(Resource.id == resource_id)
  resource = session.exec(statement).first()
  if not resource:
    raise HTTPException(
      status_code=status.HTTP_404_NOT_FOUND,
      detail="Resource not found",
    )
  return resource


@router.get(
  "",
  response_model=List[Resource],
  summary="List resources",
)
def list_resources(
  session: Session = Depends(get_session),
) -> List[Resource]:
  """
  List all resources.

  Extend this with filtering, sorting, and pagination as needed.
  """
  statement = select(Resource)
  items = session.exec(statement).all()
  return items


@router.post(
  "",
  response_model=Resource,
  status_code=status.HTTP_201_CREATED,
  summary="Create a resource",
)
def create_resource(
  payload: ResourceCreate,
  session: Session = Depends(get_session),
) -> Resource:
  """
  Create a new resource.
  """
  item = Resource.from_orm(payload)
  session.add(item)
  session.commit()
  session.refresh(item)
  return item


@router.get(
  "/{resource_id}",
  response_model=Resource,
  summary="Get a single resource",
)
def get_resource(
  resource_id: int,
  session: Session = Depends(get_session),
) -> Resource:
  """
  Get a single resource by id.
  """
  item = _get_resource_or_404(session, resource_id)
  return item


@router.put(
  "/{resource_id}",
  response_model=Resource,
  summary="Update a resource",
)
def update_resource(
  resource_id: int,
  payload: ResourceUpdate,
  session: Session = Depends(get_session),
) -> Resource:
  """
  Replace a resource's editable fields.
  """
  item = _get_resource_or_404(session, resource_id)

  update_data = payload.dict(exclude_unset=True)
  for key, value in update_data.items():
    setattr(item, key, value)

  session.add(item)
  session.commit()
  session.refresh(item)
  return item


@router.delete(
  "/{resource_id}",
  status_code=status.HTTP_204_NO_CONTENT,
  summary="Delete a resource",
)
def delete_resource(
  resource_id: int,
  session: Session = Depends(get_session),
) -> None:
  """
  Delete a resource.
  """
  item = _get_resource_or_404(session, resource_id)
  session.delete(item)
  session.commit()
  return None
