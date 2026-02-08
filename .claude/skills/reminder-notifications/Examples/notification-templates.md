# Notification Template Examples

This guide provides examples of notification templates for different use cases.

## Template Structure

Each template should include:
- **Subject/Title**: For email and push notifications
- **Body Text**: Plain text version
- **Body HTML**: Rich HTML version (for email)
- **Variables**: Data placeholders using Jinja2 syntax

## Email Templates

### 1. Task Reminder

```python
{
    "name": "task_reminder",
    "channel": "email",
    "subject": "Reminder: {{ task_title }}",
    "body_text": """
Hello {{ user_name }},

This is a reminder that your task "{{ task_title }}" is due on {{ due_date }}.

{% if task_description %}
Description: {{ task_description }}
{% endif %}

View task: {{ task_url }}

Best regards,
The Team
    """,
    "body_html": """
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        .container { max-width: 600px; margin: 0 auto; }
        .button { background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; }
    </style>
</head>
<body>
    <div class="container">
        <h2>Task Reminder</h2>
        <p>Hello {{ user_name }},</p>
        <p>Your task <strong>"{{ task_title }}"</strong> is due on <strong>{{ due_date }}</strong>.</p>
        <a href="{{ task_url }}" class="button">View Task</a>
    </div>
</body>
</html>
    """
}
```

### 2. Welcome Email

```python
{
    "name": "welcome",
    "channel": "email",
    "subject": "Welcome to {{ app_name }}!",
    "body_text": """
Hello {{ user_name }},

Welcome to {{ app_name }}! We're excited to have you on board.

Get started:
1. Create your first task
2. Set up your preferences
3. Explore our features

Need help? Contact us at {{ support_email }}

Best regards,
The {{ app_name }} Team
    """,
    "body_html": """
<!DOCTYPE html>
<html>
<head>
    <style>
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px; text-align: center; }
        .content { padding: 30px; }
        .step { background: #f5f5f5; padding: 15px; margin: 10px 0; border-left: 4px solid #667eea; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Welcome to {{ app_name }}!</h1>
    </div>
    <div class="content">
        <p>Hello {{ user_name }},</p>
        <p>We're excited to have you on board!</p>
        <h3>Get Started:</h3>
        <div class="step">1. Create your first task</div>
        <div class="step">2. Set up your preferences</div>
        <div class="step">3. Explore our features</div>
    </div>
</body>
</html>
    """
}
```

### 3. Password Reset

```python
{
    "name": "password_reset",
    "channel": "email",
    "subject": "Reset Your Password",
    "body_text": """
Hello {{ user_name }},

We received a request to reset your password.

Click here to reset: {{ reset_url }}

This link expires in {{ expiry_hours }} hours.

If you didn't request this, please ignore this email.

Best regards,
The Team
    """,
    "body_html": """
<!DOCTYPE html>
<html>
<head>
    <style>
        .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
        .button { display: inline-block; background: #007bff; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; }
    </style>
</head>
<body>
    <h2>Reset Your Password</h2>
    <p>Hello {{ user_name }},</p>
    <p>We received a request to reset your password.</p>
    <p style="text-align: center; margin: 30px 0;">
        <a href="{{ reset_url }}" class="button">Reset Password</a>
    </p>
    <div class="warning">
        <strong>Security Notice:</strong> This link expires in {{ expiry_hours }} hours.
        If you didn't request this, please ignore this email.
    </div>
</body>
</html>
    """
}
```

### 4. Daily Digest

```python
{
    "name": "daily_digest",
    "channel": "email",
    "subject": "Your Daily Summary - {{ date }}",
    "body_text": """
Hello {{ user_name }},

Here's your task summary for {{ date }}:

📊 Statistics:
- Tasks Due Today: {{ tasks_due_today }}
- Tasks Completed: {{ tasks_completed }}
- Tasks Overdue: {{ tasks_overdue }}

{% if upcoming_tasks %}
📅 Upcoming Tasks:
{% for task in upcoming_tasks %}
- {{ task.title }} (Due: {{ task.due_date }})
{% endfor %}
{% endif %}

View dashboard: {{ dashboard_url }}
    """,
    "body_html": """
<!DOCTYPE html>
<html>
<head>
    <style>
        .stats { display: flex; justify-content: space-around; margin: 30px 0; }
        .stat { text-align: center; padding: 20px; background: #f8f9fa; border-radius: 8px; }
        .stat-number { font-size: 36px; font-weight: bold; color: #007bff; }
        .task-item { padding: 15px; margin: 10px 0; background: #f8f9fa; border-left: 4px solid #28a745; }
    </style>
</head>
<body>
    <h2>Daily Summary - {{ date }}</h2>
    <div class="stats">
        <div class="stat">
            <div class="stat-number">{{ tasks_due_today }}</div>
            <div>Due Today</div>
        </div>
        <div class="stat">
            <div class="stat-number">{{ tasks_completed }}</div>
            <div>Completed</div>
        </div>
        <div class="stat">
            <div class="stat-number">{{ tasks_overdue }}</div>
            <div>Overdue</div>
        </div>
    </div>
    {% if upcoming_tasks %}
    <h3>Upcoming Tasks</h3>
    {% for task in upcoming_tasks %}
    <div class="task-item">
        <strong>{{ task.title }}</strong><br>
        <small>Due: {{ task.due_date }}</small>
    </div>
    {% endfor %}
    {% endif %}
</body>
</html>
    """
}
```

## SMS Templates

### 1. Task Reminder

```python
{
    "name": "task_reminder",
    "channel": "sms",
    "body_text": "Reminder: '{{ task_title }}' is due on {{ due_date }}. View: {{ short_url }}"
}
```

### 2. OTP Verification

```python
{
    "name": "otp_verification",
    "channel": "sms",
    "body_text": "Your verification code is: {{ otp }}. Valid for {{ validity_minutes }} minutes. Do not share."
}
```

### 3. Task Completed

```python
{
    "name": "task_completed",
    "channel": "sms",
    "body_text": "Great job! You completed '{{ task_title }}'. {{ completed_count }} tasks done today!"
}
```

### 4. Urgent Alert

```python
{
    "name": "urgent_alert",
    "channel": "sms",
    "body_text": "⚠️ URGENT: {{ alert_message }}. Action required: {{ action_url }}"
}
```

## Push Notification Templates

### 1. Task Reminder

```python
{
    "name": "task_reminder",
    "channel": "push",
    "title": "Task Reminder",
    "body_text": "'{{ task_title }}' is due {{ time_until_due }}",
    "data": {
        "type": "task_reminder",
        "task_id": "{{ task_id }}",
        "click_action": "/tasks/{{ task_id }}"
    }
}
```

### 2. New Message

```python
{
    "name": "new_message",
    "channel": "push",
    "title": "New message from {{ sender_name }}",
    "body_text": "{{ message_preview }}",
    "data": {
        "type": "message",
        "conversation_id": "{{ conversation_id }}",
        "click_action": "/messages/{{ conversation_id }}"
    }
}
```

### 3. Achievement Unlocked

```python
{
    "name": "achievement",
    "channel": "push",
    "title": "🎉 Achievement Unlocked!",
    "body_text": "{{ achievement_name }}: {{ achievement_description }}",
    "data": {
        "type": "achievement",
        "achievement_id": "{{ achievement_id }}",
        "click_action": "/achievements"
    }
}
```

## In-App Notification Templates

### 1. System Update

```python
{
    "name": "system_update",
    "channel": "in_app",
    "title": "New Feature Available",
    "body_text": "{{ feature_name }}: {{ feature_description }}",
    "data": {
        "type": "feature_announcement",
        "feature_id": "{{ feature_id }}",
        "icon": "✨",
        "action_text": "Learn More",
        "action_url": "/features/{{ feature_id }}"
    }
}
```

### 2. Collaboration Invite

```python
{
    "name": "collaboration_invite",
    "channel": "in_app",
    "title": "{{ inviter_name }} invited you",
    "body_text": "You've been invited to collaborate on '{{ project_name }}'",
    "data": {
        "type": "invite",
        "project_id": "{{ project_id }}",
        "inviter_id": "{{ inviter_id }}",
        "actions": [
            {"text": "Accept", "action": "accept_invite"},
            {"text": "Decline", "action": "decline_invite"}
        ]
    }
}
```

## Advanced Templates

### 1. Conditional Content

```python
{
    "name": "task_status_update",
    "channel": "email",
    "subject": "Task Update: {{ task_title }}",
    "body_html": """
<h2>Task Update</h2>
<p>Hello {{ user_name }},</p>

{% if status == 'completed' %}
    <p style="color: green;">✓ Task completed successfully!</p>
{% elif status == 'overdue' %}
    <p style="color: red;">⚠️ Task is now overdue.</p>
{% else %}
    <p>Task status updated to: {{ status }}</p>
{% endif %}

<p><strong>Task:</strong> {{ task_title }}</p>
<p><strong>Due Date:</strong> {{ due_date }}</p>

{% if comments %}
<h3>Recent Comments:</h3>
<ul>
{% for comment in comments %}
    <li>{{ comment.author }}: {{ comment.text }}</li>
{% endfor %}
</ul>
{% endif %}
    """
}
```

### 2. Personalized Recommendations

```python
{
    "name": "personalized_recommendations",
    "channel": "email",
    "subject": "Tasks you might like",
    "body_html": """
<h2>Recommended for You</h2>
<p>Hello {{ user_name }},</p>
<p>Based on your activity, here are some tasks we think you'll find useful:</p>

{% for task in recommended_tasks %}
<div style="border: 1px solid #ddd; padding: 15px; margin: 10px 0;">
    <h3>{{ task.title }}</h3>
    <p>{{ task.description }}</p>
    <p><strong>Category:</strong> {{ task.category }}</p>
    <p><strong>Estimated Time:</strong> {{ task.estimated_time }}</p>
    <a href="{{ task.url }}">View Task</a>
</div>
{% endfor %}
    """
}
```

### 3. Multi-Language Support

```python
{
    "name": "task_reminder_i18n",
    "channel": "email",
    "subject": "{% if locale == 'es' %}Recordatorio: {{ task_title }}{% else %}Reminder: {{ task_title }}{% endif %}",
    "body_text": """
{% if locale == 'es' %}
Hola {{ user_name }},

Este es un recordatorio de que tu tarea "{{ task_title }}" vence el {{ due_date }}.

Ver tarea: {{ task_url }}
{% else %}
Hello {{ user_name }},

This is a reminder that your task "{{ task_title }}" is due on {{ due_date }}.

View task: {{ task_url }}
{% endif %}
    """
}
```

## Template Best Practices

### 1. Keep It Concise

```python
# ❌ Too verbose
"Your task titled '{{ task_title }}' which you created on {{ created_date }} is scheduled to be due on {{ due_date }} at {{ due_time }}"

# ✅ Concise
"'{{ task_title }}' is due {{ due_date }}"
```

### 2. Use Clear CTAs

```python
# ❌ Unclear
"Click here for more information about this"

# ✅ Clear
"View Task Details"
```

### 3. Mobile-Friendly

```python
# Email template with responsive design
"""
<style>
    @media only screen and (max-width: 600px) {
        .container { width: 100% !important; }
        .button { display: block !important; width: 100% !important; }
    }
</style>
"""
```

### 4. Test Variables

```python
# Always provide default values
"Hello {{ user_name|default('there') }}"

# Handle missing data gracefully
"{% if task_description %}Description: {{ task_description }}{% endif %}"
```

### 5. Unsubscribe Links

```python
# Always include unsubscribe for marketing emails
"""
<p style="font-size: 12px; color: #666;">
    Don't want to receive these emails?
    <a href="{{ unsubscribe_url }}">Unsubscribe</a>
</p>
"""
```

## Testing Templates

```python
from notification_templates import TemplateManager
from notification_model import NotificationChannel

# Create template manager
template_manager = TemplateManager()

# Test data
test_data = {
    "user_name": "John Doe",
    "task_title": "Complete project",
    "due_date": "2024-01-10",
    "task_url": "https://app.example.com/tasks/123"
}

# Render template
content = template_manager.render(
    template_name="task_reminder",
    channel=NotificationChannel.EMAIL,
    data=test_data
)

print("Subject:", content['subject'])
print("Text:", content['text'])
print("HTML:", content['html'])
```

## Template Variables Reference

### Common Variables

- `user_name`: User's display name
- `user_email`: User's email address
- `app_name`: Application name
- `base_url`: Application base URL
- `support_email`: Support email address
- `unsubscribe_url`: Unsubscribe link

### Task Variables

- `task_id`: Task ID
- `task_title`: Task title
- `task_description`: Task description
- `task_url`: Link to task
- `due_date`: Due date
- `priority`: Task priority
- `status`: Task status
- `assigned_to`: Assigned user

### Time Variables

- `date`: Current date
- `time`: Current time
- `datetime`: Current datetime
- `time_until_due`: Time remaining until due
- `days_overdue`: Days overdue

### Statistics Variables

- `tasks_due_today`: Count of tasks due today
- `tasks_completed`: Count of completed tasks
- `tasks_overdue`: Count of overdue tasks
- `completion_rate`: Completion percentage
