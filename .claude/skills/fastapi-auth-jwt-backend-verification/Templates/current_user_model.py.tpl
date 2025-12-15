"""
Standard CurrentUser model for FastAPI JWT authentication.

PURPOSE:
- Represent the authenticated user derived from a verified JWT.
- Provide a stable type for dependencies like get_current_user().
- Keep token-specific details (raw claims) available when needed.

HOW TO USE:
- Place this file under something like `app/auth/models.py`.
- Import CurrentUser in your JWT dependency module.
- Use CurrentUser as the type for `current_user` in protected routes.
"""

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, EmailStr


class CurrentUser(BaseModel):
    """
    Generic representation of the authenticated user.

    FIELDS:
    - id: stable user identifier (e.g. sub, user_id).
    - email: optional email address from token claims.
    - roles: optional list of roles/permissions from token claims.
    - raw_claims: full decoded JWT payload for advanced use cases.
    """

    id: str
    email: Optional[EmailStr] = None
    roles: List[str] = []
    raw_claims: Dict[str, Any] = {}
