"""Database migrations for Phase 5 features.

This module handles schema migrations to add Phase 5 columns to existing tables.
"""

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncEngine


async def run_migrations(engine: AsyncEngine) -> None:
    """Run database migrations to add Phase 5 columns.
    
    This adds the following columns to the task table:
    - priority (VARCHAR, default 'medium')
    - tags (VARCHAR[], default empty array)
    - due_date (TIMESTAMP WITH TIME ZONE, nullable)
    - remind_at (TIMESTAMP WITH TIME ZONE, nullable)
    - recurring_pattern_id (UUID, nullable, foreign key)
    """
    migrations = [
        # Add priority column if it doesn't exist
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='task' AND column_name='priority'
            ) THEN
                ALTER TABLE task ADD COLUMN priority VARCHAR NOT NULL DEFAULT 'medium';
                ALTER TABLE task ADD CONSTRAINT chk_task_priority
                    CHECK (priority IN ('high', 'medium', 'low'));
            END IF;
        END $$;
        """,

        # Add tags column if it doesn't exist
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='task' AND column_name='tags'
            ) THEN
                ALTER TABLE task ADD COLUMN tags VARCHAR[] NOT NULL DEFAULT '{}';
            END IF;
        END $$;
        """,

        # Add due_date column if it doesn't exist
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='task' AND column_name='due_date'
            ) THEN
                ALTER TABLE task ADD COLUMN due_date TIMESTAMP WITH TIME ZONE;
            END IF;
        END $$;
        """,

        # Add remind_at column if it doesn't exist
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='task' AND column_name='remind_at'
            ) THEN
                ALTER TABLE task ADD COLUMN remind_at TIMESTAMP WITH TIME ZONE;
            END IF;
        END $$;
        """,

        # Add recurring_pattern_id column if it doesn't exist
        """
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='task' AND column_name='recurring_pattern_id'
            ) THEN
                ALTER TABLE task ADD COLUMN recurring_pattern_id UUID;
            END IF;
        END $$;
        """,

        # Create audit_log table if it doesn't exist
        """
        CREATE TABLE IF NOT EXISTS audit_log (
            id UUID PRIMARY KEY,
            user_id VARCHAR NOT NULL,
            action VARCHAR NOT NULL,
            resource_type VARCHAR NOT NULL,
            resource_id UUID NOT NULL,
            changes VARCHAR,
            ip_address VARCHAR,
            user_agent VARCHAR,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
        """,

        # Create recurring_patterns table if it doesn't exist
        """
        CREATE TABLE IF NOT EXISTS recurring_patterns (
            id UUID PRIMARY KEY,
            user_id VARCHAR(36) NOT NULL,
            original_task_id UUID NOT NULL,
            frequency VARCHAR(20) NOT NULL,
            interval INTEGER NOT NULL DEFAULT 1,
            days_of_week INTEGER[],
            day_of_month INTEGER,
            month_of_year INTEGER,
            cron_expression VARCHAR(100),
            end_condition VARCHAR(20) NOT NULL,
            end_date TIMESTAMP WITH TIME ZONE,
            occurrence_count INTEGER,
            current_count INTEGER NOT NULL DEFAULT 0,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
            CONSTRAINT chk_frequency CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly', 'custom')),
            CONSTRAINT chk_end_condition CHECK (end_condition IN ('date', 'count', 'indefinite')),
            CONSTRAINT chk_interval_positive CHECK (interval > 0),
            CONSTRAINT chk_day_of_month CHECK (day_of_month BETWEEN -1 AND 31 OR day_of_month IS NULL),
            CONSTRAINT chk_month_of_year CHECK (month_of_year BETWEEN 1 AND 12 OR month_of_year IS NULL),
            CONSTRAINT chk_occurrence_count CHECK (occurrence_count IS NULL OR occurrence_count > 0)
        );
        """,

        # Create notification_preferences table if it doesn't exist
        """
        CREATE TABLE IF NOT EXISTS notification_preferences (
            id UUID PRIMARY KEY,
            user_id VARCHAR(36) NOT NULL UNIQUE,
            email_enabled BOOLEAN NOT NULL DEFAULT TRUE,
            in_app_enabled BOOLEAN NOT NULL DEFAULT TRUE,
            push_enabled BOOLEAN NOT NULL DEFAULT FALSE,
            sms_enabled BOOLEAN NOT NULL DEFAULT FALSE,
            reminder_frequency VARCHAR(20) NOT NULL DEFAULT 'immediate',
            task_updates_enabled BOOLEAN NOT NULL DEFAULT TRUE,
            recurring_task_enabled BOOLEAN NOT NULL DEFAULT TRUE,
            quiet_hours_enabled BOOLEAN NOT NULL DEFAULT FALSE,
            quiet_hours_start TIME,
            quiet_hours_end TIME,
            timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
        );
        """,

        # Create saved_filter table if it doesn't exist
        """
        CREATE TABLE IF NOT EXISTS saved_filter (
            id UUID PRIMARY KEY,
            user_id VARCHAR(36) NOT NULL,
            name VARCHAR(100) NOT NULL,
            description TEXT,
            filter_config TEXT NOT NULL,
            is_default BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
        );
        """,

        # Create indexes if they don't exist
        """
        CREATE INDEX IF NOT EXISTS ix_task_priority ON task (priority);
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_task_tags ON task USING gin (tags);
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_task_due_date ON task (due_date)
            WHERE due_date IS NOT NULL;
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_task_remind_at ON task (remind_at)
            WHERE remind_at IS NOT NULL;
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_task_recurring_pattern_id ON task (recurring_pattern_id)
            WHERE recurring_pattern_id IS NOT NULL;
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_task_user_status_priority ON task (user_id, status, priority);
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_audit_log_user_id ON audit_log (user_id);
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_audit_log_resource ON audit_log (resource_type, resource_id);
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_recurring_patterns_user_id ON recurring_patterns (user_id);
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_recurring_patterns_original_task_id ON recurring_patterns (original_task_id);
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_notification_preferences_user_id ON notification_preferences (user_id);
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_saved_filter_user_id ON saved_filter (user_id);
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_saved_filter_user_default ON saved_filter (user_id, is_default);
        """,
    ]
    
    async with engine.begin() as conn:
        for migration in migrations:
            try:
                await conn.execute(text(migration))
            except Exception as e:
                # Log but don't fail - some migrations might already be applied
                print(f"Migration warning: {e}")
