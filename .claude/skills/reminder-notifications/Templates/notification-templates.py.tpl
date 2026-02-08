"""
Notification Template Manager

This module provides template management and rendering for notifications.
"""

import logging
from typing import Dict, Any, Optional
from jinja2 import Environment, BaseLoader, TemplateNotFound
from sqlmodel import Session, select
from notification_model import NotificationTemplate, NotificationChannel

logger = logging.getLogger(__name__)


class TemplateManager:
    """Manage and render notification templates."""

    def __init__(self, session_factory=None):
        self.session_factory = session_factory
        self.jinja_env = Environment(loader=BaseLoader())
        self._template_cache = {}

    def render(
        self,
        template_name: str,
        channel: NotificationChannel,
        data: Dict[str, Any]
    ) -> Dict[str, str]:
        """Render template with data."""
        try:
            # Get template
            template = self._get_template(template_name, channel)

            if not template:
                raise ValueError(f"Template {template_name} not found for channel {channel}")

            # Render based on channel
            if channel == NotificationChannel.EMAIL:
                return self._render_email(template, data)
            elif channel == NotificationChannel.SMS:
                return self._render_sms(template, data)
            elif channel == NotificationChannel.PUSH:
                return self._render_push(template, data)
            elif channel == NotificationChannel.IN_APP:
                return self._render_in_app(template, data)
            else:
                raise ValueError(f"Unsupported channel: {channel}")

        except Exception as e:
            logger.error(f"Failed to render template {template_name}: {e}")
            raise

    def _render_email(self, template: NotificationTemplate, data: Dict[str, Any]) -> Dict[str, str]:
        """Render email template."""
        subject_template = self.jinja_env.from_string(template.subject or "")
        text_template = self.jinja_env.from_string(template.body_text)
        html_template = self.jinja_env.from_string(template.body_html or template.body_text)

        return {
            "subject": subject_template.render(**data),
            "text": text_template.render(**data),
            "html": html_template.render(**data)
        }

    def _render_sms(self, template: NotificationTemplate, data: Dict[str, Any]) -> Dict[str, str]:
        """Render SMS template."""
        text_template = self.jinja_env.from_string(template.body_text)

        return {
            "text": text_template.render(**data)
        }

    def _render_push(self, template: NotificationTemplate, data: Dict[str, Any]) -> Dict[str, str]:
        """Render push notification template."""
        title_template = self.jinja_env.from_string(template.title or "")
        body_template = self.jinja_env.from_string(template.body_text)

        result = {
            "title": title_template.render(**data),
            "body": body_template.render(**data)
        }

        # Add click action if present in data
        if "click_action" in data:
            result["click_action"] = data["click_action"]

        return result

    def _render_in_app(self, template: NotificationTemplate, data: Dict[str, Any]) -> Dict[str, str]:
        """Render in-app notification template."""
        title_template = self.jinja_env.from_string(template.title or "")
        body_template = self.jinja_env.from_string(template.body_text)

        return {
            "title": title_template.render(**data),
            "body": body_template.render(**data),
            "data": data
        }

    def _get_template(self, name: str, channel: NotificationChannel) -> Optional[NotificationTemplate]:
        """Get template from cache or database."""
        cache_key = f"{name}:{channel}"

        # Check cache
        if cache_key in self._template_cache:
            return self._template_cache[cache_key]

        # Load from database
        if self.session_factory:
            with self.session_factory() as session:
                template = session.exec(
                    select(NotificationTemplate)
                    .where(NotificationTemplate.name == name)
                    .where(NotificationTemplate.channel == channel)
                    .where(NotificationTemplate.is_active == True)
                ).first()

                if template:
                    self._template_cache[cache_key] = template
                    return template

        # Fallback to built-in templates
        return self._get_builtin_template(name, channel)

    def _get_builtin_template(self, name: str, channel: NotificationChannel) -> Optional[NotificationTemplate]:
        """Get built-in template."""
        templates = get_builtin_templates()
        cache_key = f"{name}:{channel}"

        if cache_key in templates:
            return templates[cache_key]

        return None

    def create_template(
        self,
        name: str,
        channel: NotificationChannel,
        body_text: str,
        subject: Optional[str] = None,
        title: Optional[str] = None,
        body_html: Optional[str] = None,
        category: Optional[str] = None,
        description: Optional[str] = None
    ) -> NotificationTemplate:
        """Create new template."""
        if not self.session_factory:
            raise ValueError("Session factory required to create templates")

        with self.session_factory() as session:
            template = NotificationTemplate(
                name=name,
                channel=channel,
                subject=subject,
                title=title,
                body_text=body_text,
                body_html=body_html,
                category=category,
                description=description
            )

            session.add(template)
            session.commit()
            session.refresh(template)

            # Update cache
            cache_key = f"{name}:{channel}"
            self._template_cache[cache_key] = template

            return template

    def update_template(
        self,
        template_id: int,
        **kwargs
    ) -> NotificationTemplate:
        """Update existing template."""
        if not self.session_factory:
            raise ValueError("Session factory required to update templates")

        with self.session_factory() as session:
            template = session.get(NotificationTemplate, template_id)

            if not template:
                raise ValueError(f"Template {template_id} not found")

            for key, value in kwargs.items():
                if hasattr(template, key):
                    setattr(template, key, value)

            session.commit()
            session.refresh(template)

            # Clear cache
            cache_key = f"{template.name}:{template.channel}"
            if cache_key in self._template_cache:
                del self._template_cache[cache_key]

            return template

    def delete_template(self, template_id: int) -> bool:
        """Delete template."""
        if not self.session_factory:
            raise ValueError("Session factory required to delete templates")

        with self.session_factory() as session:
            template = session.get(NotificationTemplate, template_id)

            if not template:
                return False

            # Clear cache
            cache_key = f"{template.name}:{template.channel}"
            if cache_key in self._template_cache:
                del self._template_cache[cache_key]

            session.delete(template)
            session.commit()

            return True

    def clear_cache(self):
        """Clear template cache."""
        self._template_cache.clear()


def get_builtin_templates() -> Dict[str, NotificationTemplate]:
    """Get built-in notification templates."""
    templates = {}

    # Task Reminder - Email
    templates["task_reminder:email"] = NotificationTemplate(
        name="task_reminder",
        channel=NotificationChannel.EMAIL,
        subject="Reminder: {{ task_title }}",
        body_text="""
Hello {{ user_name }},

This is a reminder that your task "{{ task_title }}" is due on {{ due_date }}.

{% if task_description %}
Description: {{ task_description }}
{% endif %}

View task: {{ task_url }}

Best regards,
The Team
        """.strip(),
        body_html="""
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background-color: #f9f9f9; }
        .button { display: inline-block; padding: 10px 20px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>Task Reminder</h2>
        </div>
        <div class="content">
            <p>Hello {{ user_name }},</p>
            <p>This is a reminder that your task <strong>"{{ task_title }}"</strong> is due on <strong>{{ due_date }}</strong>.</p>
            {% if task_description %}
            <p><strong>Description:</strong> {{ task_description }}</p>
            {% endif %}
            <p style="text-align: center; margin-top: 30px;">
                <a href="{{ task_url }}" class="button">View Task</a>
            </p>
        </div>
        <div class="footer">
            <p>You received this email because you have notifications enabled.</p>
        </div>
    </div>
</body>
</html>
        """.strip(),
        category="task_reminders"
    )

    # Task Reminder - SMS
    templates["task_reminder:sms"] = NotificationTemplate(
        name="task_reminder",
        channel=NotificationChannel.SMS,
        body_text="Reminder: Your task '{{ task_title }}' is due on {{ due_date }}. View: {{ task_url }}",
        category="task_reminders"
    )

    # Task Reminder - Push
    templates["task_reminder:push"] = NotificationTemplate(
        name="task_reminder",
        channel=NotificationChannel.PUSH,
        title="Task Reminder",
        body_text="Your task '{{ task_title }}' is due on {{ due_date }}",
        category="task_reminders"
    )

    # Task Reminder - In-App
    templates["task_reminder:in_app"] = NotificationTemplate(
        name="task_reminder",
        channel=NotificationChannel.IN_APP,
        title="Task Reminder",
        body_text="Your task '{{ task_title }}' is due on {{ due_date }}",
        category="task_reminders"
    )

    # Daily Digest - Email
    templates["daily_digest:email"] = NotificationTemplate(
        name="daily_digest",
        channel=NotificationChannel.EMAIL,
        subject="Your Daily Task Summary - {{ date }}",
        body_text="""
Hello {{ user_name }},

Here's your task summary for {{ date }}:

Tasks Due Today: {{ tasks_due_today }}
Tasks Completed: {{ tasks_completed }}
Tasks Overdue: {{ tasks_overdue }}

{% if upcoming_tasks %}
Upcoming Tasks:
{% for task in upcoming_tasks %}
- {{ task.title }} (Due: {{ task.due_date }})
{% endfor %}
{% endif %}

View all tasks: {{ dashboard_url }}

Best regards,
The Team
        """.strip(),
        body_html="""
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #2196F3; color: white; padding: 20px; text-align: center; }
        .stats { display: flex; justify-content: space-around; padding: 20px; }
        .stat { text-align: center; }
        .stat-number { font-size: 32px; font-weight: bold; color: #2196F3; }
        .stat-label { color: #666; }
        .task-list { padding: 20px; }
        .task-item { padding: 10px; border-left: 3px solid #2196F3; margin-bottom: 10px; background-color: #f9f9f9; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>Daily Task Summary</h2>
            <p>{{ date }}</p>
        </div>
        <div class="stats">
            <div class="stat">
                <div class="stat-number">{{ tasks_due_today }}</div>
                <div class="stat-label">Due Today</div>
            </div>
            <div class="stat">
                <div class="stat-number">{{ tasks_completed }}</div>
                <div class="stat-label">Completed</div>
            </div>
            <div class="stat">
                <div class="stat-number">{{ tasks_overdue }}</div>
                <div class="stat-label">Overdue</div>
            </div>
        </div>
        {% if upcoming_tasks %}
        <div class="task-list">
            <h3>Upcoming Tasks</h3>
            {% for task in upcoming_tasks %}
            <div class="task-item">
                <strong>{{ task.title }}</strong><br>
                <small>Due: {{ task.due_date }}</small>
            </div>
            {% endfor %}
        </div>
        {% endif %}
        <p style="text-align: center; margin-top: 30px;">
            <a href="{{ dashboard_url }}" style="display: inline-block; padding: 10px 20px; background-color: #2196F3; color: white; text-decoration: none; border-radius: 5px;">View Dashboard</a>
        </p>
    </div>
</body>
</html>
        """.strip(),
        category="task_updates"
    )

    # OTP Verification - SMS
    templates["otp_verification:sms"] = NotificationTemplate(
        name="otp_verification",
        channel=NotificationChannel.SMS,
        body_text="Your verification code is: {{ otp }}. Valid for {{ validity_minutes }} minutes. Do not share this code.",
        category="system_notifications"
    )

    # Welcome - Email
    templates["welcome:email"] = NotificationTemplate(
        name="welcome",
        channel=NotificationChannel.EMAIL,
        subject="Welcome to {{ app_name }}!",
        body_text="""
Hello {{ user_name }},

Welcome to {{ app_name }}! We're excited to have you on board.

Get started by:
1. Creating your first task
2. Setting up your preferences
3. Exploring our features

If you have any questions, feel free to reach out to our support team.

Best regards,
The {{ app_name }} Team
        """.strip(),
        body_html="""
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #4CAF50; color: white; padding: 30px; text-align: center; }
        .content { padding: 30px; }
        .steps { padding: 20px; }
        .step { padding: 15px; margin-bottom: 10px; background-color: #f9f9f9; border-left: 4px solid #4CAF50; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to {{ app_name }}!</h1>
        </div>
        <div class="content">
            <p>Hello {{ user_name }},</p>
            <p>We're excited to have you on board!</p>
            <div class="steps">
                <h3>Get Started:</h3>
                <div class="step">1. Create your first task</div>
                <div class="step">2. Set up your preferences</div>
                <div class="step">3. Explore our features</div>
            </div>
            <p>If you have any questions, feel free to reach out to our support team.</p>
        </div>
    </div>
</body>
</html>
        """.strip(),
        category="system_notifications"
    )

    return templates


# Example usage
if __name__ == "__main__":
    # Create template manager
    template_manager = TemplateManager()

    # Render task reminder email
    content = template_manager.render(
        template_name="task_reminder",
        channel=NotificationChannel.EMAIL,
        data={
            "user_name": "John Doe",
            "task_title": "Complete project",
            "due_date": "2024-01-10",
            "task_description": "Finish the final report",
            "task_url": "https://app.example.com/tasks/123"
        }
    )

    print("Subject:", content['subject'])
    print("\nText:", content['text'])
    print("\nHTML:", content['html'][:200], "...")
