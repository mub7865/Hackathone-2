# Common Cron Expression Patterns

This guide provides common cron expression patterns for recurring task scheduling.

## Cron Expression Format

```
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of month (1 - 31)
│ │ │ ┌───────────── month (1 - 12)
│ │ │ │ ┌───────────── day of week (0 - 6) (Sunday to Saturday)
│ │ │ │ │
* * * * *
```

## Special Characters

- `*` - Any value
- `,` - Value list separator (e.g., `1,3,5`)
- `-` - Range of values (e.g., `1-5`)
- `/` - Step values (e.g., `*/15` = every 15 units)

## Common Patterns

### Every Minute
```
* * * * *
```
Runs every minute.

### Every 5 Minutes
```
*/5 * * * *
```
Runs at 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55 minutes past every hour.

### Every 15 Minutes
```
*/15 * * * *
```
Runs at 0, 15, 30, 45 minutes past every hour.

### Every 30 Minutes
```
*/30 * * * *
```
or
```
0,30 * * * *
```
Runs at 0 and 30 minutes past every hour.

### Every Hour
```
0 * * * *
```
Runs at the start of every hour (minute 0).

### Every 2 Hours
```
0 */2 * * *
```
Runs at 0:00, 2:00, 4:00, 6:00, 8:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00, 22:00.

### Every Day at Midnight
```
0 0 * * *
```
Runs at 00:00 every day.

### Every Day at 9:00 AM
```
0 9 * * *
```
Runs at 09:00 every day.

### Every Day at 5:30 PM
```
30 17 * * *
```
Runs at 17:30 (5:30 PM) every day.

### Twice a Day (9 AM and 5 PM)
```
0 9,17 * * *
```
Runs at 09:00 and 17:00 every day.

### Every Weekday at 9:00 AM
```
0 9 * * 1-5
```
Runs at 09:00 Monday through Friday.

### Every Weekend at 10:00 AM
```
0 10 * * 0,6
```
or
```
0 10 * * 6,0
```
Runs at 10:00 on Saturday and Sunday.

### Every Monday at 9:00 AM
```
0 9 * * 1
```
Runs at 09:00 every Monday.

### Every Friday at 5:00 PM
```
0 17 * * 5
```
Runs at 17:00 every Friday.

### First Day of Every Month at 9:00 AM
```
0 9 1 * *
```
Runs at 09:00 on the 1st of every month.

### Last Day of Every Month
```
0 9 28-31 * *
```
Note: This runs on days 28-31, which covers the last day of every month.

### 15th of Every Month at 2:00 PM
```
0 14 15 * *
```
Runs at 14:00 on the 15th of every month.

### First Monday of Every Month
```
0 9 1-7 * 1
```
Runs at 09:00 on the first Monday of every month (days 1-7 that are Monday).

### Every Quarter (Jan, Apr, Jul, Oct) on 1st at 9:00 AM
```
0 9 1 1,4,7,10 *
```
Runs at 09:00 on January 1st, April 1st, July 1st, and October 1st.

### Every 6 Months (Jan and Jul) on 1st at 9:00 AM
```
0 9 1 1,7 *
```
Runs at 09:00 on January 1st and July 1st.

### Yearly on January 1st at Midnight
```
0 0 1 1 *
```
Runs at 00:00 on January 1st every year.

### Every Business Day at 9:00 AM
```
0 9 * * 1-5
```
Runs at 09:00 Monday through Friday.

### Every Night at 2:00 AM
```
0 2 * * *
```
Runs at 02:00 every day (common for maintenance tasks).

### Every Sunday at 3:00 AM
```
0 3 * * 0
```
Runs at 03:00 every Sunday (common for weekly backups).

## Advanced Patterns

### Every 10 Minutes During Business Hours (9 AM - 5 PM)
```
*/10 9-17 * * 1-5
```
Runs every 10 minutes from 09:00 to 17:59, Monday through Friday.

### Every Hour During Business Hours
```
0 9-17 * * 1-5
```
Runs at the start of every hour from 09:00 to 17:00, Monday through Friday.

### Every 30 Minutes During Business Hours
```
0,30 9-17 * * 1-5
```
Runs at 0 and 30 minutes past every hour from 09:00 to 17:30, Monday through Friday.

### Every 2 Hours During Daytime (8 AM - 8 PM)
```
0 8-20/2 * * *
```
Runs at 08:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00 every day.

### Weekdays at 9 AM, 12 PM, and 5 PM
```
0 9,12,17 * * 1-5
```
Runs at 09:00, 12:00, and 17:00, Monday through Friday.

### Every 15 Minutes During Peak Hours (9 AM - 12 PM and 2 PM - 5 PM)
```
*/15 9-12,14-17 * * 1-5
```
Runs every 15 minutes from 09:00-12:59 and 14:00-17:59, Monday through Friday.

## Testing Cron Expressions

### Online Tools
- [Crontab Guru](https://crontab.guru/) - Interactive cron expression tester
- [Cron Expression Generator](https://www.freeformatter.com/cron-expression-generator-quartz.html)

### Python Testing
```python
from croniter import croniter
from datetime import datetime

# Test cron expression
cron_expr = "0 9 * * 1-5"  # Every weekday at 9 AM
base = datetime(2024, 1, 1, 0, 0)
cron = croniter(cron_expr, base)

# Get next 5 occurrences
for i in range(5):
    next_run = cron.get_next(datetime)
    print(f"{i+1}. {next_run.strftime('%Y-%m-%d %H:%M:%S %A')}")
```

Output:
```
1. 2024-01-01 09:00:00 Monday
2. 2024-01-02 09:00:00 Tuesday
3. 2024-01-03 09:00:00 Wednesday
4. 2024-01-04 09:00:00 Thursday
5. 2024-01-05 09:00:00 Friday
```

## Common Use Cases

### Daily Reports
```
0 9 * * *  # Every day at 9 AM
```

### Weekly Reports
```
0 9 * * 1  # Every Monday at 9 AM
```

### Monthly Reports
```
0 9 1 * *  # First day of month at 9 AM
```

### Quarterly Reports
```
0 9 1 1,4,7,10 *  # Jan 1, Apr 1, Jul 1, Oct 1 at 9 AM
```

### Daily Backups
```
0 2 * * *  # Every day at 2 AM
```

### Weekly Backups
```
0 3 * * 0  # Every Sunday at 3 AM
```

### Hourly Health Checks
```
0 * * * *  # Every hour
```

### Frequent Monitoring (Every 5 Minutes)
```
*/5 * * * *  # Every 5 minutes
```

### Daily Cleanup (Midnight)
```
0 0 * * *  # Every day at midnight
```

### Business Hours Reminders
```
0 9,12,15,17 * * 1-5  # 9 AM, 12 PM, 3 PM, 5 PM on weekdays
```

## Tips

1. **Use Crontab Guru**: Always test your cron expressions at https://crontab.guru/
2. **Consider Timezones**: Cron expressions are timezone-aware in APScheduler
3. **Avoid Midnight**: Use 2-3 AM for daily tasks to avoid peak times
4. **Stagger Tasks**: Don't schedule everything at the same time
5. **Test First**: Test with frequent intervals (e.g., every minute) before deploying
6. **Document**: Always comment what the cron expression does

## Converting to Python

### Using croniter
```python
from croniter import croniter
from datetime import datetime

cron_expr = "0 9 * * 1-5"
base = datetime.now()
cron = croniter(cron_expr, base)

# Get next occurrence
next_run = cron.get_next(datetime)
print(f"Next run: {next_run}")
```

### Using APScheduler
```python
from apscheduler.triggers.cron import CronTrigger

# Create trigger from cron expression
trigger = CronTrigger.from_crontab("0 9 * * 1-5")

# Or create trigger with parameters
trigger = CronTrigger(
    hour=9,
    minute=0,
    day_of_week='mon-fri'
)
```

## Common Mistakes

### ❌ Wrong: `0 0 * * 1-7`
Days of week are 0-6, not 1-7.

### ✅ Correct: `0 0 * * 0-6` or `0 0 * * *`

### ❌ Wrong: `*/60 * * * *`
This means "every 60 minutes" which is invalid (max is 59).

### ✅ Correct: `0 * * * *` (every hour)

### ❌ Wrong: `0 9 31 * *`
Not all months have 31 days.

### ✅ Correct: `0 9 1 * *` (first day of month)

## Resources

- [Crontab Guru](https://crontab.guru/) - Interactive cron expression tester
- [Cron Wikipedia](https://en.wikipedia.org/wiki/Cron)
- [APScheduler Cron Trigger](https://apscheduler.readthedocs.io/en/stable/modules/triggers/cron.html)
- [Croniter Documentation](https://github.com/kiorky/croniter)
