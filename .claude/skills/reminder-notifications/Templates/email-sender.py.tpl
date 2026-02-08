"""
Email Notification Sender

This module provides email sending functionality with multiple provider support.
"""

import os
import logging
from typing import Optional, Dict, Any, List
from enum import Enum
from dataclasses import dataclass
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

logger = logging.getLogger(__name__)


class EmailProvider(str, Enum):
    """Supported email providers."""
    SMTP = "smtp"
    SENDGRID = "sendgrid"
    AWS_SES = "aws_ses"
    MAILGUN = "mailgun"
    POSTMARK = "postmark"


@dataclass
class EmailMessage:
    """Email message data."""
    to_email: str
    subject: str
    html_content: str
    text_content: Optional[str] = None
    from_email: Optional[str] = None
    from_name: Optional[str] = None
    reply_to: Optional[str] = None
    cc: Optional[List[str]] = None
    bcc: Optional[List[str]] = None
    attachments: Optional[List[Dict[str, Any]]] = None
    headers: Optional[Dict[str, str]] = None


class EmailSender:
    """Base email sender class."""

    def __init__(
        self,
        provider: EmailProvider,
        from_email: str,
        from_name: Optional[str] = None,
        **kwargs
    ):
        self.provider = provider
        self.from_email = from_email
        self.from_name = from_name
        self.config = kwargs

    def send(self, message: EmailMessage) -> Dict[str, Any]:
        """Send email message."""
        raise NotImplementedError("Subclass must implement send()")

    def send_batch(self, messages: List[EmailMessage]) -> List[Dict[str, Any]]:
        """Send multiple emails."""
        results = []
        for message in messages:
            try:
                result = self.send(message)
                results.append(result)
            except Exception as e:
                logger.error(f"Failed to send email to {message.to_email}: {e}")
                results.append({"success": False, "error": str(e)})
        return results


class SMTPEmailSender(EmailSender):
    """SMTP email sender."""

    def __init__(
        self,
        from_email: str,
        smtp_host: str,
        smtp_port: int = 587,
        smtp_username: Optional[str] = None,
        smtp_password: Optional[str] = None,
        use_tls: bool = True,
        **kwargs
    ):
        super().__init__(EmailProvider.SMTP, from_email, **kwargs)
        self.smtp_host = smtp_host
        self.smtp_port = smtp_port
        self.smtp_username = smtp_username
        self.smtp_password = smtp_password
        self.use_tls = use_tls

    def send(self, message: EmailMessage) -> Dict[str, Any]:
        """Send email via SMTP."""
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['Subject'] = message.subject
            msg['From'] = f"{self.from_name} <{self.from_email}>" if self.from_name else self.from_email
            msg['To'] = message.to_email

            if message.reply_to:
                msg['Reply-To'] = message.reply_to

            if message.cc:
                msg['Cc'] = ', '.join(message.cc)

            if message.headers:
                for key, value in message.headers.items():
                    msg[key] = value

            # Add text and HTML parts
            if message.text_content:
                text_part = MIMEText(message.text_content, 'plain')
                msg.attach(text_part)

            html_part = MIMEText(message.html_content, 'html')
            msg.attach(html_part)

            # Add attachments
            if message.attachments:
                for attachment in message.attachments:
                    part = MIMEBase('application', 'octet-stream')
                    part.set_payload(attachment['content'])
                    encoders.encode_base64(part)
                    part.add_header(
                        'Content-Disposition',
                        f'attachment; filename={attachment["filename"]}'
                    )
                    msg.attach(part)

            # Send email
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                if self.use_tls:
                    server.starttls()

                if self.smtp_username and self.smtp_password:
                    server.login(self.smtp_username, self.smtp_password)

                recipients = [message.to_email]
                if message.cc:
                    recipients.extend(message.cc)
                if message.bcc:
                    recipients.extend(message.bcc)

                server.sendmail(self.from_email, recipients, msg.as_string())

            logger.info(f"Email sent successfully to {message.to_email}")
            return {"success": True, "message_id": None}

        except Exception as e:
            logger.error(f"Failed to send email via SMTP: {e}")
            raise


class SendGridEmailSender(EmailSender):
    """SendGrid email sender."""

    def __init__(self, from_email: str, api_key: str, **kwargs):
        super().__init__(EmailProvider.SENDGRID, from_email, **kwargs)
        self.api_key = api_key

        try:
            from sendgrid import SendGridAPIClient
            from sendgrid.helpers.mail import Mail, Email, To, Content
            self.sg_client = SendGridAPIClient(api_key)
            self.Mail = Mail
            self.Email = Email
            self.To = To
            self.Content = Content
        except ImportError:
            raise ImportError("sendgrid package not installed. Install with: pip install sendgrid")

    def send(self, message: EmailMessage) -> Dict[str, Any]:
        """Send email via SendGrid."""
        try:
            # Create message
            from_email = self.Email(message.from_email or self.from_email, self.from_name)
            to_email = self.To(message.to_email)
            subject = message.subject
            content = self.Content("text/html", message.html_content)

            mail = self.Mail(from_email, to_email, subject, content)

            # Add text content
            if message.text_content:
                mail.add_content(self.Content("text/plain", message.text_content))

            # Add reply-to
            if message.reply_to:
                mail.reply_to = self.Email(message.reply_to)

            # Add CC
            if message.cc:
                for cc_email in message.cc:
                    mail.add_cc(self.Email(cc_email))

            # Add BCC
            if message.bcc:
                for bcc_email in message.bcc:
                    mail.add_bcc(self.Email(bcc_email))

            # Add custom headers
            if message.headers:
                for key, value in message.headers.items():
                    mail.add_header(key, value)

            # Send
            response = self.sg_client.send(mail)

            logger.info(f"Email sent via SendGrid to {message.to_email}")
            return {
                "success": response.status_code == 202,
                "message_id": response.headers.get('X-Message-Id'),
                "status_code": response.status_code
            }

        except Exception as e:
            logger.error(f"Failed to send email via SendGrid: {e}")
            raise


class AWSEmailSender(EmailSender):
    """AWS SES email sender."""

    def __init__(
        self,
        from_email: str,
        region_name: str = 'us-east-1',
        aws_access_key_id: Optional[str] = None,
        aws_secret_access_key: Optional[str] = None,
        **kwargs
    ):
        super().__init__(EmailProvider.AWS_SES, from_email, **kwargs)
        self.region_name = region_name

        try:
            import boto3
            self.ses_client = boto3.client(
                'ses',
                region_name=region_name,
                aws_access_key_id=aws_access_key_id,
                aws_secret_access_key=aws_secret_access_key
            )
        except ImportError:
            raise ImportError("boto3 package not installed. Install with: pip install boto3")

    def send(self, message: EmailMessage) -> Dict[str, Any]:
        """Send email via AWS SES."""
        try:
            # Prepare destination
            destination = {'ToAddresses': [message.to_email]}

            if message.cc:
                destination['CcAddresses'] = message.cc

            if message.bcc:
                destination['BccAddresses'] = message.bcc

            # Prepare message
            email_message = {
                'Subject': {'Data': message.subject, 'Charset': 'UTF-8'},
                'Body': {
                    'Html': {'Data': message.html_content, 'Charset': 'UTF-8'}
                }
            }

            if message.text_content:
                email_message['Body']['Text'] = {
                    'Data': message.text_content,
                    'Charset': 'UTF-8'
                }

            # Send
            response = self.ses_client.send_email(
                Source=f"{self.from_name} <{self.from_email}>" if self.from_name else self.from_email,
                Destination=destination,
                Message=email_message,
                ReplyToAddresses=[message.reply_to] if message.reply_to else []
            )

            logger.info(f"Email sent via AWS SES to {message.to_email}")
            return {
                "success": True,
                "message_id": response['MessageId']
            }

        except Exception as e:
            logger.error(f"Failed to send email via AWS SES: {e}")
            raise


class MailgunEmailSender(EmailSender):
    """Mailgun email sender."""

    def __init__(
        self,
        from_email: str,
        api_key: str,
        domain: str,
        **kwargs
    ):
        super().__init__(EmailProvider.MAILGUN, from_email, **kwargs)
        self.api_key = api_key
        self.domain = domain
        self.base_url = f"https://api.mailgun.net/v3/{domain}"

    def send(self, message: EmailMessage) -> Dict[str, Any]:
        """Send email via Mailgun."""
        try:
            import requests

            # Prepare data
            data = {
                'from': f"{self.from_name} <{self.from_email}>" if self.from_name else self.from_email,
                'to': message.to_email,
                'subject': message.subject,
                'html': message.html_content
            }

            if message.text_content:
                data['text'] = message.text_content

            if message.reply_to:
                data['h:Reply-To'] = message.reply_to

            if message.cc:
                data['cc'] = message.cc

            if message.bcc:
                data['bcc'] = message.bcc

            # Send
            response = requests.post(
                f"{self.base_url}/messages",
                auth=("api", self.api_key),
                data=data
            )

            response.raise_for_status()
            result = response.json()

            logger.info(f"Email sent via Mailgun to {message.to_email}")
            return {
                "success": True,
                "message_id": result.get('id')
            }

        except Exception as e:
            logger.error(f"Failed to send email via Mailgun: {e}")
            raise


def create_email_sender(
    provider: EmailProvider,
    from_email: str,
    **kwargs
) -> EmailSender:
    """Factory function to create email sender."""
    if provider == EmailProvider.SMTP:
        return SMTPEmailSender(from_email, **kwargs)
    elif provider == EmailProvider.SENDGRID:
        return SendGridEmailSender(from_email, **kwargs)
    elif provider == EmailProvider.AWS_SES:
        return AWSEmailSender(from_email, **kwargs)
    elif provider == EmailProvider.MAILGUN:
        return MailgunEmailSender(from_email, **kwargs)
    else:
        raise ValueError(f"Unsupported email provider: {provider}")


# Example usage
if __name__ == "__main__":
    # SMTP example
    smtp_sender = create_email_sender(
        provider=EmailProvider.SMTP,
        from_email="noreply@example.com",
        smtp_host="smtp.gmail.com",
        smtp_port=587,
        smtp_username=os.getenv("SMTP_USERNAME"),
        smtp_password=os.getenv("SMTP_PASSWORD")
    )

    message = EmailMessage(
        to_email="user@example.com",
        subject="Test Email",
        html_content="<h1>Hello World</h1>",
        text_content="Hello World"
    )

    result = smtp_sender.send(message)
    print(f"Email sent: {result}")
