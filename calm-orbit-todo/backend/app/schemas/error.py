"""RFC 7807 Problem Details error response schemas."""

from pydantic import BaseModel, Field


class ProblemDetail(BaseModel):
    """RFC 7807 Problem Details error response.

    Provides a consistent, machine-readable error format for all API errors.
    See: https://datatracker.ietf.org/doc/html/rfc7807
    """

    type: str = Field(
        default="about:blank",
        description="URI reference identifying the problem type",
    )
    title: str = Field(
        description="Short human-readable summary of the problem",
    )
    status: int = Field(
        description="HTTP status code for this occurrence",
    )
    detail: str | None = Field(
        default=None,
        description="Human-readable explanation specific to this occurrence",
    )
    instance: str | None = Field(
        default=None,
        description="URI reference identifying the specific occurrence",
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "type": "about:blank",
                    "title": "Not Found",
                    "status": 404,
                    "detail": "Task not found",
                    "instance": "/api/v1/tasks/550e8400-e29b-41d4-a716-446655440099",
                },
                {
                    "type": "about:blank",
                    "title": "Unauthorized",
                    "status": 401,
                    "detail": "Missing or invalid authentication token",
                },
            ]
        }
    }


class ValidationErrorItem(BaseModel):
    """Single validation error with location."""

    loc: list[str | int] = Field(
        description="Error location path (e.g., ['body', 'title'])",
    )
    msg: str = Field(
        description="Error message",
    )
    type: str = Field(
        description="Error type identifier",
    )


class ValidationErrorDetail(ProblemDetail):
    """RFC 7807 Problem Details with validation error array.

    Used for 422 Unprocessable Entity responses with field-level errors.
    """

    errors: list[ValidationErrorItem] = Field(
        default_factory=list,
        description="List of validation errors with field locations",
    )

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "type": "about:blank",
                    "title": "Validation Error",
                    "status": 422,
                    "detail": "Request validation failed",
                    "errors": [
                        {
                            "loc": ["body", "title"],
                            "msg": "Field required",
                            "type": "missing",
                        }
                    ],
                }
            ]
        }
    }
