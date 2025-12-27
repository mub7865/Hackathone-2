"""Create task table.

Revision ID: 001
Revises:
Create Date: 2025-12-12

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create the task table with all columns, indexes, and constraints."""
    op.create_table(
        "task",
        sa.Column("id", sa.UUID(), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="pending"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.CheckConstraint(
            "status IN ('pending', 'completed')", name="chk_task_status"
        ),
        sa.CheckConstraint(
            "length(trim(title)) > 0", name="chk_task_title_not_empty"
        ),
    )

    # Create indexes
    op.create_index("ix_task_user_id", "task", ["user_id"], unique=False)
    op.create_index("ix_task_user_status", "task", ["user_id", "status"], unique=False)


def downgrade() -> None:
    """Drop the task table and its indexes."""
    op.drop_index("ix_task_user_status", table_name="task")
    op.drop_index("ix_task_user_id", table_name="task")
    op.drop_table("task")
