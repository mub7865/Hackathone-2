"""Add Phase V schema (event-driven features).

Revision ID: 004_add_phase5_schema
Revises: 003_add_phase3_chat_tables
Create Date: 2026-01-12

This migration adds:
- New columns to tasks: priority, tags, due_date, remind_at, recurring_pattern_id
- recurring_patterns table: recurrence rules for recurring tasks
- audit_log table: event history for compliance tracking
- notification_preferences table: user notification settings
- saved_filters table: user-defined filter combinations
- processed_events table: idempotency tracking for event consumers
- Indexes for Phase V query patterns
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "004"
down_revision: str | None = "003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add Phase V schema changes."""

    # -------------------------------------------------------------------------
    # 1. Add new columns to tasks table
    # -------------------------------------------------------------------------
    op.add_column(
        "task",
        sa.Column(
            "priority",
            sa.String(10),
            nullable=False,
            server_default="medium",
        ),
    )

    op.add_column(
        "task",
        sa.Column(
            "tags",
            postgresql.ARRAY(sa.String()),
            nullable=False,
            server_default="{}",
        ),
    )

    op.add_column(
        "task",
        sa.Column(
            "due_date",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    op.add_column(
        "task",
        sa.Column(
            "remind_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
    )

    op.add_column(
        "task",
        sa.Column(
            "recurring_pattern_id",
            postgresql.UUID(as_uuid=True),
            nullable=True,
        ),
    )

    # Add check constraint for priority
    op.create_check_constraint(
        "chk_task_priority",
        "task",
        "priority IN ('high', 'medium', 'low')",
    )

    # -------------------------------------------------------------------------
    # 2. Create recurring_patterns table
    # -------------------------------------------------------------------------
    op.create_table(
        "recurring_patterns",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("user_id", sa.String(36), nullable=False),
        sa.Column("original_task_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("frequency", sa.String(20), nullable=False),
        sa.Column("interval", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("days_of_week", postgresql.ARRAY(sa.Integer()), nullable=True),
        sa.Column("day_of_month", sa.Integer(), nullable=True),
        sa.Column("month_of_year", sa.Integer(), nullable=True),
        sa.Column("cron_expression", sa.String(100), nullable=True),
        sa.Column("end_condition", sa.String(20), nullable=False),
        sa.Column("end_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("occurrence_count", sa.Integer(), nullable=True),
        sa.Column("current_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )

    # Add constraints for recurring_patterns
    op.create_check_constraint(
        "chk_frequency",
        "recurring_patterns",
        "frequency IN ('daily', 'weekly', 'monthly', 'yearly', 'custom')",
    )

    op.create_check_constraint(
        "chk_end_condition",
        "recurring_patterns",
        "end_condition IN ('date', 'count', 'indefinite')",
    )

    op.create_check_constraint(
        "chk_interval_positive",
        "recurring_patterns",
        "interval > 0",
    )

    op.create_check_constraint(
        "chk_day_of_month",
        "recurring_patterns",
        "day_of_month BETWEEN -1 AND 31 OR day_of_month IS NULL",
    )

    op.create_check_constraint(
        "chk_month_of_year",
        "recurring_patterns",
        "month_of_year BETWEEN 1 AND 12 OR month_of_year IS NULL",
    )

    op.create_check_constraint(
        "chk_occurrence_count",
        "recurring_patterns",
        "occurrence_count IS NULL OR occurrence_count > 0",
    )

    # -------------------------------------------------------------------------
    # 3. Create audit_log table
    # -------------------------------------------------------------------------
    op.create_table(
        "audit_log",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("event_id", postgresql.UUID(as_uuid=True), nullable=False, unique=True),
        sa.Column("event_type", sa.String(50), nullable=False),
        sa.Column("task_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("operation", sa.String(20), nullable=False),
        sa.Column("event_payload", postgresql.JSONB(), nullable=False),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "processed_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )

    # -------------------------------------------------------------------------
    # 4. Create notification_preferences table
    # -------------------------------------------------------------------------
    op.create_table(
        "notification_preferences",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False, unique=True),
        sa.Column("email_enabled", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("inapp_enabled", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("quiet_hours_start", sa.Time(), nullable=True),
        sa.Column("quiet_hours_end", sa.Time(), nullable=True),
        sa.Column("max_notifications_per_hour", sa.Integer(), nullable=False, server_default="10"),
        sa.Column("timezone", sa.String(50), nullable=False, server_default="'UTC'"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )

    # Add constraint for notification_preferences
    op.create_check_constraint(
        "chk_max_notifications_positive",
        "notification_preferences",
        "max_notifications_per_hour > 0",
    )

    # -------------------------------------------------------------------------
    # 5. Create saved_filters table
    # -------------------------------------------------------------------------
    op.create_table(
        "saved_filters",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("filter_criteria", postgresql.JSONB(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )

    # Add unique constraint for saved_filters
    op.create_unique_constraint(
        "uq_saved_filters_user_name",
        "saved_filters",
        ["user_id", "name"],
    )

    # -------------------------------------------------------------------------
    # 6. Create processed_events table
    # -------------------------------------------------------------------------
    op.create_table(
        "processed_events",
        sa.Column("event_id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("service_name", sa.String(50), nullable=False),
        sa.Column("event_type", sa.String(50), nullable=False),
        sa.Column(
            "processed_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )

    # Add unique constraint for processed_events
    op.create_unique_constraint(
        "uq_processed_events_service",
        "processed_events",
        ["event_id", "service_name"],
    )

    # -------------------------------------------------------------------------
    # 7. Add foreign key constraint from tasks to recurring_patterns
    # -------------------------------------------------------------------------
    op.create_foreign_key(
        "fk_tasks_recurring_pattern",
        "task",
        "recurring_patterns",
        ["recurring_pattern_id"],
        ["id"],
        ondelete="SET NULL",
    )

    # -------------------------------------------------------------------------
    # 8. Create indexes for Phase V queries
    # -------------------------------------------------------------------------

    # Task indexes
    op.create_index("ix_task_priority", "task", ["priority"])
    op.create_index("ix_task_tags", "task", ["tags"], postgresql_using="gin")
    op.create_index(
        "ix_task_due_date",
        "task",
        ["due_date"],
        postgresql_where=sa.text("due_date IS NOT NULL"),
    )
    op.create_index(
        "ix_task_remind_at",
        "task",
        ["remind_at"],
        postgresql_where=sa.text("remind_at IS NOT NULL"),
    )
    op.create_index(
        "ix_task_recurring_pattern_id",
        "task",
        ["recurring_pattern_id"],
        postgresql_where=sa.text("recurring_pattern_id IS NOT NULL"),
    )
    op.create_index(
        "ix_task_user_status_priority",
        "task",
        ["user_id", "status", "priority"],
    )

    # Recurring patterns indexes
    op.create_index("ix_recurring_patterns_user_id", "recurring_patterns", ["user_id"])
    op.create_index(
        "ix_recurring_patterns_original_task_id",
        "recurring_patterns",
        ["original_task_id"],
    )

    # Audit log indexes
    op.create_index("ix_audit_log_event_id", "audit_log", ["event_id"])
    op.create_index("ix_audit_log_task_id", "audit_log", ["task_id"])
    op.create_index("ix_audit_log_user_id", "audit_log", ["user_id"])
    op.create_index("ix_audit_log_event_type", "audit_log", ["event_type"])
    op.create_index("ix_audit_log_timestamp", "audit_log", ["timestamp"])
    op.create_index(
        "ix_audit_log_event_payload",
        "audit_log",
        ["event_payload"],
        postgresql_using="gin",
    )

    # Notification preferences indexes
    op.create_index(
        "ix_notification_preferences_user_id",
        "notification_preferences",
        ["user_id"],
    )

    # Saved filters indexes
    op.create_index("ix_saved_filters_user_id", "saved_filters", ["user_id"])

    # Processed events indexes
    op.create_index("ix_processed_events_service_name", "processed_events", ["service_name"])
    op.create_index("ix_processed_events_processed_at", "processed_events", ["processed_at"])
    op.create_index(
        "ix_processed_events_cleanup",
        "processed_events",
        ["processed_at"],
        postgresql_where=sa.text("processed_at < NOW() - INTERVAL '7 days'"),
    )


def downgrade() -> None:
    """Remove Phase V schema changes."""

    # Drop indexes first
    op.drop_index("ix_processed_events_cleanup", table_name="processed_events")
    op.drop_index("ix_processed_events_processed_at", table_name="processed_events")
    op.drop_index("ix_processed_events_service_name", table_name="processed_events")
    op.drop_index("ix_saved_filters_user_id", table_name="saved_filters")
    op.drop_index("ix_notification_preferences_user_id", table_name="notification_preferences")
    op.drop_index("ix_audit_log_event_payload", table_name="audit_log")
    op.drop_index("ix_audit_log_timestamp", table_name="audit_log")
    op.drop_index("ix_audit_log_event_type", table_name="audit_log")
    op.drop_index("ix_audit_log_user_id", table_name="audit_log")
    op.drop_index("ix_audit_log_task_id", table_name="audit_log")
    op.drop_index("ix_audit_log_event_id", table_name="audit_log")
    op.drop_index("ix_recurring_patterns_original_task_id", table_name="recurring_patterns")
    op.drop_index("ix_recurring_patterns_user_id", table_name="recurring_patterns")
    op.drop_index("ix_task_user_status_priority", table_name="task")
    op.drop_index("ix_task_recurring_pattern_id", table_name="task")
    op.drop_index("ix_task_remind_at", table_name="task")
    op.drop_index("ix_task_due_date", table_name="task")
    op.drop_index("ix_task_tags", table_name="task")
    op.drop_index("ix_task_priority", table_name="task")

    # Drop foreign key constraint
    op.drop_constraint("fk_tasks_recurring_pattern", "task", type_="foreignkey")

    # Drop tables (in reverse order of creation)
    op.drop_table("processed_events")
    op.drop_table("saved_filters")
    op.drop_table("notification_preferences")
    op.drop_table("audit_log")
    op.drop_table("recurring_patterns")

    # Drop new columns from tasks table
    op.drop_column("task", "recurring_pattern_id")
    op.drop_column("task", "remind_at")
    op.drop_column("task", "due_date")
    op.drop_column("task", "tags")
    op.drop_column("task", "priority")
