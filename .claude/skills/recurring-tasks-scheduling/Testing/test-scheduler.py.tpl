"""
Unit Tests for Scheduler

This template provides test patterns for APScheduler integration.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timedelta
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
import pytz


class TestSchedulerConfiguration:
    """Test suite for scheduler configuration."""

    def test_create_background_scheduler(self):
        """Test creating background scheduler."""
        from apscheduler_setup import create_background_scheduler

        scheduler = create_background_scheduler(
            database_url="sqlite:///:memory:",
            max_workers=5,
            timezone="UTC"
        )

        assert scheduler is not None
        assert isinstance(scheduler, BackgroundScheduler)
        assert scheduler.timezone.zone == "UTC"

    def test_scheduler_job_defaults(self):
        """Test scheduler job defaults."""
        from apscheduler_setup import create_background_scheduler

        scheduler = create_background_scheduler()

        defaults = scheduler._job_defaults
        assert defaults['coalesce'] is True
        assert defaults['max_instances'] == 1
        assert defaults['misfire_grace_time'] == 300

    def test_scheduler_has_jobstores(self):
        """Test scheduler has configured jobstores."""
        from apscheduler_setup import create_background_scheduler

        scheduler = create_background_scheduler()

        assert 'default' in scheduler._jobstores
        assert 'memory' in scheduler._jobstores


class TestSchedulerLifecycle:
    """Test suite for scheduler lifecycle."""

    @pytest.fixture
    def scheduler(self):
        """Create test scheduler."""
        from apscheduler_setup import create_background_scheduler
        return create_background_scheduler(database_url="sqlite:///:memory:")

    def test_scheduler_start_stop(self, scheduler):
        """Test starting and stopping scheduler."""
        assert not scheduler.running

        scheduler.start()
        assert scheduler.running

        scheduler.shutdown(wait=False)
        assert not scheduler.running

    def test_scheduler_add_job(self, scheduler):
        """Test adding job to scheduler."""
        def test_job():
            pass

        scheduler.add_job(
            test_job,
            'interval',
            seconds=60,
            id='test_job'
        )

        job = scheduler.get_job('test_job')
        assert job is not None
        assert job.id == 'test_job'

    def test_scheduler_remove_job(self, scheduler):
        """Test removing job from scheduler."""
        def test_job():
            pass

        scheduler.add_job(test_job, 'interval', seconds=60, id='test_job')
        scheduler.remove_job('test_job')

        job = scheduler.get_job('test_job')
        assert job is None

    def test_scheduler_pause_resume_job(self, scheduler):
        """Test pausing and resuming job."""
        def test_job():
            pass

        scheduler.add_job(test_job, 'interval', seconds=60, id='test_job')

        # Pause
        scheduler.pause_job('test_job')
        job = scheduler.get_job('test_job')
        assert job.next_run_time is None

        # Resume
        scheduler.resume_job('test_job')
        job = scheduler.get_job('test_job')
        assert job.next_run_time is not None


class TestCronTriggers:
    """Test suite for cron triggers."""

    def test_daily_trigger(self):
        """Test daily cron trigger."""
        trigger = CronTrigger(hour=9, minute=0, timezone='UTC')

        # Get next run time
        now = datetime(2024, 1, 1, 8, 0, tzinfo=pytz.utc)
        next_run = trigger.get_next_fire_time(None, now)

        # Should be 9 AM today
        assert next_run.hour == 9
        assert next_run.minute == 0
        assert next_run.day == 1

    def test_weekly_trigger(self):
        """Test weekly cron trigger."""
        # Every Monday at 9 AM
        trigger = CronTrigger(
            day_of_week=0,  # Monday
            hour=9,
            minute=0,
            timezone='UTC'
        )

        # Monday, Jan 1, 2024 at 8 AM
        now = datetime(2024, 1, 1, 8, 0, tzinfo=pytz.utc)
        next_run = trigger.get_next_fire_time(None, now)

        # Should be 9 AM today (Monday)
        assert next_run.hour == 9
        assert next_run.weekday() == 0  # Monday

    def test_monthly_trigger(self):
        """Test monthly cron trigger."""
        # 1st of every month at 9 AM
        trigger = CronTrigger(
            day=1,
            hour=9,
            minute=0,
            timezone='UTC'
        )

        now = datetime(2024, 1, 15, 8, 0, tzinfo=pytz.utc)
        next_run = trigger.get_next_fire_time(None, now)

        # Should be Feb 1
        assert next_run.day == 1
        assert next_run.month == 2

    def test_cron_from_expression(self):
        """Test creating trigger from cron expression."""
        # Every weekday at 9 AM
        trigger = CronTrigger.from_crontab("0 9 * * 1-5", timezone='UTC')

        # Tuesday, Jan 2, 2024 at 8 AM
        now = datetime(2024, 1, 2, 8, 0, tzinfo=pytz.utc)
        next_run = trigger.get_next_fire_time(None, now)

        # Should be 9 AM today (Tuesday)
        assert next_run.hour == 9
        assert next_run.weekday() == 1  # Tuesday


class TestJobExecution:
    """Test suite for job execution."""

    @pytest.fixture
    def scheduler(self):
        """Create test scheduler."""
        from apscheduler_setup import create_background_scheduler
        scheduler = create_background_scheduler(database_url="sqlite:///:memory:")
        scheduler.start()
        yield scheduler
        scheduler.shutdown(wait=False)

    def test_job_executes(self, scheduler):
        """Test that job executes."""
        executed = []

        def test_job():
            executed.append(True)

        # Add job that runs immediately
        scheduler.add_job(
            test_job,
            'date',
            run_date=datetime.now() + timedelta(seconds=1)
        )

        # Wait for execution
        import time
        time.sleep(2)

        assert len(executed) == 1

    def test_job_executes_with_args(self, scheduler):
        """Test job execution with arguments."""
        results = []

        def test_job(value):
            results.append(value)

        scheduler.add_job(
            test_job,
            'date',
            run_date=datetime.now() + timedelta(seconds=1),
            args=['test_value']
        )

        import time
        time.sleep(2)

        assert results == ['test_value']

    def test_job_error_handling(self, scheduler):
        """Test job error handling."""
        errors = []

        def failing_job():
            raise Exception("Test error")

        def error_listener(event):
            errors.append(event.exception)

        scheduler.add_listener(
            error_listener,
            EVENT_JOB_ERROR
        )

        scheduler.add_job(
            failing_job,
            'date',
            run_date=datetime.now() + timedelta(seconds=1)
        )

        import time
        time.sleep(2)

        assert len(errors) == 1


class TestSchedulerService:
    """Test suite for SchedulerService."""

    @pytest.fixture
    def mock_scheduler(self):
        """Mock scheduler."""
        scheduler = Mock()
        scheduler.running = False
        return scheduler

    @pytest.fixture
    def mock_session(self):
        """Mock database session."""
        return Mock()

    @pytest.fixture
    def scheduler_service(self, mock_scheduler, mock_session):
        """Create scheduler service."""
        from scheduler_service import SchedulerService

        def session_factory():
            return mock_session

        return SchedulerService(
            scheduler=mock_scheduler,
            session_factory=session_factory,
            timezone="UTC"
        )

    def test_schedule_all_active_tasks(self, scheduler_service, mock_session):
        """Test scheduling all active tasks."""
        from recurring_task_model import RecurringTask, RecurrencePattern

        # Mock active tasks
        tasks = [
            RecurringTask(
                id=1,
                title="Task 1",
                user_id="user_123",
                pattern=RecurrencePattern.DAILY,
                hour=9,
                minute=0,
                start_date=datetime(2024, 1, 1, 9, 0),
                next_run=datetime(2024, 1, 1, 9, 0),
                is_active=True,
                timezone="UTC"
            ),
            RecurringTask(
                id=2,
                title="Task 2",
                user_id="user_123",
                pattern=RecurrencePattern.WEEKLY,
                day_of_week=0,
                hour=9,
                minute=0,
                start_date=datetime(2024, 1, 1, 9, 0),
                next_run=datetime(2024, 1, 1, 9, 0),
                is_active=True,
                timezone="UTC"
            )
        ]

        mock_session.__enter__ = Mock(return_value=mock_session)
        mock_session.__exit__ = Mock(return_value=None)
        mock_session.exec = Mock(return_value=Mock(all=Mock(return_value=tasks)))

        count = scheduler_service.schedule_all_active_tasks()

        assert count == 2

    def test_get_scheduled_jobs(self, scheduler_service, mock_scheduler):
        """Test getting scheduled jobs."""
        mock_job = Mock()
        mock_job.id = 'recurring_1'
        mock_job.name = 'Test Task'
        mock_job.next_run_time = datetime(2024, 1, 1, 9, 0)
        mock_job.trigger = 'cron'

        mock_scheduler.get_jobs.return_value = [mock_job]

        jobs = scheduler_service.get_scheduled_jobs()

        assert len(jobs) == 1
        assert jobs[0]['id'] == 'recurring_1'
        assert jobs[0]['name'] == 'Test Task'


class TestMisfireHandling:
    """Test suite for misfire handling."""

    @pytest.fixture
    def scheduler(self):
        """Create test scheduler."""
        from apscheduler_setup import create_background_scheduler
        return create_background_scheduler(database_url="sqlite:///:memory:")

    def test_coalesce_missed_executions(self, scheduler):
        """Test that missed executions are coalesced."""
        executed = []

        def test_job():
            executed.append(datetime.now())

        # Add job with past run time
        past_time = datetime.now() - timedelta(hours=2)
        scheduler.add_job(
            test_job,
            'interval',
            hours=1,
            start_date=past_time,
            coalesce=True  # Combine missed executions
        )

        scheduler.start()
        import time
        time.sleep(2)
        scheduler.shutdown(wait=False)

        # Should only execute once (coalesced)
        assert len(executed) == 1

    def test_misfire_grace_time(self, scheduler):
        """Test misfire grace time."""
        executed = []

        def test_job():
            executed.append(datetime.now())

        # Add job with past run time beyond grace period
        past_time = datetime.now() - timedelta(minutes=10)
        scheduler.add_job(
            test_job,
            'date',
            run_date=past_time,
            misfire_grace_time=300  # 5 minutes
        )

        scheduler.start()
        import time
        time.sleep(2)
        scheduler.shutdown(wait=False)

        # Should not execute (beyond grace period)
        assert len(executed) == 0


# Integration tests
@pytest.mark.integration
class TestSchedulerIntegration:
    """Integration tests with real scheduler."""

    @pytest.mark.skipif(
        not pytest.config.getoption("--run-integration"),
        reason="Integration tests disabled"
    )
    def test_full_scheduling_workflow(self):
        """Test complete scheduling workflow."""
        from apscheduler_setup import create_background_scheduler
        from scheduler_service import SchedulerService
        from sqlmodel import create_engine, Session, SQLModel
        from recurring_task_model import RecurringTask, Task, RecurrencePattern

        # Create database
        engine = create_engine("sqlite:///:memory:")
        SQLModel.metadata.create_all(engine)

        # Create scheduler
        scheduler = create_background_scheduler(database_url="sqlite:///:memory:")

        # Create scheduler service
        def session_factory():
            return Session(engine)

        scheduler_service = SchedulerService(
            scheduler=scheduler,
            session_factory=session_factory,
            timezone="UTC"
        )

        # Create recurring task
        with Session(engine) as session:
            task = RecurringTask(
                title="Test Task",
                user_id="user_123",
                pattern=RecurrencePattern.DAILY,
                hour=9,
                minute=0,
                start_date=datetime(2024, 1, 1, 9, 0),
                next_run=datetime.now() + timedelta(seconds=2),
                is_active=True,
                timezone="UTC"
            )
            session.add(task)
            session.commit()
            session.refresh(task)

            # Schedule task
            scheduler_service.schedule_recurring_task(task)

        # Start scheduler
        scheduler.start()

        # Wait for execution
        import time
        time.sleep(3)

        # Check that task instance was created
        with Session(engine) as session:
            from sqlmodel import select
            instances = session.exec(select(Task)).all()
            assert len(instances) > 0

        # Cleanup
        scheduler.shutdown(wait=False)


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
