"""
Standard FastAPI error handling using Problem Details (application/problem+json).

PURPOSE:
- Provide a central way to return RFC 7807-style error responses.
- Map common HTTPException / validation errors into a consistent JSON shape.
- Make it easy for other Skills (CRUD, auth, etc.) to reuse the same pattern.

HOW TO USE:
- Place this file somewhere like: app/core/error_handling.py
- Import and call `register_problem_details_handlers(app)` from main.py
  after creating the FastAPI app.
- Always raise fastapi.HTTPException or custom exceptions that this
  handler can map.

REFERENCES:
- RFC 7807 "Problem Details for HTTP APIs"
- FastAPI error handling patterns
"""

from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import ValidationError


def _build_problem_details(
    *,
    status_code: int,
    title: str,
    detail: str,
    instance: str,
    type_uri: str = "https://example.com/errors/generic-error",
    errors: Optional[List[Dict[str, Any]]] = None,
) -> Dict[str, Any]:
    """
    Build a Problem Details (RFC 7807-style) JSON object.

    FIELDS:
    - type:     URI identifying the problem type
    - title:    Short, human-readable summary of the problem type
    - status:   HTTP status code
    - detail:   Human-readable explanation for this occurrence
    - instance: Request path or unique error occurrence identifier
    - errors:   Optional list of field-level error objects
    """
    problem: Dict[str, Any] = {
        "type": type_uri,
        "title": title,
        "status": status_code,
        "detail": detail,
        "instance": instance,
    }
    if errors:
        problem["errors"] = errors
    return problem


async def http_exception_handler(
    request: Request,
    exc: HTTPException,
) -> JSONResponse:
    """
    Handle FastAPI HTTPException as Problem Details.

    - Uses exc.status_code as HTTP status.
    - Uses exc.detail for the `detail` field (stringified if needed).
    """
    # Normalize detail to string
    if isinstance(exc.detail, dict):
        detail = exc.detail.get("detail") or str(exc.detail)
    else:
        detail = str(exc.detail)

    problem = _build_problem_details(
        status_code=exc.status_code,
        title=_title_for_status(exc.status_code),
        detail=detail,
        instance=request.url.path,
        type_uri=_type_uri_for_status(exc.status_code),
    )

    return JSONResponse(
        status_code=exc.status_code,
        content=problem,
        media_type="application/problem+json",
    )


async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    """
    Handle FastAPI request validation errors (422) as Problem Details.

    - Extracts field errors into an `errors` array.
    - Uses status 422 Unprocessable Entity by default.
    """
    status_code = status.HTTP_422_UNPROCESSABLE_ENTITY

    field_errors: List[Dict[str, Any]] = []
    for err in exc.errors():
        # Example err structure:
        # {"loc": ("body", "title"), "msg": "field required", "type": "value_error.missing"}
        loc = err.get("loc", [])
        # Drop 'body', 'query', etc. from the path prefix for clarity.
        field_path = ".".join(str(p) for p in loc[1:]) if len(loc) > 1 else ""
        field_errors.append(
            {
                "field": field_path or None,
                "message": err.get("msg"),
                "code": err.get("type"),
            }
        )

    problem = _build_problem_details(
        status_code=status_code,
        title="Validation failed",
        detail="One or more fields are invalid.",
        instance=request.url.path,
        type_uri="https://example.com/errors/validation-error",
        errors=field_errors,
    )

    return JSONResponse(
        status_code=status_code,
        content=problem,
        media_type="application/problem+json",
    )


async def pydantic_validation_exception_handler(
    request: Request,
    exc: ValidationError,
) -> JSONResponse:
    """
    Optional: Handle Pydantic ValidationError in a similar way
    (useful if you manually validate models outside of FastAPI's
    automatic request validation).
    """
    status_code = status.HTTP_422_UNPROCESSABLE_ENTITY

    field_errors: List[Dict[str, Any]] = []
    for err in exc.errors():
        loc = err.get("loc", [])
        field_path = ".".join(str(p) for p in loc) if loc else ""
        field_errors.append(
            {
                "field": field_path or None,
                "message": err.get("msg"),
                "code": err.get("type"),
            }
        )

    problem = _build_problem_details(
        status_code=status_code,
        title="Validation failed",
        detail="One or more fields are invalid.",
        instance=request.url.path,
        type_uri="https://example.com/errors/validation-error",
        errors=field_errors,
    )

    return JSONResponse(
        status_code=status_code,
        content=problem,
        media_type="application/problem+json",
    )


def register_problem_details_handlers(app: FastAPI) -> None:
    """
    Register Problem Details handlers on a FastAPI app.

    HOW TO USE (in main.py):

        from fastapi import FastAPI
        from app.core.error_handling import register_problem_details_handlers

        app = FastAPI()
        register_problem_details_handlers(app)

    After registration:
    - Any HTTPException will be returned as application/problem+json.
    - Any RequestValidationError will use the validation Problem Details shape.
    """
    from fastapi.exceptions import RequestValidationError as FAPIValidationError

    app.add_exception_handler(HTTPException, http_exception_handler)
    app.add_exception_handler(FAPIValidationError, validation_exception_handler)
    # Optional: if you want to catch raw Pydantic ValidationError:
    app.add_exception_handler(ValidationError, pydantic_validation_exception_handler)


def _title_for_status(status_code: int) -> str:
    """
    Provide a short default title per common HTTP status code.
    """
    mapping = {
        400: "Bad Request",
        401: "Unauthorized",
        403: "Forbidden",
        404: "Not Found",
        409: "Conflict",
        422: "Unprocessable Entity",
        500: "Internal Server Error",
    }
    return mapping.get(status_code, "Error")


def _type_uri_for_status(status_code: int) -> str:
    """
    Provide a default type URI per common HTTP status code.

    Projects may override these with their own stable URLs later.
    """
    base = "https://example.com/errors"
    mapping = {
        400: f"{base}/bad-request",
        401: f"{base}/unauthorized",
        403: f"{base}/forbidden",
        404: f"{base}/not-found",
        409: f"{base}/conflict",
        422: f"{base}/validation-error",
        500: f"{base}/internal-server-error",
    }
    return mapping.get(status_code, f"{base}/generic-error")
