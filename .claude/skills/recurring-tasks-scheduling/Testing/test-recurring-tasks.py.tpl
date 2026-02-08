"""
Unit Tests for Recurring Tasks

This template provides comprehensive test patterns for recurring task functionality.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timedelta
import pytz


class TestRecurringTaskModel:
    """Test suite for RecurringTask model."""

    def test_create_daily_recurring_task(self):
        """Test creating a daily recurring task."""
        from recurring_task_model import RecurringTask, RecurrencePattern

        task = RecurringTask(
            title="Daily standup",
            user_id="user_123",
            pattern=RecurrencePattern.DAILY,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            next_run=datetime(2024, 1, 1, 9, 0),
            timezone="America/New_York"
        )

        assert task.title == "Daily standup"
        assert task.pattern == RecurrencePattern.DAILY
        assert task.hour == 9
        assert task.minute == 0

    def test_create_weekly_recurring_task(self):
        """Test creating a weekly recurring task."""
        from recurring_task_model import RecurringTask, RecurrencePattern, DayOfWeek

        task = RecurringTask(
            title="Weekly report",
            user_id="user_123",
            pattern=RecurrencePattern.WEEKLY,
            day_of_week=DayOfWeek.FRIDAY,
            hour=17,
            minute=0,
            start_date=datetime(2024, 1, 5, 17, 0),
            next_run=datetime(2024, 1, 5, 17, 0),
            timezone="America/New_York"
        )

        assert task.pattern == RecurrencePattern.WEEKLY
        assert task.day_of_week == DayOfWeek.FRIDAY

    def test_create_monthly_recurring_task(self):
        """Test creating a monthly recurring task."""
        from recurring_task_model import RecurringTask, RecurrencePattern

        task = RecurringTask(
            title="Monthly review",
            user_id="user_123",
            pattern=RecurrencePattern.MONTHLY,
            day_of_month=1,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            next_run=datetime(2024, 1, 1, 9, 0),
            timezone="America/New_York"
        )

        assert task.pattern == RecurrencePattern.MONTHLY
        assert task.day_of_month == 1

    def test_validate_recurring_task(self):
        """Test recurring task validation."""
        from recurring_task_model import RecurringTaskCreate, RecurrencePattern, validate_recurring_task

        # Valid daily task
        task = RecurringTaskCreate(
            title="Test",
            user_id="user_123",
            pattern=RecurrencePattern.DAILY,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            next_run=datetime(2024, 1, 1, 9, 0)
        )
        validate_recurring_task(task)  # Should not raise

    def test_validate_custom_pattern_requires_cron(self):
        """Test that custom pattern requires cron expression."""
        from recurring_task_model import RecurringTaskCreate, RecurrencePattern, validate_recurring_task

        task = RecurringTaskCreate(
            title="Test",
            user_id="user_123",
            pattern=RecurrencePattern.CUSTOM,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            next_run=datetime(2024, 1, 1, 9, 0)
        )

        with pytest.raises(ValueError, match="cron_expression required"):
            validate_recurring_task(task)

    def test_should_stop_recurring_task_end_date(self):
        """Test stopping task when end date reached."""
        from recurring_task_model import RecurringTask, RecurrencePattern, should_stop_recurring_task

        task = RecurringTask(
            title="Test",
            user_id="user_123",
            pattern=RecurrencePattern.DAILY,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            end_date=datetime(2024, 1, 31, 9, 0),
            next_run=datetime(2024, 2, 1, 9, 0),
            timezone="UTC"
        )

        assert should_stop_recurring_task(task) is True

    def test_should_stop_recurring_task_max_occurrences(self):
        """Test stopping task when max occurrences reached."""
        from recurring_task_model import RecurringTask, RecurrencePattern, should_stop_recurring_task

        task = RecurringTask(
            title="Test",
            user_id="user_123",
            pattern=RecurrencePattern.DAILY,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            next_run=datetime(2024, 1, 11, 9, 0),
            max_occurrences=10,
            occurrence_count=10,
            timezone="UTC"
        )

        assert should_stop_recurring_task(task) is True


class TestNextOccurrenceCalculation:
    """Test suite for next occurrence calculation."""

    def test_calculate_daily_occurrence(self):
        """Test calculating next daily occurrence."""
        from next_occurrence import calculate_next_occurrence, RecurrencePattern

        last_run = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
        next_run = calculate_next_occurrence(
            last_run=last_run,
            pattern=RecurrencePattern.DAILY,
            interval=1,
            hour=9,
            minute=0,
            timezone="UTC"
        )

        expected = datetime(2024, 1, 2, 9, 0, tzinfo=pytz.utc)
        assert next_run == expected

    def test_calculate_weekly_occurrence(self):
        """Test calculating next weekly occurrence."""
        from next_occurrence import calculate_next_occurrence, RecurrencePattern, DayOfWeek

        # Monday, Jan 1, 2024
        last_run = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
        next_run = calculate_next_occurrence(
            last_run=last_run,
            pattern=RecurrencePattern.WEEKLY,
            interval=1,
            hour=9,
            minute=0,
            day_of_week=DayOfWeek.MONDAY,
            timezone="UTC"
        )

        # Next Monday
        expected = datetime(2024, 1, 8, 9, 0, tzinfo=pytz.utc)
        assert next_run == expected

    def test_calculate_monthly_occurrence(self):
        """Test calculating next monthly occurrence."""
        from next_occurrence import calculate_next_occurrence, RecurrencePattern

        last_run = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
        next_run = calculate_next_occurrence(
            last_run=last_run,
            pattern=RecurrencePattern.MONTHLY,
            interval=1,
            hour=9,
            minute=0,
            day_of_month=1,
            timezone="UTC"
        )

        expected = datetime(2024, 2, 1, 9, 0, tzinfo=pytz.utc)
        assert next_run == expected

    def test_calculate_monthly_occurrence_invalid_day(self):
        """Test monthly occurrence with invalid day (e.g., Feb 31)."""
        from next_occurrence import calculate_next_occurrence, RecurrencePattern

        # Jan 31
        last_run = datetime(2024, 1, 31, 9, 0, tzinfo=pytz.utc)
        next_run = calculate_next_occurrence(
            last_run=last_run,
            pattern=RecurrencePattern.MONTHLY,
            interval=1,
            hour=9,
            minute=0,
            day_of_month=31,
            timezone="UTC"
        )

        # Should use last day of February (29 in 2024, leap year)
        assert next_run.day == 29
        assert next_run.month == 2

    def test_calculate_cron_occurrence(self):
        """Test calculating occurrence from cron expression."""
        from next_occurrence import calculate_next_occurrence, RecurrencePattern

        last_run = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
        next_run = calculate_next_occurrence(
            last_run=last_run,
            pattern=RecurrencePattern.CUSTOM,
            cron_expression="0 9 * * 1-5",  # Weekdays at 9 AM
            timezone="UTC"
        )

        # Next weekday at 9 AM (Jan 2 is Tuesday)
        expected = datetime(2024, 1, 2, 9, 0, tzinfo=pytz.utc)
        assert next_run == expected

    def test_calculate_first_occurrence(self):
        """Test calculating first occurrence."""
        from next_occurrence import calculate_first_occurrence, RecurrencePattern

        start_date = datetime(2024, 1, 1, 0, 0, tzinfo=pytz.utc)
        first_run = calculate_first_occurrence(
            start_date=start_date,
            pattern=RecurrencePattern.DAILY,
            hour=9,
            minute=0,
            timezone="UTC"
        )

        expected = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
        assert first_run == expected

    def test_calculate_missed_occurrences(self):
        """Test calculating missed occurrences."""
        from next_occurrence import calculate_missed_occurrences, RecurrencePattern

        # Last run was 5 days ago
        last_run = datetime.now(pytz.utc) - timedelta(days=5)
        next_run = datetime.now(pytz.utc) - timedelta(days=4)

        missed = calculate_missed_occurrences(
            last_run=last_run,
            next_run=next_run,
            pattern=RecurrencePattern.DAILY,
            interval=1,
            hour=9,
            minute=0,
            timezone="UTC"
        )

        # Should have 4 missed occurrences
        assert len(missed) == 4

    def test_timezone_conversion(self):
        """Test timezone conversion in calculations."""
        from next_occurrence import calculate_next_occurrence, RecurrencePattern

        # 9 AM EST = 2 PM UTC
        last_run = datetime(2024, 1, 1, 14, 0, tzinfo=pytz.utc)
        next_run = calculate_next_occurrence(
            last_run=last_run,
            pattern=RecurrencePattern.DAILY,
            interval=1,
            hour=9,
            minute=0,
            timezone="America/New_York"
        )

        # Next day at 9 AM EST = 2 PM UTC
        expected = datetime(2024, 1, 2, 14, 0, tzinfo=pytz.utc)
        assert next_run == expected


class TestSchedulerService:
    """Test suite for SchedulerService."""

    @pytest.fixture
    def mock_scheduler(self):
        """Mock APScheduler."""
        return Mock()

    @pytest.fixture
    def mock_session_factory(self):
        """Mock session factory."""
        return Mock()

    @pytest.fixture
    def scheduler_service(self, mock_scheduler, mock_session_factory):
        """Create SchedulerService instance."""
        from scheduler_service import SchedulerService
        return SchedulerService(
            scheduler=mock_scheduler,
            session_factory=mock_session_factory,
            timezone="UTC"
        )

    def test_schedule_recurring_task(self, scheduler_service, mock_scheduler):
        """Test scheduling a recurring task."""
        from recurring_task_model import RecurringTask, RecurrencePattern

        task = RecurringTask(
            id=1,
            title="Test",
            user_id="user_123",
            pattern=RecurrencePattern.DAILY,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            next_run=datetime(2024, 1, 1, 9, 0),
            timezone="UTC"
        )

        scheduler_service.schedule_recurring_task(task)

        # Verify job was added
        mock_scheduler.add_job.assert_called_once()
        call_args = mock_scheduler.add_job.call_args
        assert call_args[1]['id'] == 'recurring_1'

    def test_unschedule_recurring_task(self, scheduler_service, mock_scheduler):
        """Test unscheduling a recurring task."""
        scheduler_service.unschedule_recurring_task(1)

        mock_scheduler.remove_job.assert_called_once_with('recurring_1')

    def test_create_task_instance(self, scheduler_service, mock_session_factory):
        """Test creating task instance."""
        from recurring_task_model import RecurringTask, Task, RecurrencePattern

        # Mock session and recurring task
        mock_session = Mock()
        mock_session_factory.return_value.__enter__.return_value = mock_session

        recurring_task = RecurringTask(
            id=1,
            title="Test",
            user_id="user_123",
            pattern=RecurrencePattern.DAILY,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            next_run=datetime(2024, 1, 1, 9, 0),
            is_active=True,
            timezone="UTC"
        )

        mock_session.get.return_value = recurring_task

        # Create task instance
        scheduler_service._create_task_instance(1)

        # Verify task was created
        mock_session.add.assert_called_once()
        mock_session.commit.assert_called_once()


# Integration tests (require database)
@pytest.mark.integration
class TestRecurringTasksIntegration:
    """Integration tests with real database."""

    @pytest.fixture
    def engine(self):
        """Create test database engine."""
        from sqlmodel import create_engine
        return create_engine("sqlite:///:memory:")

    @pytest.fixture
    def session(self, engine):
        """Create test database session."""
        from sqlmodel import Session, SQLModel
        SQLModel.metadata.create_all(engine)
        with Session(engine) as session:
            yield session

    def test_create_and_retrieve_recurring_task(self, session):
        """Test creating and retrieving recurring task."""
        from recurring_task_model import RecurringTask, RecurrencePattern

        task = RecurringTask(
            title="Test",
            user_id="user_123",
            pattern=RecurrencePattern.DAILY,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            next_run=datetime(2024, 1, 1, 9, 0),
            timezone="UTC"
        )

        session.add(task)
        session.commit()
        session.refresh(task)

        # Retrieve
        retrieved = session.get(RecurringTask, task.id)
        assert retrieved.title == "Test"
        assert retrieved.pattern == RecurrencePattern.DAILY

    def test_create_task_instance_from_recurring(self, session):
        """Test creating task instance from recurring task."""
        from recurring_task_model import RecurringTask, Task, RecurrencePattern

        # Create recurring task
        recurring_task = RecurringTask(
            title="Daily Task",
            user_id="user_123",
            pattern=RecurrencePattern.DAILY,
            hour=9,
            minute=0,
            start_date=datetime(2024, 1, 1, 9, 0),
            next_run=datetime(2024, 1, 1, 9, 0),
            timezone="UTC"
        )

        session.add(recurring_task)
        session.commit()
        session.refresh(recurring_task)

        # Create task instance
        task = Task(
            title=recurring_task.title,
            user_id=recurring_task.user_id,
            is_recurring=True,
            recurring_task_id=recurring_task.id
        )

        session.add(task)
        session.commit()

        # Verify relationship
        assert task.recurring_task == recurring_task
        assert recurring_task.task_instances[0] == task


# Pytest configuration
def pytest_addoption(parser):
    """Add custom pytest options."""
    parser.addoption(
        "--run-integration",
        action="store_true",
        default=False,
        help="Run integration tests"
    )


# Run tests
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
