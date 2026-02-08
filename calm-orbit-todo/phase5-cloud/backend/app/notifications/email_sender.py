"""SendGrid email sender for task reminder notifications.

This module provides email notification functionality using SendGrid API
for sending task reminders and other notifications to users.
"""

import logging
from datetime import datetime
from pathlib import Path
from typing import List, Optional

from jinja2 import Environment, FileSystemLoader
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email, To, Content

from app.config import get_settings
from app.models.task import Task

logger = logging.getLogger(__name__)


class EmailSender:
    """SendGrid email sender for task notifications."""

    def __init__(self):
        """Initialize the email sender."""
        self.settings = get_settings()
        self.client = None

        # Initialize SendGrid client if API key is configured
        if self.settings.sendgrid_api_key:
            self.client = SendGridAPIClient(self.settings.sendgrid_api_key)
        else:
            logger.warning("SendGrid API key not configured, email sending disabled")

        # Initialize Jinja2 template environment
        template_dir = Path(__file__).parent.parent / "email_templates"
        self.jinja_env = Environment(loader=FileSystemLoader(str(template_dir)))

    async def send_reminder_email(
        self,
        to_email: str,
        task: Task,
        app_url: str = "https://todo-app.example.com",
    ) -> bool:
        """Send a reminder email for a task.

        Args:
            to_email: Recipient email address.
            task: Task to send reminder for.
            app_url: Base URL of the application.

        Returns:
            True if email sent successfully, False otherwise.
        """
        if not self.client:
            logger.warning("SendGrid client not initialized, skipping email")
            return False

        try:
            # Render email template
            template = self.jinja_env.get_template("reminder.html")

            # Format due date for display
            due_date_str = None
            if task.due_date:
                due_date_str = task.due_date.strftime("%B %d, %Y at %I:%M %p UTC")

            html_content = template.render(
                task_id=str(task.id),
                task_title=task.title,
                task_description=task.description,
                due_date=due_date_str,
                priority=task.priority.value,
                tags=task.tags,
                app_url=app_url,
            )

            # Create email message
            from_email = Email(
                self.settings.sendgrid_from_email,
                self.settings.sendgrid_from_name,
            )
            to_email_obj = To(to_email)
            subject = f"⏰ Reminder: {task.title}"
            content = Content("text/html", html_content)

            mail = Mail(from_email, to_email_obj, subject, content)

            # Send email
            response = self.client.send(mail)

            if response.status_code in [200, 201, 202]:
                logger.info(f"Reminder email sent to {to_email} for task {task.id}")
                return True
            else:
                logger.error(
                    f"Failed to send reminder email: status={response.status_code}, "
                    f"body={response.body}"
                )
                return False

        except Exception as e:
            logger.error(f"Error sending reminder email: {e}", exc_info=True)
            return False

    async def send_overdue_notification(
        self,
        to_email: str,
        tasks: List[Task],
        app_url: str = "https://todo-app.example.com",
    ) -> bool:
        """Send an overdue tasks notification email.

        Args:
            to_email: Recipient email address.
            tasks: List of overdue tasks.
            app_url: Base URL of the application.

        Returns:
            True if email sent successfully, False otherwise.
        """
        if not self.client:
            logger.warning("SendGrid client not initialized, skipping email")
            return False

        if not tasks:
            return True  # Nothing to send

        try:
            # Build email content
            task_list = "\n".join(
                [
                    f"• {task.title} (Due: {task.due_date.strftime('%B %d, %Y') if task.due_date else 'N/A'})"
                    for task in tasks
                ]
            )

            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background-color: #dc2626; color: white; padding: 20px; text-align: center; }}
                    .content {{ padding: 20px; background-color: #f9fafb; }}
                    .task-list {{ background-color: white; padding: 15px; margin: 15px 0; border-left: 4px solid #dc2626; }}
                    .cta-button {{ display: inline-block; background-color: #2563eb; color: white;
                                   text-decoration: none; padding: 12px 24px; border-radius: 6px; margin: 20px 0; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>⚠️ Overdue Tasks</h1>
                        <p>You have {len(tasks)} overdue task(s)</p>
                    </div>
                    <div class="content">
                        <p>The following tasks are past their due date:</p>
                        <div class="task-list">
                            <pre>{task_list}</pre>
                        </div>
                        <div style="text-align: center;">
                            <a href="{app_url}/tasks?filter=overdue" class="cta-button">View Overdue Tasks</a>
                        </div>
                    </div>
                </div>
            </body>
            </html>
            """

            # Create email message
            from_email = Email(
                self.settings.sendgrid_from_email,
                self.settings.sendgrid_from_name,
            )
            to_email_obj = To(to_email)
            subject = f"⚠️ You have {len(tasks)} overdue task(s)"
            content = Content("text/html", html_content)

            mail = Mail(from_email, to_email_obj, subject, content)

            # Send email
            response = self.client.send(mail)

            if response.status_code in [200, 201, 202]:
                logger.info(f"Overdue notification sent to {to_email}")
                return True
            else:
                logger.error(
                    f"Failed to send overdue notification: status={response.status_code}"
                )
                return False

        except Exception as e:
            logger.error(f"Error sending overdue notification: {e}", exc_info=True)
            return False

    async def send_daily_summary(
        self,
        to_email: str,
        tasks_due_today: List[Task],
        tasks_due_this_week: List[Task],
        overdue_tasks: List[Task],
        app_url: str = "https://todo-app.example.com",
    ) -> bool:
        """Send a daily summary email.

        Args:
            to_email: Recipient email address.
            tasks_due_today: Tasks due today.
            tasks_due_this_week: Tasks due this week.
            overdue_tasks: Overdue tasks.
            app_url: Base URL of the application.

        Returns:
            True if email sent successfully, False otherwise.
        """
        if not self.client:
            logger.warning("SendGrid client not initialized, skipping email")
            return False

        try:
            # Build summary content
            html_content = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <style>
                    body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                    .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                    .header {{ background-color: #2563eb; color: white; padding: 20px; text-align: center; }}
                    .section {{ padding: 15px; margin: 15px 0; background-color: #f9fafb; border-radius: 8px; }}
                    .section h3 {{ margin-top: 0; color: #1f2937; }}
                    .count {{ font-size: 24px; font-weight: bold; color: #2563eb; }}
                    .cta-button {{ display: inline-block; background-color: #2563eb; color: white;
                                   text-decoration: none; padding: 12px 24px; border-radius: 6px; margin: 20px 0; }}
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="header">
                        <h1>📊 Daily Task Summary</h1>
                        <p>{datetime.utcnow().strftime("%B %d, %Y")}</p>
                    </div>

                    <div class="section">
                        <h3>📅 Due Today</h3>
                        <p class="count">{len(tasks_due_today)}</p>
                        <p>task(s) due today</p>
                    </div>

                    <div class="section">
                        <h3>📆 Due This Week</h3>
                        <p class="count">{len(tasks_due_this_week)}</p>
                        <p>task(s) due in the next 7 days</p>
                    </div>

                    <div class="section">
                        <h3>⚠️ Overdue</h3>
                        <p class="count">{len(overdue_tasks)}</p>
                        <p>task(s) past their due date</p>
                    </div>

                    <div style="text-align: center;">
                        <a href="{app_url}/tasks" class="cta-button">View All Tasks</a>
                    </div>
                </div>
            </body>
            </html>
            """

            # Create email message
            from_email = Email(
                self.settings.sendgrid_from_email,
                self.settings.sendgrid_from_name,
            )
            to_email_obj = To(to_email)
            subject = f"📊 Daily Task Summary - {datetime.utcnow().strftime('%B %d, %Y')}"
            content = Content("text/html", html_content)

            mail = Mail(from_email, to_email_obj, subject, content)

            # Send email
            response = self.client.send(mail)

            if response.status_code in [200, 201, 202]:
                logger.info(f"Daily summary sent to {to_email}")
                return True
            else:
                logger.error(
                    f"Failed to send daily summary: status={response.status_code}"
                )
                return False

        except Exception as e:
            logger.error(f"Error sending daily summary: {e}", exc_info=True)
            return False


# Global email sender instance
_email_sender: Optional[EmailSender] = None


def get_email_sender() -> EmailSender:
    """Get or create the global email sender instance.

    Returns:
        EmailSender instance.
    """
    global _email_sender
    if _email_sender is None:
        _email_sender = EmailSender()
    return _email_sender
