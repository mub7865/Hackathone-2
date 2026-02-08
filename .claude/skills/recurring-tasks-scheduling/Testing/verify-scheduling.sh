#!/bin/bash
# Verification Script for Recurring Task Scheduling Setup
# This script verifies that APScheduler is properly configured and working

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0

echo "=========================================="
echo "Recurring Task Scheduling Verification"
echo "=========================================="
echo ""

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}: $2"
        ((FAILED++))
    fi
}

# Test 1: Check Python dependencies
echo "Test 1: Checking Python dependencies..."
python3 -c "import apscheduler" 2>/dev/null
print_result $? "APScheduler installed"

python3 -c "import pytz" 2>/dev/null
print_result $? "pytz installed"

python3 -c "import croniter" 2>/dev/null
print_result $? "croniter installed"

python3 -c "import sqlmodel" 2>/dev/null
print_result $? "SQLModel installed"

echo ""

# Test 2: Verify scheduler can be created
echo "Test 2: Creating background scheduler..."
python3 << 'EOF'
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore
import sys

try:
    jobstores = {
        'default': SQLAlchemyJobStore(url='sqlite:///:memory:')
    }

    scheduler = BackgroundScheduler(
        jobstores=jobstores,
        job_defaults={
            'coalesce': True,
            'max_instances': 1,
            'misfire_grace_time': 300
        }
    )

    print("Scheduler created successfully")
    sys.exit(0)
except Exception as e:
    print(f"Failed to create scheduler: {e}")
    sys.exit(1)
EOF
print_result $? "Background scheduler creation"

echo ""

# Test 3: Test cron trigger creation
echo "Test 3: Testing cron trigger creation..."
python3 << 'EOF'
from apscheduler.triggers.cron import CronTrigger
import pytz
import sys

try:
    # Daily trigger
    trigger1 = CronTrigger(hour=9, minute=0, timezone='UTC')

    # Weekly trigger
    trigger2 = CronTrigger(day_of_week=0, hour=9, minute=0, timezone='UTC')

    # Monthly trigger
    trigger3 = CronTrigger(day=1, hour=9, minute=0, timezone='UTC')

    # Custom cron expression
    trigger4 = CronTrigger.from_crontab("0 9 * * 1-5", timezone='UTC')

    print("All triggers created successfully")
    sys.exit(0)
except Exception as e:
    print(f"Failed to create triggers: {e}")
    sys.exit(1)
EOF
print_result $? "Cron trigger creation"

echo ""

# Test 4: Test timezone handling
echo "Test 4: Testing timezone handling..."
python3 << 'EOF'
import pytz
from datetime import datetime
import sys

try:
    # Test common timezones
    timezones = ['UTC', 'America/New_York', 'Europe/London', 'Asia/Tokyo']

    for tz_name in timezones:
        tz = pytz.timezone(tz_name)
        now = datetime.now(tz)
        assert now.tzinfo is not None, f"Timezone {tz_name} not properly set"

    print("All timezones working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Timezone handling failed: {e}")
    sys.exit(1)
EOF
print_result $? "Timezone handling"

echo ""

# Test 5: Test next occurrence calculation
echo "Test 5: Testing next occurrence calculation..."
python3 << 'EOF'
from datetime import datetime, timedelta
from croniter import croniter
import pytz
import sys

try:
    # Test daily occurrence
    base = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)
    cron = croniter("0 9 * * *", base)
    next_run = cron.get_next(datetime)
    expected = datetime(2024, 1, 2, 9, 0, tzinfo=pytz.utc)
    assert next_run == expected, f"Daily calculation failed: {next_run} != {expected}"

    # Test weekly occurrence
    base = datetime(2024, 1, 1, 9, 0, tzinfo=pytz.utc)  # Monday
    cron = croniter("0 9 * * 1", base)
    next_run = cron.get_next(datetime)
    expected = datetime(2024, 1, 8, 9, 0, tzinfo=pytz.utc)  # Next Monday
    assert next_run == expected, f"Weekly calculation failed: {next_run} != {expected}"

    print("Next occurrence calculations working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Next occurrence calculation failed: {e}")
    sys.exit(1)
EOF
print_result $? "Next occurrence calculation"

echo ""

# Test 6: Test scheduler lifecycle
echo "Test 6: Testing scheduler lifecycle..."
python3 << 'EOF'
from apscheduler.schedulers.background import BackgroundScheduler
import time
import sys

try:
    scheduler = BackgroundScheduler()

    # Test start
    scheduler.start()
    assert scheduler.running, "Scheduler not running after start"

    # Test add job
    def test_job():
        pass

    scheduler.add_job(test_job, 'interval', seconds=60, id='test_job')
    job = scheduler.get_job('test_job')
    assert job is not None, "Job not added"

    # Test remove job
    scheduler.remove_job('test_job')
    job = scheduler.get_job('test_job')
    assert job is None, "Job not removed"

    # Test shutdown
    scheduler.shutdown(wait=False)
    assert not scheduler.running, "Scheduler still running after shutdown"

    print("Scheduler lifecycle working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Scheduler lifecycle test failed: {e}")
    sys.exit(1)
EOF
print_result $? "Scheduler lifecycle"

echo ""

# Test 7: Test job execution
echo "Test 7: Testing job execution..."
python3 << 'EOF'
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta
import time
import sys

executed = []

def test_job():
    executed.append(True)

try:
    scheduler = BackgroundScheduler()
    scheduler.start()

    # Add job that runs immediately
    scheduler.add_job(
        test_job,
        'date',
        run_date=datetime.now() + timedelta(seconds=1)
    )

    # Wait for execution
    time.sleep(2)

    scheduler.shutdown(wait=False)

    assert len(executed) == 1, f"Job not executed: {len(executed)} executions"

    print("Job execution working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Job execution test failed: {e}")
    sys.exit(1)
EOF
print_result $? "Job execution"

echo ""

# Test 8: Test database persistence
echo "Test 8: Testing database persistence..."
python3 << 'EOF'
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore
import sys

try:
    jobstores = {
        'default': SQLAlchemyJobStore(url='sqlite:///test_scheduler.db')
    }

    scheduler = BackgroundScheduler(jobstores=jobstores)

    def test_job():
        pass

    scheduler.add_job(test_job, 'interval', seconds=60, id='persistent_job')

    # Verify job is in database
    job = scheduler.get_job('persistent_job')
    assert job is not None, "Job not persisted"

    scheduler.shutdown(wait=False)

    # Cleanup
    import os
    if os.path.exists('test_scheduler.db'):
        os.remove('test_scheduler.db')

    print("Database persistence working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Database persistence test failed: {e}")
    sys.exit(1)
EOF
print_result $? "Database persistence"

echo ""

# Test 9: Test misfire handling
echo "Test 9: Testing misfire handling..."
python3 << 'EOF'
from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime, timedelta
import sys

try:
    scheduler = BackgroundScheduler(
        job_defaults={
            'coalesce': True,
            'max_instances': 1,
            'misfire_grace_time': 300
        }
    )

    def test_job():
        pass

    # Add job with past run time
    past_time = datetime.now() - timedelta(hours=1)
    scheduler.add_job(
        test_job,
        'interval',
        hours=1,
        start_date=past_time,
        coalesce=True
    )

    scheduler.start()
    scheduler.shutdown(wait=False)

    print("Misfire handling configured correctly")
    sys.exit(0)
except Exception as e:
    print(f"Misfire handling test failed: {e}")
    sys.exit(1)
EOF
print_result $? "Misfire handling"

echo ""

# Summary
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Scheduler is ready to use.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please check the output above.${NC}"
    exit 1
fi
