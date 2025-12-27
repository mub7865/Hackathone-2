"""Custom exceptions and RFC 7807 exception handlers for FastAPI."""

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.schemas.error import ProblemDetail, ValidationErrorDetail, ValidationErrorItem


class AuthenticationError(Exception):
    """Raised when JWT authentication fails."""

    def __init__(self, detail: str = "Authentication failed"):
        self.detail = detail
        super().__init__(detail)


class TaskNotFoundError(Exception):
    """Raised when a task is not found or not owned by the user."""

    def __init__(self, task_id: str | None = None):
        self.task_id = task_id
        detail = f"Task {task_id} not found" if task_id else "Task not found"
        super().__init__(detail)


async def authentication_error_handler(
    request: Request, exc: AuthenticationError
) -> JSONResponse:
    """Handle AuthenticationError with RFC 7807 response.

    Returns 401 Unauthorized with ProblemDetail body.
    """
    problem = ProblemDetail(
        type="about:blank",
        title="Unauthorized",
        status=401,
        detail=exc.detail,
        instance=str(request.url.path),
    )
    return JSONResponse(
        status_code=401,
        content=problem.model_dump(exclude_none=True),
    )


async def task_not_found_handler(
    request: Request, exc: TaskNotFoundError
) -> JSONResponse:
    """Handle TaskNotFoundError with RFC 7807 response.

    Returns 404 Not Found with ProblemDetail body.
    Note: We use 404 (not 403) even for other users' tasks to prevent enumeration.
    """
    problem = ProblemDetail(
        type="about:blank",
        title="Not Found",
        status=404,
        detail=str(exc),
        instance=str(request.url.path),
    )
    return JSONResponse(
        status_code=404,
        content=problem.model_dump(exclude_none=True),
    )


async def validation_error_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    """Handle Pydantic validation errors with RFC 7807 response.

    Returns 422 Unprocessable Entity with ValidationErrorDetail body.
    """
    errors = [
        ValidationErrorItem(
            loc=list(err.get("loc", [])),
            msg=err.get("msg", "Validation error"),
            type=err.get("type", "value_error"),
        )
        for err in exc.errors()
    ]

    problem = ValidationErrorDetail(
        type="about:blank",
        title="Validation Error",
        status=422,
        detail="Request validation failed",
        instance=str(request.url.path),
        errors=errors,
    )
    return JSONResponse(
        status_code=422,
        content=problem.model_dump(exclude_none=True),
    )


async def generic_exception_handler(
    request: Request, exc: Exception
) -> JSONResponse:
    """Handle unexpected exceptions with RFC 7807 response.

    Returns 500 Internal Server Error with minimal detail.
    """
    problem = ProblemDetail(
        type="about:blank",
        title="Internal Server Error",
        status=500,
        detail="An unexpected error occurred",
        instance=str(request.url.path),
    )
    return JSONResponse(
        status_code=500,
        content=problem.model_dump(exclude_none=True),
    )


def register_exception_handlers(app: FastAPI) -> None:
    """Register all exception handlers with the FastAPI app.

    Args:
        app: FastAPI application instance
    """
    app.add_exception_handler(AuthenticationError, authentication_error_handler)
    app.add_exception_handler(TaskNotFoundError, task_not_found_handler)
    app.add_exception_handler(RequestValidationError, validation_error_handler)
    # Optionally add generic handler for production
    # app.add_exception_handler(Exception, generic_exception_handler)
