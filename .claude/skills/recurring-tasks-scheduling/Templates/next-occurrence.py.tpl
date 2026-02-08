"""
Next Occurrence Calculation Template

This template provides functions for calculating the next occurrence
of recurring tasks based on various scheduling patterns.
"""

from datetime import datetime, timedelta, time
from dateutil.relativedelta import relativedelta
from croniter import croniter
import pytz
from typing import Optional
from enum import Enum


# ============================================================================
# Enums
# ============================================================================

class RecurrencePattern(str, Enum):
    """Recurrence patterns."""
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"
    CUSTOM = "custom"


class DayOfWeek(int, Enum):
    """Days of the week."""
    MONDAY = 0
    TUESDAY = 1
    WEDNESDAY = 2
    THURSDAY = 3
    FRIDAY = 4
    SATURDAY = 5
    SUNDAY = 6


# ============================================================================
# Next Occurrence Calculation
# ============================================================================

def calculate_next_occurrence(
    last_run: datetime,
    pattern: RecurrencePattern,
    interval: int = 1,
    hour: int = 9,
    minute: int = 0,
    day_of_week: Optional[DayOfWeek] = None,
    day_of_month: Optional[int] = None,
    cron_expression: Optional[str] = None,
    timezone: str = "UTC"
) -> datetime:
    """
    Calculate the next occurrence of a recurring task.

    Args:
        last_run: Last execution time
        pattern: Recurrence pattern
        interval: Interval between occurrences (e.g., every 2 days)
        hour: Hour of day (0-23)
        minute: Minute of hour (0-59)
        day_of_week: Day of week for weekly tasks
        day_of_month: Day of month for monthly tasks
        cron_expression: Cron expression for custom patterns
        timezone: Timezone for calculations

    Returns:
        Next occurrence datetime in UTC
    """

    # Convert to timezone-aware datetime
    tz = pytz.timezone(timezone)
    if last_run.tzinfo is None:
        last_run = pytz.utc.localize(last_run)

    # Convert to user timezone
    last_run_tz = last_run.astimezone(tz)

    if pattern == RecurrencePattern.DAILY:
        next_run = calculate_daily_occurrence(
            last_run_tz, interval, hour, minute
        )

    elif pattern == RecurrencePattern.WEEKLY:
        if day_of_week is None:
            raise ValueError("day_of_week required for weekly pattern")
        next_run = calculate_weekly_occurrence(
            last_run_tz, interval, day_of_week, hour, minute
        )

    elif pattern == RecurrencePattern.MONTHLY:
        if day_of_month is None:
            raise ValueError("day_of_month required for monthly pattern")
        next_run = calculate_monthly_occurrence(
            last_run_tz, interval, day_of_month, hour, minute
        )

    elif pattern == RecurrencePattern.YEARLY:
        next_run = calculate_yearly_occurrence(
            last_run_tz, interval, hour, minute
        )

    elif pattern == RecurrencePattern.CUSTOM:
        if not cron_expression:
            raise ValueError("cron_expression required for custom pattern")
        next_run = calculate_cron_occurrence(
            last_run_tz, cron_expression
        )

    else:
        raise ValueError(f"Unknown pattern: {pattern}")

    # Convert back to UTC
    return next_run.astimezone(pytz.utc)


def calculate_daily_occurrence(
    last_run: datetime,
    interval: int,
    hour: int,
    minute: int
) -> datetime:
    """Calculate next daily occurrence."""

    # Add interval days
    next_run = last_run + timedelta(days=interval)

    # Set time
    next_run = next_run.replace(hour=hour, minute=minute, second=0, microsecond=0)

    return next_run


def calculate_weekly_occurrence(
    last_run: datetime,
    interval: int,
    day_of_week: DayOfWeek,
    hour: int,
    minute: int
) -> datetime:
    """Calculate next weekly occurrence."""

    # Calculate days until target day of week
    current_day = last_run.weekday()
    target_day = day_of_week.value

    days_ahead = target_day - current_day
    if days_ahead <= 0:  # Target day already happened this week
        days_ahead += 7 * interval

    # Add days
    next_run = last_run + timedelta(days=days_ahead)

    # Set time
    next_run = next_run.replace(hour=hour, minute=minute, second=0, microsecond=0)

    return next_run


def calculate_monthly_occurrence(
    last_run: datetime,
    interval: int,
    day_of_month: int,
    hour: int,
    minute: int
) -> datetime:
    """Calculate next monthly occurrence."""

    # Add interval months
    next_run = last_run + relativedelta(months=interval)

    # Set day of month (handle month boundaries)
    try:
        next_run = next_run.replace(
            day=day_of_month,
            hour=hour,
            minute=minute,
            second=0,
            microsecond=0
        )
    except ValueError:
        # Day doesn't exist in this month (e.g., Feb 31)
        # Use last day of month
        next_run = next_run.replace(day=1) + relativedelta(months=1) - timedelta(days=1)
        next_run = next_run.replace(hour=hour, minute=minute, second=0, microsecond=0)

    return next_run


def calculate_yearly_occurrence(
    last_run: datetime,
    interval: int,
    hour: int,
    minute: int
) -> datetime:
    """Calculate next yearly occurrence."""

    # Add interval years
    next_run = last_run + relativedelta(years=interval)

    # Set time
    next_run = next_run.replace(hour=hour, minute=minute, second=0, microsecond=0)

    return next_run


def calculate_cron_occurrence(
    last_run: datetime,
    cron_expression: str
) -> datetime:
    """Calculate next occurrence using cron expression."""

    # Create croniter instance
    cron = croniter(cron_expression, last_run)

    # Get next occurrence
    next_run = cron.get_next(datetime)

    return next_run


# ============================================================================
# First Occurrence Calculation
# ============================================================================

def calculate_first_occurrence(
    start_date: datetime,
    pattern: RecurrencePattern,
    hour: int = 9,
    minute: int = 0,
    day_of_week: Optional[DayOfWeek] = None,
    day_of_month: Optional[int] = None,
    cron_expression: Optional[str] = None,
    timezone: str = "UTC"
) -> datetime:
    """
    Calculate the first occurrence of a recurring task.

    Args:
        start_date: Start date for the recurring task
        pattern: Recurrence pattern
        hour: Hour of day (0-23)
        minute: Minute of hour (0-59)
        day_of_week: Day of week for weekly tasks
        day_of_month: Day of month for monthly tasks
        cron_expression: Cron expression for custom patterns
        timezone: Timezone for calculations

    Returns:
        First occurrence datetime in UTC
    """

    # Convert to timezone-aware datetime
    tz = pytz.timezone(timezone)
    if start_date.tzinfo is None:
        start_date = pytz.utc.localize(start_date)

    # Convert to user timezone
    start_date_tz = start_date.astimezone(tz)

    if pattern == RecurrencePattern.DAILY:
        # First occurrence is start_date at specified time
        first_run = start_date_tz.replace(
            hour=hour,
            minute=minute,
            second=0,
            microsecond=0
        )

        # If time already passed today, use tomorrow
        if first_run <= start_date_tz:
            first_run += timedelta(days=1)

    elif pattern == RecurrencePattern.WEEKLY:
        if day_of_week is None:
            raise ValueError("day_of_week required for weekly pattern")

        # Find next occurrence of target day
        current_day = start_date_tz.weekday()
        target_day = day_of_week.value

        days_ahead = target_day - current_day
        if days_ahead < 0:
            days_ahead += 7

        first_run = start_date_tz + timedelta(days=days_ahead)
        first_run = first_run.replace(
            hour=hour,
            minute=minute,
            second=0,
            microsecond=0
        )

    elif pattern == RecurrencePattern.MONTHLY:
        if day_of_month is None:
            raise ValueError("day_of_month required for monthly pattern")

        # Set to target day of current month
        try:
            first_run = start_date_tz.replace(
                day=day_of_month,
                hour=hour,
                minute=minute,
                second=0,
                microsecond=0
            )
        except ValueError:
            # Day doesn't exist in this month
            # Use last day of month
            first_run = start_date_tz.replace(day=1) + relativedelta(months=1) - timedelta(days=1)
            first_run = first_run.replace(hour=hour, minute=minute, second=0, microsecond=0)

        # If already passed this month, use next month
        if first_run <= start_date_tz:
            first_run += relativedelta(months=1)

    elif pattern == RecurrencePattern.YEARLY:
        # First occurrence is start_date at specified time
        first_run = start_date_tz.replace(
            hour=hour,
            minute=minute,
            second=0,
            microsecond=0
        )

        # If already passed this year, use next year
        if first_run <= start_date_tz:
            first_run += relativedelta(years=1)

    elif pattern == RecurrencePattern.CUSTOM:
        if not cron_expression:
            raise ValueError("cron_expression required for custom pattern")

        # Use croniter to find first occurrence
        cron = croniter(cron_expression, start_date_tz)
        first_run = cron.get_next(datetime)

    else:
        raise ValueError(f"Unknown pattern: {pattern}")

    # Convert back to UTC
    return first_run.astimezone(pytz.utc)


# ============================================================================
# Missed Occurrences Calculation
# ============================================================================

def calculate_missed_occurrences(
    last_run: datetime,
    next_run: datetime,
    pattern: RecurrencePattern,
    interval: int = 1,
    hour: int = 9,
    minute: int = 0,
    day_of_week: Optional[DayOfWeek] = None,
    day_of_month: Optional[int] = None,
    cron_expression: Optional[str] = None,
    timezone: str = "UTC"
) -> list[datetime]:
    """
    Calculate all missed occurrences between last_run and now.

    Args:
        last_run: Last execution time
        next_run: Next scheduled execution time
        pattern: Recurrence pattern
        interval: Interval between occurrences
        hour: Hour of day
        minute: Minute of hour
        day_of_week: Day of week for weekly tasks
        day_of_month: Day of month for monthly tasks
        cron_expression: Cron expression for custom patterns
        timezone: Timezone for calculations

    Returns:
        List of missed occurrence datetimes in UTC
    """

    now = datetime.now(pytz.utc)
    missed = []

    # If next_run is in the future, no missed occurrences
    if next_run > now:
        return missed

    # Calculate all occurrences between last_run and now
    current = last_run
    while True:
        current = calculate_next_occurrence(
            current,
            pattern,
            interval,
            hour,
            minute,
            day_of_week,
            day_of_month,
            cron_expression,
            timezone
        )

        if current > now:
            break

        missed.append(current)

    return missed


# ============================================================================
# Validation
# ============================================================================

def validate_schedule_configuration(
    pattern: RecurrencePattern,
    hour: int,
    minute: int,
    day_of_week: Optional[DayOfWeek] = None,
    day_of_month: Optional[int] = None,
    cron_expression: Optional[str] = None
) -> None:
    """Validate schedule configuration."""

    # Validate time
    if not (0 <= hour <= 23):
        raise ValueError(f"Invalid hour: {hour}. Must be 0-23")

    if not (0 <= minute <= 59):
        raise ValueError(f"Invalid minute: {minute}. Must be 0-59")

    # Validate pattern-specific fields
    if pattern == RecurrencePattern.WEEKLY:
        if day_of_week is None:
            raise ValueError("day_of_week required for weekly pattern")

    elif pattern == RecurrencePattern.MONTHLY:
        if day_of_month is None:
            raise ValueError("day_of_month required for monthly pattern")
        if not (1 <= day_of_month <= 31):
            raise ValueError(f"Invalid day_of_month: {day_of_month}. Must be 1-31")

    elif pattern == RecurrencePattern.CUSTOM:
        if not cron_expression:
            raise ValueError("cron_expression required for custom pattern")
        if not croniter.is_valid(cron_expression):
            raise ValueError(f"Invalid cron expression: {cron_expression}")


# ============================================================================
# Usage Example
# ============================================================================

if __name__ == "__main__":
    # Daily task
    last_run = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
    next_run = calculate_next_occurrence(
        last_run,
        RecurrencePattern.DAILY,
        interval=1,
        hour=9,
        minute=0,
        timezone="America/New_York"
    )
    print(f"Daily next run: {next_run}")

    # Weekly task (every Monday)
    next_run = calculate_next_occurrence(
        last_run,
        RecurrencePattern.WEEKLY,
        interval=1,
        hour=9,
        minute=0,
        day_of_week=DayOfWeek.MONDAY,
        timezone="America/New_York"
    )
    print(f"Weekly next run: {next_run}")

    # Monthly task (1st of month)
    next_run = calculate_next_occurrence(
        last_run,
        RecurrencePattern.MONTHLY,
        interval=1,
        hour=9,
        minute=0,
        day_of_month=1,
        timezone="America/New_York"
    )
    print(f"Monthly next run: {next_run}")

    # Custom cron (every 15 minutes)
    next_run = calculate_next_occurrence(
        last_run,
        RecurrencePattern.CUSTOM,
        cron_expression="*/15 * * * *",
        timezone="UTC"
    )
    print(f"Custom next run: {next_run}")

    # Calculate first occurrence
    start_date = datetime(2024, 1, 1, 0, 0, tzinfo=pytz.utc)
    first_run = calculate_first_occurrence(
        start_date,
        RecurrencePattern.DAILY,
        hour=9,
        minute=0,
        timezone="America/New_York"
    )
    print(f"First occurrence: {first_run}")

    # Calculate missed occurrences
    last_run = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
    next_run = datetime(2024, 1, 2, 9, 0, tzinfo=pytz.utc)
    missed = calculate_missed_occurrences(
        last_run,
        next_run,
        RecurrencePattern.DAILY,
        interval=1,
        hour=9,
        minute=0,
        timezone="America/New_York"
    )
    print(f"Missed occurrences: {missed}")
