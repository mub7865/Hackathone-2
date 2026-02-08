# Timezone Handling Best Practices

This guide covers best practices for handling timezones in recurring task scheduling.

## The Problem

Timezones are complex:
- Different regions have different UTC offsets
- Daylight Saving Time (DST) changes twice a year
- Some regions don't observe DST
- Historical timezone changes
- User expectations vs. server time

## Core Principles

### 1. Always Store in UTC

**Rule**: Store all timestamps in UTC in the database.

```python
from datetime import datetime
import pytz

# ❌ Wrong: Store in local time
task.created_at = datetime.now()  # Uses system timezone

# ✅ Correct: Store in UTC
task.created_at = datetime.utcnow()  # UTC time
# or
task.created_at = datetime.now(pytz.utc)  # UTC time with timezone info
```

### 2. Convert to User Timezone for Display

**Rule**: Convert to user's timezone only when displaying to the user.

```python
import pytz

# Get user's timezone
user_tz = pytz.timezone('America/New_York')

# Convert UTC to user timezone
utc_time = datetime.utcnow().replace(tzinfo=pytz.utc)
user_time = utc_time.astimezone(user_tz)

print(f"UTC: {utc_time}")
print(f"User time: {user_time}")
```

### 3. Schedule in User Timezone

**Rule**: When scheduling recurring tasks, use the user's timezone.

```python
from apscheduler.triggers.cron import CronTrigger
import pytz

# User wants task at 9 AM in their timezone
user_tz = pytz.timezone('America/New_York')

trigger = CronTrigger(
    hour=9,
    minute=0,
    timezone=user_tz  # Schedule in user's timezone
)
```

## Common Timezone Issues

### Issue 1: Daylight Saving Time (DST)

**Problem**: Tasks scheduled at 2:30 AM during DST transition may not run.

**Solution**: Avoid scheduling tasks during DST transition hours (2-3 AM).

```python
# ❌ Risky: May not run during DST transition
trigger = CronTrigger(hour=2, minute=30, timezone='America/New_York')

# ✅ Safe: Schedule at 3 AM or later
trigger = CronTrigger(hour=3, minute=0, timezone='America/New_York')
```

### Issue 2: Timezone-Naive Datetimes

**Problem**: Mixing timezone-aware and timezone-naive datetimes causes errors.

**Solution**: Always use timezone-aware datetimes.

```python
from datetime import datetime
import pytz

# ❌ Wrong: Timezone-naive
naive_dt = datetime(2024, 1, 1, 9, 0)

# ✅ Correct: Timezone-aware
utc = pytz.utc
aware_dt = utc.localize(datetime(2024, 1, 1, 9, 0))

# Or use timezone directly
aware_dt = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
```

### Issue 3: Incorrect Timezone Conversion

**Problem**: Using `replace()` instead of `astimezone()` for conversion.

```python
import pytz

utc_time = datetime.now(pytz.utc)

# ❌ Wrong: Changes timezone without converting time
wrong = utc_time.replace(tzinfo=pytz.timezone('America/New_York'))

# ✅ Correct: Converts time to new timezone
correct = utc_time.astimezone(pytz.timezone('America/New_York'))
```

## Implementation Patterns

### Pattern 1: Store User Timezone

```python
from sqlmodel import SQLModel, Field
from datetime import datetime

class RecurringTask(SQLModel, table=True):
    id: int = Field(primary_key=True)
    title: str
    user_id: str

    # Store user's timezone
    timezone: str = Field(default="UTC")

    # Store times in UTC
    created_at: datetime = Field(default_factory=datetime.utcnow)
    next_run: datetime  # Always UTC
```

### Pattern 2: Convert for Scheduling

```python
import pytz
from apscheduler.triggers.cron import CronTrigger

def create_trigger(recurring_task):
    """Create trigger in user's timezone."""
    user_tz = pytz.timezone(recurring_task.timezone)

    return CronTrigger(
        hour=recurring_task.hour,
        minute=recurring_task.minute,
        timezone=user_tz
    )
```

### Pattern 3: Display in User Timezone

```python
def format_time_for_user(utc_time: datetime, user_timezone: str) -> str:
    """Format UTC time for user's timezone."""
    user_tz = pytz.timezone(user_timezone)

    # Ensure UTC time is timezone-aware
    if utc_time.tzinfo is None:
        utc_time = pytz.utc.localize(utc_time)

    # Convert to user timezone
    user_time = utc_time.astimezone(user_tz)

    # Format for display
    return user_time.strftime('%Y-%m-%d %I:%M %p %Z')

# Example
utc_time = datetime.utcnow()
print(format_time_for_user(utc_time, 'America/New_York'))
# Output: 2024-01-09 03:45 PM EST
```

### Pattern 4: Calculate Next Occurrence

```python
from datetime import datetime
import pytz

def calculate_next_run(
    last_run: datetime,
    hour: int,
    minute: int,
    user_timezone: str
) -> datetime:
    """Calculate next run time in UTC."""

    # Convert last_run to user timezone
    user_tz = pytz.timezone(user_timezone)
    if last_run.tzinfo is None:
        last_run = pytz.utc.localize(last_run)

    last_run_user = last_run.astimezone(user_tz)

    # Calculate next occurrence in user timezone
    next_run_user = last_run_user.replace(
        hour=hour,
        minute=minute,
        second=0,
        microsecond=0
    )

    # If time already passed today, use tomorrow
    if next_run_user <= last_run_user:
        next_run_user += timedelta(days=1)

    # Convert back to UTC
    next_run_utc = next_run_user.astimezone(pytz.utc)

    return next_run_utc
```

## Testing Timezone Logic

### Test 1: UTC Storage

```python
def test_utc_storage():
    """Test that times are stored in UTC."""
    task = RecurringTask(
        title="Test",
        timezone="America/New_York",
        created_at=datetime.utcnow()
    )

    # Verify stored time is UTC
    assert task.created_at.tzinfo is None or task.created_at.tzinfo == pytz.utc
```

### Test 2: Timezone Conversion

```python
def test_timezone_conversion():
    """Test timezone conversion."""
    utc_time = datetime(2024, 1, 1, 14, 0, tzinfo=pytz.utc)  # 2 PM UTC

    # Convert to New York time
    ny_tz = pytz.timezone('America/New_York')
    ny_time = utc_time.astimezone(ny_tz)

    # Should be 9 AM EST (UTC-5)
    assert ny_time.hour == 9
```

### Test 3: DST Handling

```python
def test_dst_transition():
    """Test DST transition handling."""
    ny_tz = pytz.timezone('America/New_York')

    # Before DST (EST, UTC-5)
    before_dst = ny_tz.localize(datetime(2024, 3, 9, 9, 0))
    utc_before = before_dst.astimezone(pytz.utc)
    assert utc_before.hour == 14  # 9 AM EST = 2 PM UTC

    # After DST (EDT, UTC-4)
    after_dst = ny_tz.localize(datetime(2024, 3, 11, 9, 0))
    utc_after = after_dst.astimezone(pytz.utc)
    assert utc_after.hour == 13  # 9 AM EDT = 1 PM UTC
```

## Common Timezones

### US Timezones
```python
'America/New_York'      # Eastern Time (ET)
'America/Chicago'       # Central Time (CT)
'America/Denver'        # Mountain Time (MT)
'America/Los_Angeles'   # Pacific Time (PT)
'America/Anchorage'     # Alaska Time (AKT)
'Pacific/Honolulu'      # Hawaii Time (HT)
```

### European Timezones
```python
'Europe/London'         # GMT/BST
'Europe/Paris'          # CET/CEST
'Europe/Berlin'         # CET/CEST
'Europe/Moscow'         # MSK
```

### Asian Timezones
```python
'Asia/Tokyo'            # JST
'Asia/Shanghai'         # CST
'Asia/Kolkata'          # IST
'Asia/Dubai'            # GST
```

### Australian Timezones
```python
'Australia/Sydney'      # AEDT/AEST
'Australia/Melbourne'   # AEDT/AEST
'Australia/Perth'       # AWST
```

## FastAPI Integration

### Store User Timezone

```python
from fastapi import FastAPI, Depends
from sqlmodel import Session

@app.post("/recurring-tasks")
async def create_recurring_task(
    task: RecurringTaskCreate,
    user_timezone: str = Header(default="UTC"),
    session: Session = Depends(get_session)
):
    """Create recurring task with user's timezone."""

    # Validate timezone
    try:
        pytz.timezone(user_timezone)
    except pytz.exceptions.UnknownTimeZoneError:
        raise HTTPException(status_code=400, detail="Invalid timezone")

    # Create task with user's timezone
    recurring_task = RecurringTask(
        **task.dict(),
        timezone=user_timezone
    )

    session.add(recurring_task)
    session.commit()

    return recurring_task
```

### Return Times in User Timezone

```python
from pydantic import BaseModel, validator

class RecurringTaskResponse(BaseModel):
    id: int
    title: str
    next_run: datetime
    timezone: str

    @validator('next_run')
    def convert_to_user_timezone(cls, v, values):
        """Convert next_run to user's timezone."""
        if 'timezone' in values:
            user_tz = pytz.timezone(values['timezone'])
            if v.tzinfo is None:
                v = pytz.utc.localize(v)
            return v.astimezone(user_tz)
        return v
```

## Best Practices Summary

1. **Always store in UTC**: Database timestamps should be UTC
2. **Store user timezone**: Keep track of each user's timezone preference
3. **Convert for display**: Convert to user timezone only when displaying
4. **Use timezone-aware datetimes**: Always include timezone information
5. **Validate timezones**: Check that timezone strings are valid
6. **Test DST transitions**: Test your code around DST changes
7. **Use pytz**: Use pytz library for reliable timezone handling
8. **Document timezone assumptions**: Make it clear what timezone is expected
9. **Avoid DST transition hours**: Don't schedule tasks at 2-3 AM
10. **Use ISO 8601 format**: When serializing, use ISO 8601 with timezone

## Tools and Libraries

### Python Libraries
- **pytz**: Timezone definitions and conversions
- **python-dateutil**: Relative date calculations
- **arrow**: Human-friendly dates and times
- **pendulum**: Better datetime library

### Online Tools
- [Time Zone Converter](https://www.timeanddate.com/worldclock/converter.html)
- [Timezone Database](https://www.iana.org/time-zones)
- [DST Dates](https://www.timeanddate.com/time/dst/)

## Resources

- [pytz Documentation](https://pythonhosted.org/pytz/)
- [Python datetime Documentation](https://docs.python.org/3/library/datetime.html)
- [IANA Time Zone Database](https://www.iana.org/time-zones)
- [Falsehoods Programmers Believe About Time](https://gist.github.com/timvisee/fcda9bbdff88d45cc9061606b4b923ca)
