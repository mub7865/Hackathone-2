# User Guide: Cloud-Native Event-Driven Todo Application

**Version**: 1.0
**Last Updated**: 2026-01-12
**Target Audience**: End Users

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Managing Tasks](#managing-tasks)
3. [Recurring Tasks](#recurring-tasks)
4. [Due Dates and Reminders](#due-dates-and-reminders)
5. [Task Priorities](#task-priorities)
6. [Task Tags](#task-tags)
7. [Search and Filters](#search-and-filters)
8. [Notification Preferences](#notification-preferences)
9. [Audit Trail](#audit-trail)
10. [Tips and Best Practices](#tips-and-best-practices)

---

## Getting Started

### Creating an Account

1. Navigate to the application URL
2. Click "Sign Up" button
3. Enter your email and password
4. Verify your email address
5. Log in with your credentials

### First Login

After logging in for the first time:
1. You'll see an empty task list
2. Click "Create Task" to add your first task
3. Explore the sidebar for additional features

### User Interface Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Logo    [Search]                    [User Menu] [Settings] │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Sidebar          │  Main Content Area                       │
│  ─────────        │  ──────────────────                      │
│  📋 All Tasks     │  Task List                               │
│  ⭐ High Priority │  ┌──────────────────────────────────┐   │
│  📅 Due Today     │  │ ☐ Task Title                     │   │
│  🔁 Recurring     │  │   Description                    │   │
│  🏷️ Tags          │  │   🏷️ tag1, tag2  ⏰ Due: Jan 15 │   │
│  📊 Statistics    │  └──────────────────────────────────┘   │
│  ⚙️ Settings      │                                          │
│                   │  [+ Create Task]                         │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Managing Tasks

### Creating a Task

1. Click the "Create Task" button
2. Enter task details:
   - **Title** (required): Brief description of the task
   - **Description** (optional): Detailed information
   - **Status**: Pending, In Progress, or Completed
   - **Priority**: Low, Medium, or High
   - **Tags**: Add relevant tags
   - **Due Date**: Set a deadline
   - **Reminder**: Set a reminder time
3. Click "Save" to create the task

**Example**:
```
Title: Complete project documentation
Description: Write comprehensive API documentation for the new features
Status: Pending
Priority: High
Tags: documentation, urgent
Due Date: January 15, 2026, 5:00 PM
Reminder: January 15, 2026, 9:00 AM
```

### Viewing Tasks

**All Tasks View**:
- Shows all your tasks
- Default sort: Most recent first
- Click on a task to view details

**Filtered Views**:
- **High Priority**: Tasks marked as high priority
- **Due Today**: Tasks due today
- **Overdue**: Tasks past their due date
- **Completed**: Completed tasks

### Updating a Task

1. Click on the task to open details
2. Click "Edit" button
3. Modify any field
4. Click "Save" to update

**Quick Actions**:
- **Mark as Complete**: Click the checkbox
- **Change Priority**: Click the priority indicator
- **Add Tag**: Click the tag icon

### Deleting a Task

1. Click on the task to open details
2. Click "Delete" button
3. Confirm deletion

**Note**: Deleted tasks cannot be recovered. Consider marking as completed instead.

### Task Status

**Pending** (☐):
- Task not yet started
- Default status for new tasks

**In Progress** (⏳):
- Task currently being worked on
- Shows you're actively working on it

**Completed** (✓):
- Task finished
- Moves to completed list
- Can be filtered out of main view

---

## Recurring Tasks

### Creating a Recurring Task

1. Click "Recurring Tasks" in sidebar
2. Click "Create Recurring Pattern"
3. Configure pattern:
   - **Frequency**: Daily, Weekly, Monthly, or Yearly
   - **Interval**: Every N days/weeks/months
   - **Days of Week** (for weekly): Select specific days
   - **Day of Month** (for monthly): Select specific day
   - **Start Date**: When to start generating tasks
   - **End Date** (optional): When to stop
4. Configure task template:
   - Title, description, priority, tags
5. Click "Save"

### Frequency Options

**Daily**:
- Every N days
- Example: Every 2 days

**Weekly**:
- Every N weeks on specific days
- Example: Every week on Monday, Wednesday, Friday

**Monthly**:
- Every N months on specific day
- Example: Every month on the 15th

**Yearly**:
- Every N years
- Example: Every year on January 1st

### Examples

**Daily Standup**:
```
Frequency: Daily
Interval: 1 (every day)
Start Date: January 1, 2026
Task Template:
  Title: Daily standup meeting
  Priority: Medium
  Tags: meeting, daily
```

**Weekly Team Meeting**:
```
Frequency: Weekly
Interval: 1 (every week)
Days of Week: Monday, Wednesday, Friday
Start Date: January 1, 2026
Task Template:
  Title: Team sync meeting
  Priority: High
  Tags: meeting, team
```

**Monthly Report**:
```
Frequency: Monthly
Interval: 1 (every month)
Day of Month: 1 (first day of month)
Start Date: January 1, 2026
Task Template:
  Title: Submit monthly report
  Priority: High
  Tags: report, deadline
```

### Managing Recurring Patterns

**View Patterns**:
- Click "Recurring Tasks" in sidebar
- See all active patterns

**Edit Pattern**:
- Click on pattern
- Modify settings
- Click "Save"

**Pause Pattern**:
- Click on pattern
- Toggle "Active" switch
- Pattern stops generating tasks

**Delete Pattern**:
- Click on pattern
- Click "Delete"
- Confirm deletion
- Note: Existing tasks remain

---

## Due Dates and Reminders

### Setting Due Dates

1. When creating/editing a task
2. Click "Due Date" field
3. Select date and time
4. Click "Save"

**Due Date Indicators**:
- 🟢 Green: More than 3 days away
- 🟡 Yellow: 1-3 days away
- 🔴 Red: Due today or overdue

### Setting Reminders

1. When creating/editing a task
2. Click "Reminder" field
3. Select date and time
4. Must be before due date
5. Click "Save"

**Reminder Options**:
- Custom date and time
- 1 hour before due
- 1 day before due
- 1 week before due

### Notification Channels

Reminders can be sent via:
- **Email**: Sent to your registered email
- **In-App**: Notification in the application
- **Push**: Browser push notification (if enabled)
- **WebSocket**: Real-time update in open browser

### Quiet Hours

Configure quiet hours to avoid notifications during specific times:
1. Go to Settings > Notifications
2. Enable "Quiet Hours"
3. Set start time (e.g., 10:00 PM)
4. Set end time (e.g., 8:00 AM)
5. Select timezone
6. Click "Save"

**Note**: Critical reminders may still be sent during quiet hours.

---

## Task Priorities

### Priority Levels

**High** (🔴):
- Urgent and important tasks
- Requires immediate attention
- Shown at top of list

**Medium** (🟡):
- Important but not urgent
- Standard priority
- Default for most tasks

**Low** (🟢):
- Nice to have
- Can be done later
- Shown at bottom of list

### Setting Priority

**When Creating**:
- Select priority from dropdown
- Default: Medium

**Quick Change**:
- Click priority indicator on task
- Cycles through Low → Medium → High

**Bulk Change**:
- Select multiple tasks
- Click "Change Priority"
- Select new priority

### Priority-Based Views

**High Priority View**:
- Shows only high priority tasks
- Sorted by due date
- Quick access from sidebar

**Priority Statistics**:
- View distribution of tasks by priority
- Available in Statistics section

---

## Task Tags

### Adding Tags

**When Creating Task**:
1. Type tag name in "Tags" field
2. Press Enter or comma
3. Add multiple tags

**To Existing Task**:
1. Click on task
2. Click "Add Tag"
3. Type tag name
4. Press Enter

**Tag Suggestions**:
- System suggests frequently used tags
- Click to add

### Tag Management

**View All Tags**:
- Click "Tags" in sidebar
- See all tags with usage count

**Rename Tag**:
- Click on tag
- Click "Rename"
- Enter new name
- All tasks updated automatically

**Delete Tag**:
- Click on tag
- Click "Delete"
- Confirm deletion
- Removed from all tasks

### Tag Best Practices

**Use Consistent Naming**:
- Lowercase: `documentation`, `urgent`
- Avoid duplicates: `doc` vs `documentation`

**Common Tag Categories**:
- **Project**: `project-alpha`, `project-beta`
- **Context**: `work`, `personal`, `home`
- **Status**: `urgent`, `blocked`, `waiting`
- **Type**: `meeting`, `email`, `call`

**Tag Limits**:
- Maximum 10 tags per task
- Maximum 50 characters per tag

---

## Search and Filters

### Basic Search

1. Click search bar at top
2. Type search query
3. Results update in real-time

**Search Scope**:
- Task titles
- Task descriptions
- Tags

**Search Tips**:
- Use quotes for exact match: `"project documentation"`
- Case-insensitive

### Advanced Filters

**Filter Panel**:
1. Click "Filters" button
2. Select filter criteria:
   - Status: Pending, In Progress, Completed
   - Priority: Low, Medium, High
   - Tags: Select one or more tags
   - Due Date: Today, This Week, This Month, Custom Range
3. Click "Apply"

**Multiple Filters**:
- Combine multiple criteria
- Results match ALL selected filters (AND logic)

### Saved Filters

**Create Saved Filter**:
1. Apply desired filters
2. Click "Save Filter"
3. Enter filter name
4. Click "Save"

**Use Saved Filter**:
1. Click "Saved Filters" in sidebar
2. Click on filter name
3. Results update automatically

**Manage Saved Filters**:
- Edit: Modify filter criteria
- Rename: Change filter name
- Delete: Remove saved filter

**Example Saved Filters**:
- "High Priority Pending": Status=Pending, Priority=High
- "Due This Week": Due Date=This Week
- "Work Tasks": Tags=work
- "Urgent Documentation": Priority=High, Tags=documentation

### Sorting

**Sort Options**:
- Created Date (newest/oldest)
- Updated Date (newest/oldest)
- Due Date (soonest/latest)
- Priority (high to low/low to high)
- Title (A-Z/Z-A)

**Change Sort**:
1. Click sort dropdown
2. Select sort field
3. Click again to reverse order

---

## Notification Preferences

### Accessing Preferences

1. Click user menu (top right)
2. Select "Settings"
3. Click "Notifications" tab

### Notification Channels

**Email Notifications**:
- Toggle on/off
- Sent to registered email
- Includes task details and links

**In-App Notifications**:
- Toggle on/off
- Shown in notification center
- Real-time updates

**Push Notifications**:
- Toggle on/off
- Requires browser permission
- Works when app is closed

**SMS Notifications** (if configured):
- Toggle on/off
- Requires phone number verification
- Limited to critical reminders

### Notification Types

**Task Updates**:
- Task created
- Task updated
- Task completed
- Task deleted

**Reminders**:
- Due date approaching
- Reminder time reached

**Recurring Tasks**:
- New task generated from pattern

### Frequency Settings

**Immediate**:
- Notify as soon as event occurs
- Best for urgent tasks

**Daily Digest**:
- One email per day with all updates
- Sent at configured time

**Weekly Digest**:
- One email per week with summary
- Sent on configured day

### Quiet Hours

**Configure Quiet Hours**:
1. Enable "Quiet Hours"
2. Set start time (e.g., 10:00 PM)
3. Set end time (e.g., 8:00 AM)
4. Select timezone
5. Save settings

**During Quiet Hours**:
- Non-urgent notifications suppressed
- Critical reminders still sent
- Notifications queued for later

### Rate Limiting

To prevent notification spam:
- Maximum 20 notifications per hour
- Maximum 100 notifications per day
- Maximum 5 of same type per hour

**If Limit Reached**:
- Additional notifications suppressed
- Summary sent at end of period

---

## Audit Trail

### Viewing Audit Trail

1. Click on a task
2. Click "History" tab
3. See all changes to task

**Audit Information**:
- Action performed (created, updated, deleted)
- User who performed action
- Timestamp
- Changes made (before/after values)
- IP address
- User agent

### Audit Actions

**Created**:
- Task was created
- Shows initial values

**Updated**:
- Task was modified
- Shows field-by-field changes
- Before and after values

**Deleted**:
- Task was deleted
- Shows final state

**Completed**:
- Task marked as completed
- Shows completion time

**Viewed**:
- Task was viewed
- Tracks access for compliance

### Filtering Audit Logs

**By Date Range**:
- Select start and end dates
- View changes in specific period

**By Action**:
- Filter by action type
- See only creates, updates, or deletes

**By User**:
- Filter by user (if shared tasks)
- See who made changes

### Audit Statistics

**View Statistics**:
1. Click "Statistics" in sidebar
2. Click "Audit" tab

**Available Statistics**:
- Total actions by type
- Most active days
- Actions per user
- Changes by field

---

## Tips and Best Practices

### Task Management

**Keep Titles Concise**:
- Use clear, actionable titles
- Example: "Complete project documentation" not "Documentation"

**Use Descriptions for Details**:
- Add context in description
- Include links, requirements, notes

**Set Realistic Due Dates**:
- Don't overcommit
- Leave buffer time
- Consider dependencies

**Review Regularly**:
- Daily: Check due today
- Weekly: Review upcoming tasks
- Monthly: Clean up completed tasks

### Priority Management

**Use High Priority Sparingly**:
- Reserve for truly urgent tasks
- Too many high priority = none are high

**Eisenhower Matrix**:
- Urgent + Important = High Priority
- Important + Not Urgent = Medium Priority
- Urgent + Not Important = Low Priority (or delegate)
- Not Urgent + Not Important = Don't add

### Tag Strategy

**Create Tag Hierarchy**:
- Use prefixes: `project:alpha`, `project:beta`
- Consistent naming convention

**Limit Tags Per Task**:
- 3-5 tags is optimal
- Too many = hard to filter

**Review Tags Periodically**:
- Merge similar tags
- Delete unused tags
- Rename for clarity

### Recurring Tasks

**Start Simple**:
- Begin with daily/weekly patterns
- Add complexity as needed

**Review Generated Tasks**:
- Check if pattern is working
- Adjust frequency if needed

**Pause When Not Needed**:
- Vacation, holidays
- Temporary projects

### Notifications

**Configure Quiet Hours**:
- Avoid notification fatigue
- Set boundaries

**Use Daily Digest**:
- For non-urgent updates
- Reduce interruptions

**Test Notifications**:
- Ensure they're working
- Check spam folder for emails

### Search and Filters

**Use Saved Filters**:
- Create filters for common views
- Quick access to relevant tasks

**Combine Filters**:
- Narrow down results
- Find exactly what you need

**Regular Searches**:
- Find orphaned tasks
- Identify patterns

---

## Keyboard Shortcuts

### Navigation

- `Ctrl/Cmd + K`: Open search
- `Ctrl/Cmd + N`: Create new task
- `Ctrl/Cmd + /`: Show shortcuts
- `Esc`: Close modal/dialog

### Task Actions

- `Space`: Toggle task completion
- `E`: Edit selected task
- `D`: Delete selected task
- `P`: Change priority

### List Navigation

- `↑/↓`: Navigate tasks
- `Enter`: Open selected task
- `Ctrl/Cmd + A`: Select all
- `Ctrl/Cmd + Click`: Multi-select

---

## Mobile App

### Features

- Full task management
- Push notifications
- Offline mode
- Quick add widget

### Download

- **iOS**: App Store
- **Android**: Google Play

### Sync

- Automatic sync when online
- Offline changes sync when connected
- Conflict resolution

---

## Troubleshooting

### Common Issues

**Tasks Not Syncing**:
- Check internet connection
- Refresh page
- Clear browser cache

**Notifications Not Received**:
- Check notification settings
- Verify email address
- Check spam folder
- Enable browser notifications

**Can't Create Task**:
- Check required fields (title)
- Verify due date is in future
- Check character limits

**Slow Performance**:
- Clear browser cache
- Close unused tabs
- Check internet speed

### Getting Help

**In-App Help**:
- Click "?" icon
- Search help articles
- Watch tutorial videos

**Contact Support**:
- Email: support@todo-app.example.com
- Live Chat: Available 9 AM - 5 PM EST
- Response time: Within 24 hours

---

## Privacy and Security

### Data Privacy

- Your data is encrypted at rest and in transit
- We never share your data with third parties
- You can export your data anytime
- You can delete your account and all data

### Security Features

- Two-factor authentication (2FA)
- Session timeout after inactivity
- Audit trail for all actions
- Regular security audits

### Data Export

1. Go to Settings > Data
2. Click "Export Data"
3. Select format (JSON, CSV)
4. Download file

### Account Deletion

1. Go to Settings > Account
2. Click "Delete Account"
3. Confirm deletion
4. All data permanently deleted

---

## Frequently Asked Questions

**Q: Can I share tasks with others?**
A: Task sharing is coming in a future update.

**Q: Is there a mobile app?**
A: Yes, available on iOS and Android.

**Q: Can I import tasks from other apps?**
A: Yes, we support CSV import. Go to Settings > Import.

**Q: How many tasks can I create?**
A: No limit on number of tasks.

**Q: Can I use offline?**
A: Mobile app supports offline mode. Web app requires internet.

**Q: How do I change my password?**
A: Go to Settings > Security > Change Password.

**Q: Can I customize the theme?**
A: Yes, dark mode and custom themes available in Settings > Appearance.

**Q: How do I cancel my subscription?**
A: Go to Settings > Billing > Cancel Subscription.

---

## Changelog

### Version 1.0 (2026-01-12)
- Initial release
- Task management (create, read, update, delete)
- Recurring tasks
- Due dates and reminders
- Task priorities
- Task tags
- Advanced search and filters
- Notification preferences
- Audit trail
- Real-time updates via WebSocket

---

## Support

For questions and support:
- **Email**: support@todo-app.example.com
- **Documentation**: https://docs.todo-app.example.com
- **Community Forum**: https://community.todo-app.example.com
- **Status Page**: https://status.todo-app.example.com

---

## Feedback

We'd love to hear from you!
- **Feature Requests**: https://feedback.todo-app.example.com
- **Bug Reports**: https://github.com/your-org/todo-app/issues
- **General Feedback**: feedback@todo-app.example.com

Thank you for using the Todo Application!
