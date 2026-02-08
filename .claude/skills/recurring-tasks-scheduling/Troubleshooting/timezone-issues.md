# Troubleshooting Timezone Issues

This guide covers common timezone-related issues in recurring task scheduling and their solutions.

## Table of Contents

1. [Tasks Running at Wrong Time](#tasks-running-at-wrong-time)
2. [Daylight Saving Time Issues](#daylight-saving-time-issues)
3. [Timezone-Naive vs Timezone-Aware](#timezone-naive-vs-timezone-aware)
4. [Invalid Timezone Errors](#invalid-timezone-errors)
5. [Conversion Errors](#conversion-errors)
6. [Display Issues](#display-issues)
7. [Database Timezone Issues](#database-timezone-issues)
8. [Testing Timezone Logic](#testing-timezone-logic)

---

## Tasks Running at Wrong Time

### Symptom
Tasks execute at unexpected times, hours off from expected schedule.

### Diagnosis

1. **Check task timezone:**
```python
print(f"Task timezone: {recurring_task.timezone}")
print(f"Next run (UTC): {recurring_task.next_run}")
```

2. **Check scheduler timezone:**
```python
print(f"Scheduler timezone: {scheduler.timezone}")
```

3. **Check system timezone:**
```python
import time
print(f"System timezone: {time.tzname}")
```

4. **Compare UTC and local time:**
```python
from datetime import datetime
import pytz

utc_now = datetime.now(pytz.utc)
local_now = datetime.now()

print(f"UTC time: {utc_now}")
print(f"Local time: {local_now}")
print(f"Difference: {(local_now - utc_now.replace(tzinfo=None)).total_seconds() / 3600} hours")
```

### Common Causes and Solutions

#### Cause 1: Mixing UTC and Local Time
**Problem:** Storing local time instead of UTC

```python
# ❌ Wrong: Storing local time
task.next_run = datetime.now()  # Uses system timezone

# ✅ Correct: Store UTC
task.next_run = datetime.utcnow()
# or
task.next_run = datetime.now(pytz.utc)
```

#### Cause 2: Wrong Timezone in Trigger
**Problem:** Trigger using wrong timezone

```python
# ❌ Wrong: Using UTC when user expects EST
trigger = CronTrigger(hour=9, minute=0, timezone='UTC')

# ✅ Correct: Use user's timezone
user_tz = pytz.timezone(recurring_task.timezone)
trigger = CronTrigger(hour=9, minute=0, timezone=user_tz)
```

#### Cause 3: Server Timezone Mismatch
**Problem:** Server in different timezone than expected

**Solution:** Always use UTC on server, convert for display
```python
# Server: Store in UTC
task.created_at = datetime.utcnow()

# Client: Convert to user timezone
def format_for_user(utc_time: datetime, user_timezone: str) -> str:
    user_tz = pytz.timezone(user_timezone)
    if utc_time.tzinfo is None:
        utc_time = pytz.utc.localize(utc_time)
    user_time = utc_time.astimezone(user_tz)
    return user_time.strftime('%Y-%m-%d %I:%M %p %Z')
```

---

## Daylight Saving Time Issues

### Symptom
Tasks don't run during DST transitions or run at wrong time after DST change.

### Diagnosis

1. **Check if timezone observes DST:**
```python
import pytz
from datetime import datetime

tz = pytz.timezone('America/New_York')

# Check DST transition dates
transitions = tz._utc_transition_times
print(f"Recent DST transitions: {transitions[-5:]}")
```

2. **Test around DST transition:**
```python
# Spring forward (2 AM -> 3 AM)
before_dst = tz.localize(datetime(2024, 3, 10, 1, 30))
print(f"Before DST: {before_dst} (UTC: {before_dst.astimezone(pytz.utc)})")

# This time doesn't exist!
try:
    during_dst = tz.localize(datetime(2024, 3, 10, 2, 30))
except pytz.exceptions.NonExistentTimeError as e:
    print(f"Time doesn't exist: {e}")

after_dst = tz.localize(datetime(2024, 3, 10, 3, 30))
print(f"After DST: {after_dst} (UTC: {after_dst.astimezone(pytz.utc)})")
```

### Solutions

#### Solution 1: Avoid DST Transition Hours
**Best Practice:** Don't schedule tasks between 2-3 AM

```python
# ❌ Risky: May not run during DST transition
trigger = CronTrigger(hour=2, minute=30, timezone='America/New_York')

# ✅ Safe: Schedule at 3 AM or later
trigger = CronTrigger(hour=3, minute=0, timezone='America/New_York')
```

#### Solution 2: Handle NonExistentTimeError
```python
from pytz.exceptions import NonExistentTimeError, AmbiguousTimeError

def safe_localize(dt: datetime, tz: pytz.timezone):
    """Safely localize datetime, handling DST transitions."""
    try:
        return tz.localize(dt)
    except NonExistentTimeError:
        # Time doesn't exist (spring forward)
        # Use the time after DST transition
        return tz.localize(dt, is_dst=False)
    except AmbiguousTimeError:
        # Time exists twice (fall back)
        # Use the first occurrence (before DST ends)
        return tz.localize(dt, is_dst=True)
```

#### Solution 3: Use UTC for Calculations
```python
def calculate_next_run_dst_safe(
    last_run: datetime,
    hour: int,
    minute: int,
    user_timezone: str
) -> datetime:
    """Calculate next run time, handling DST transitions."""

    # Work in UTC
    if last_run.tzinfo is None:
        last_run = pytz.utc.localize(last_run)

    # Convert to user timezone
    user_tz = pytz.timezone(user_timezone)
    last_run_local = last_run.astimezone(user_tz)

    # Calculate next occurrence
    next_run_local = last_run_local.replace(
        hour=hour,
        minute=minute,
        second=0,
        microsecond=0
    )

    # If time already passed, add a day
    if next_run_local <= last_run_local:
        next_run_local += timedelta(days=1)

    # Normalize to handle DST transitions
    next_run_local = user_tz.normalize(next_run_local)

    # Convert back to UTC
    return next_run_local.astimezone(pytz.utc)
```

#### Solution 4: Test Around DST Dates
```python
def test_dst_transitions():
    """Test scheduling around DST transitions."""
    tz = pytz.timezone('America/New_York')

    # Spring forward: March 10, 2024, 2:00 AM -> 3:00 AM
    spring_dates = [
        datetime(2024, 3, 9, 9, 0),   # Day before
        datetime(2024, 3, 10, 1, 0),  # Before transition
        datetime(2024, 3, 10, 3, 0),  # After transition
        datetime(2024, 3, 11, 9, 0),  # Day after
    ]

    # Fall back: November 3, 2024, 2:00 AM -> 1:00 AM
    fall_dates = [
        datetime(2024, 11, 2, 9, 0),  # Day before
        datetime(2024, 11, 3, 1, 0),  # Before transition
        datetime(2024, 11, 3, 3, 0),  # After transition
        datetime(2024, 11, 4, 9, 0),  # Day after
    ]

    for dt in spring_dates + fall_dates:
        try:
            localized = tz.localize(dt)
            utc = localized.astimezone(pytz.utc)
            print(f"{dt} -> {localized} -> {utc}")
        except Exception as e:
            print(f"{dt} -> ERROR: {e}")
```

---

## Timezone-Naive vs Timezone-Aware

### Symptom
`TypeError: can't compare offset-naive and offset-aware datetimes`

### Diagnosis

```python
from datetime import datetime
import pytz

naive = datetime(2024, 1, 1, 9, 0)
aware = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)

print(f"Naive has tzinfo: {naive.tzinfo is not None}")  # False
print(f"Aware has tzinfo: {aware.tzinfo is not None}")  # True

# This will raise TypeError
try:
    result = naive < aware
except TypeError as e:
    print(f"Error: {e}")
```

### Solutions

#### Solution 1: Always Use Timezone-Aware Datetimes
```python
import pytz
from datetime import datetime

# ❌ Wrong: Timezone-naive
naive_dt = datetime(2024, 1, 1, 9, 0)

# ✅ Correct: Timezone-aware
utc = pytz.utc
aware_dt = utc.localize(datetime(2024, 1, 1, 9, 0))

# Or use timezone directly
aware_dt = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
```

#### Solution 2: Convert Naive to Aware
```python
def make_aware(dt: datetime, timezone: str = 'UTC') -> datetime:
    """Convert naive datetime to aware."""
    if dt.tzinfo is not None:
        return dt  # Already aware

    tz = pytz.timezone(timezone)
    return tz.localize(dt)
```

#### Solution 3: Enforce Timezone-Aware in Models
```python
from sqlmodel import SQLModel, Field
from datetime import datetime
from pydantic import validator
import pytz

class RecurringTask(SQLModel, table=True):
    next_run: datetime

    @validator('next_run', pre=True)
    def ensure_timezone_aware(cls, v):
        """Ensure datetime is timezone-aware."""
        if isinstance(v, datetime) and v.tzinfo is None:
            # Assume UTC if no timezone
            return pytz.utc.localize(v)
        return v
```

---

## Invalid Timezone Errors

### Symptom
`pytz.exceptions.UnknownTimeZoneError: 'Invalid/Timezone'`

### Diagnosis

```python
import pytz

# Check if timezone is valid
timezone_name = "America/New_York"
try:
    tz = pytz.timezone(timezone_name)
    print(f"Valid timezone: {tz}")
except pytz.exceptions.UnknownTimeZoneError:
    print(f"Invalid timezone: {timezone_name}")
```

### Solutions

#### Solution 1: Validate Timezone Input
```python
import pytz
from fastapi import HTTPException

def validate_timezone(timezone: str) -> str:
    """Validate timezone string."""
    try:
        pytz.timezone(timezone)
        return timezone
    except pytz.exceptions.UnknownTimeZoneError:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid timezone: {timezone}. Use IANA timezone names."
        )
```

#### Solution 2: Provide Timezone List
```python
def get_common_timezones() -> list[str]:
    """Get list of common timezones."""
    return pytz.common_timezones

def get_all_timezones() -> list[str]:
    """Get list of all timezones."""
    return pytz.all_timezones

# In API
@app.get("/timezones")
async def list_timezones():
    return {"timezones": get_common_timezones()}
```

#### Solution 3: Use Timezone Aliases
```python
# Map common abbreviations to IANA names
TIMEZONE_ALIASES = {
    'EST': 'America/New_York',
    'PST': 'America/Los_Angeles',
    'CST': 'America/Chicago',
    'MST': 'America/Denver',
    'GMT': 'Europe/London',
    'CET': 'Europe/Paris',
    'JST': 'Asia/Tokyo',
}

def resolve_timezone(timezone: str) -> str:
    """Resolve timezone alias to IANA name."""
    return TIMEZONE_ALIASES.get(timezone, timezone)
```

---

## Conversion Errors

### Symptom
Times convert incorrectly between timezones.

### Diagnosis

```python
import pytz
from datetime import datetime

utc_time = datetime(2024, 1, 1, 14, 0, tzinfo=pytz.utc)
ny_tz = pytz.timezone('America/New_York')

# Wrong way
wrong = utc_time.replace(tzinfo=ny_tz)
print(f"Wrong: {wrong}")  # Just changes label, doesn't convert

# Right way
correct = utc_time.astimezone(ny_tz)
print(f"Correct: {correct}")  # Actually converts time
```

### Solutions

#### Solution 1: Use astimezone() for Conversion
```python
# ❌ Wrong: replace() just changes timezone label
utc_time = datetime.now(pytz.utc)
wrong = utc_time.replace(tzinfo=pytz.timezone('America/New_York'))

# ✅ Correct: astimezone() converts the time
correct = utc_time.astimezone(pytz.timezone('America/New_York'))
```

#### Solution 2: Use localize() for Naive Datetimes
```python
# ❌ Wrong: Using tzinfo parameter with naive datetime
naive = datetime(2024, 1, 1, 9, 0)
wrong = naive.replace(tzinfo=pytz.timezone('America/New_York'))

# ✅ Correct: Use localize()
tz = pytz.timezone('America/New_York')
correct = tz.localize(naive)
```

#### Solution 3: Create Conversion Helper
```python
def convert_timezone(
    dt: datetime,
    from_tz: str,
    to_tz: str
) -> datetime:
    """Convert datetime from one timezone to another."""
    from_tz_obj = pytz.timezone(from_tz)
    to_tz_obj = pytz.timezone(to_tz)

    # Ensure datetime is aware
    if dt.tzinfo is None:
        dt = from_tz_obj.localize(dt)

    # Convert to target timezone
    return dt.astimezone(to_tz_obj)
```

---

## Display Issues

### Symptom
Times display incorrectly to users in different timezones.

### Solutions

#### Solution 1: Store UTC, Display Local
```python
from pydantic import BaseModel, validator
import pytz

class TaskResponse(BaseModel):
    id: int
    title: str
    next_run: datetime
    timezone: str

    @validator('next_run')
    def convert_to_user_timezone(cls, v, values):
        """Convert next_run to user's timezone for display."""
        if 'timezone' in values:
            user_tz = pytz.timezone(values['timezone'])
            if v.tzinfo is None:
                v = pytz.utc.localize(v)
            return v.astimezone(user_tz)
        return v

    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }
```

#### Solution 2: Format with Timezone Name
```python
def format_with_timezone(dt: datetime, timezone: str) -> str:
    """Format datetime with timezone name."""
    tz = pytz.timezone(timezone)

    if dt.tzinfo is None:
        dt = pytz.utc.localize(dt)

    local_dt = dt.astimezone(tz)

    # Format: "2024-01-09 03:45 PM EST"
    return local_dt.strftime('%Y-%m-%d %I:%M %p %Z')
```

#### Solution 3: Include UTC Offset
```python
def format_with_offset(dt: datetime, timezone: str) -> str:
    """Format datetime with UTC offset."""
    tz = pytz.timezone(timezone)

    if dt.tzinfo is None:
        dt = pytz.utc.localize(dt)

    local_dt = dt.astimezone(tz)

    # Format: "2024-01-09 03:45 PM EST (UTC-05:00)"
    return local_dt.strftime('%Y-%m-%d %I:%M %p %Z (UTC%z)')
```

---

## Database Timezone Issues

### Symptom
Times stored incorrectly in database or retrieved with wrong timezone.

### Solutions

#### Solution 1: Configure Database for UTC
```python
# PostgreSQL
from sqlalchemy import create_engine

engine = create_engine(
    'postgresql://user:pass@localhost/db',
    connect_args={'options': '-c timezone=utc'}
)
```

#### Solution 2: Use Timezone-Aware Column Types
```python
from sqlmodel import SQLModel, Field
from datetime import datetime

class RecurringTask(SQLModel, table=True):
    # SQLModel/SQLAlchemy will handle timezone conversion
    created_at: datetime = Field(default_factory=lambda: datetime.now(pytz.utc))
    next_run: datetime
```

#### Solution 3: Normalize on Read/Write
```python
def save_task(task: RecurringTask, session: Session):
    """Save task with UTC normalization."""
    # Ensure all datetimes are UTC
    if task.next_run.tzinfo is None:
        task.next_run = pytz.utc.localize(task.next_run)
    else:
        task.next_run = task.next_run.astimezone(pytz.utc)

    session.add(task)
    session.commit()

def load_task(task_id: int, session: Session) -> RecurringTask:
    """Load task and ensure UTC timezone."""
    task = session.get(RecurringTask, task_id)

    # Ensure timezone is set
    if task.next_run.tzinfo is None:
        task.next_run = pytz.utc.localize(task.next_run)

    return task
```

---

## Testing Timezone Logic

### Test 1: UTC Storage
```python
def test_utc_storage():
    """Test that times are stored in UTC."""
    task = RecurringTask(
        title="Test",
        timezone="America/New_York",
        next_run=datetime(2024, 1, 1, 14, 0, tzinfo=pytz.utc)
    )

    session.add(task)
    session.commit()
    session.refresh(task)

    # Verify stored in UTC
    assert task.next_run.tzinfo == pytz.utc
    assert task.next_run.hour == 14  # Still 14:00 UTC
```

### Test 2: Timezone Conversion
```python
def test_timezone_conversion():
    """Test timezone conversion."""
    utc_time = datetime(2024, 1, 1, 14, 0, tzinfo=pytz.utc)

    # Convert to New York time
    ny_tz = pytz.timezone('America/New_York')
    ny_time = utc_time.astimezone(ny_tz)

    # Should be 9 AM EST (UTC-5)
    assert ny_time.hour == 9
    assert ny_time.strftime('%Z') == 'EST'
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

### Test 4: Round-Trip Conversion
```python
def test_round_trip_conversion():
    """Test that conversion is reversible."""
    original = datetime(2024, 1, 1, 14, 0, tzinfo=pytz.utc)

    # Convert to NY time and back
    ny_tz = pytz.timezone('America/New_York')
    ny_time = original.astimezone(ny_tz)
    back_to_utc = ny_time.astimezone(pytz.utc)

    assert original == back_to_utc
```

---

## Quick Reference: Common Timezone Operations

```python
import pytz
from datetime import datetime

# Get current time in UTC
utc_now = datetime.now(pytz.utc)

# Get current time in specific timezone
ny_tz = pytz.timezone('America/New_York')
ny_now = datetime.now(ny_tz)

# Convert UTC to local
utc_time = datetime(2024, 1, 1, 14, 0, tzinfo=pytz.utc)
local_time = utc_time.astimezone(ny_tz)

# Convert local to UTC
local_time = ny_tz.localize(datetime(2024, 1, 1, 9, 0))
utc_time = local_time.astimezone(pytz.utc)

# Make naive datetime aware
naive = datetime(2024, 1, 1, 9, 0)
aware = ny_tz.localize(naive)

# Format with timezone
formatted = local_time.strftime('%Y-%m-%d %I:%M %p %Z')
```

---

## Resources

- [pytz Documentation](https://pythonhosted.org/pytz/)
- [Python datetime Documentation](https://docs.python.org/3/library/datetime.html)
- [IANA Time Zone Database](https://www.iana.org/time-zones)
- [Time Zone Converter](https://www.timeanddate.com/worldclock/converter.html)
- [DST Dates](https://www.timeanddate.com/time/dst/)
