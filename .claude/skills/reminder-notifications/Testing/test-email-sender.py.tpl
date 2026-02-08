"""
Unit Tests for Email Sender

This module provides comprehensive tests for email sending functionality.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from email_sender import (
    EmailSender,
    EmailMessage,
    SMTPEmailSender,
    SendGridEmailSender,
    AWSEmailSender,
    MailgunEmailSender,
    create_email_sender,
    EmailProvider
)


class TestEmailMessage:
    """Test EmailMessage data class."""

    def test_create_basic_message(self):
        """Test creating basic email message."""
        message = EmailMessage(
            to_email="user@example.com",
            subject="Test Subject",
            html_content="<h1>Test</h1>"
        )

        assert message.to_email == "user@example.com"
        assert message.subject == "Test Subject"
        assert message.html_content == "<h1>Test</h1>"
        assert message.text_content is None

    def test_create_full_message(self):
        """Test creating email with all fields."""
        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>",
            text_content="Test",
            from_email="sender@example.com",
            from_name="Sender",
            reply_to="reply@example.com",
            cc=["cc@example.com"],
            bcc=["bcc@example.com"],
            attachments=[{"filename": "test.pdf", "content": b"data"}],
            headers={"X-Custom": "value"}
        )

        assert message.from_email == "sender@example.com"
        assert message.from_name == "Sender"
        assert message.reply_to == "reply@example.com"
        assert len(message.cc) == 1
        assert len(message.bcc) == 1
        assert len(message.attachments) == 1
        assert message.headers["X-Custom"] == "value"


class TestSMTPEmailSender:
    """Test SMTP email sender."""

    @pytest.fixture
    def smtp_sender(self):
        """Create SMTP sender for testing."""
        return SMTPEmailSender(
            from_email="noreply@example.com",
            smtp_host="smtp.example.com",
            smtp_port=587,
            smtp_username="user",
            smtp_password="pass",
            use_tls=True
        )

    def test_smtp_sender_initialization(self, smtp_sender):
        """Test SMTP sender initialization."""
        assert smtp_sender.from_email == "noreply@example.com"
        assert smtp_sender.smtp_host == "smtp.example.com"
        assert smtp_sender.smtp_port == 587
        assert smtp_sender.use_tls is True

    @patch('email_sender.smtplib.SMTP')
    def test_send_basic_email(self, mock_smtp, smtp_sender):
        """Test sending basic email via SMTP."""
        # Mock SMTP server
        mock_server = MagicMock()
        mock_smtp.return_value.__enter__.return_value = mock_server

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>"
        )

        result = smtp_sender.send(message)

        assert result["success"] is True
        mock_server.starttls.assert_called_once()
        mock_server.login.assert_called_once_with("user", "pass")
        mock_server.sendmail.assert_called_once()

    @patch('email_sender.smtplib.SMTP')
    def test_send_with_attachments(self, mock_smtp, smtp_sender):
        """Test sending email with attachments."""
        mock_server = MagicMock()
        mock_smtp.return_value.__enter__.return_value = mock_server

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>",
            attachments=[
                {"filename": "test.pdf", "content": b"PDF content"}
            ]
        )

        result = smtp_sender.send(message)

        assert result["success"] is True
        mock_server.sendmail.assert_called_once()

    @patch('email_sender.smtplib.SMTP')
    def test_send_with_cc_bcc(self, mock_smtp, smtp_sender):
        """Test sending email with CC and BCC."""
        mock_server = MagicMock()
        mock_smtp.return_value.__enter__.return_value = mock_server

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>",
            cc=["cc@example.com"],
            bcc=["bcc@example.com"]
        )

        result = smtp_sender.send(message)

        assert result["success"] is True
        # Verify all recipients included
        call_args = mock_server.sendmail.call_args
        recipients = call_args[0][1]
        assert "user@example.com" in recipients
        assert "cc@example.com" in recipients
        assert "bcc@example.com" in recipients

    @patch('email_sender.smtplib.SMTP')
    def test_send_failure(self, mock_smtp, smtp_sender):
        """Test handling SMTP send failure."""
        mock_smtp.return_value.__enter__.side_effect = Exception("SMTP error")

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>"
        )

        with pytest.raises(Exception, match="SMTP error"):
            smtp_sender.send(message)


class TestSendGridEmailSender:
    """Test SendGrid email sender."""

    @pytest.fixture
    def sendgrid_sender(self):
        """Create SendGrid sender for testing."""
        with patch('email_sender.SendGridAPIClient'):
            return SendGridEmailSender(
                from_email="noreply@example.com",
                api_key="test_api_key"
            )

    def test_sendgrid_initialization(self, sendgrid_sender):
        """Test SendGrid sender initialization."""
        assert sendgrid_sender.from_email == "noreply@example.com"
        assert sendgrid_sender.api_key == "test_api_key"

    def test_send_basic_email(self, sendgrid_sender):
        """Test sending email via SendGrid."""
        # Mock SendGrid client
        mock_response = Mock()
        mock_response.status_code = 202
        mock_response.headers = {'X-Message-Id': 'msg_123'}

        sendgrid_sender.sg_client.send = Mock(return_value=mock_response)

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>"
        )

        result = sendgrid_sender.send(message)

        assert result["success"] is True
        assert result["message_id"] == "msg_123"
        assert result["status_code"] == 202

    def test_send_with_reply_to(self, sendgrid_sender):
        """Test sending email with reply-to."""
        mock_response = Mock()
        mock_response.status_code = 202
        mock_response.headers = {'X-Message-Id': 'msg_123'}

        sendgrid_sender.sg_client.send = Mock(return_value=mock_response)

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>",
            reply_to="reply@example.com"
        )

        result = sendgrid_sender.send(message)

        assert result["success"] is True

    def test_send_failure(self, sendgrid_sender):
        """Test handling SendGrid send failure."""
        sendgrid_sender.sg_client.send = Mock(side_effect=Exception("API error"))

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>"
        )

        with pytest.raises(Exception, match="API error"):
            sendgrid_sender.send(message)


class TestAWSEmailSender:
    """Test AWS SES email sender."""

    @pytest.fixture
    def aws_sender(self):
        """Create AWS SES sender for testing."""
        with patch('email_sender.boto3'):
            return AWSEmailSender(
                from_email="noreply@example.com",
                region_name="us-east-1"
            )

    def test_aws_initialization(self, aws_sender):
        """Test AWS SES sender initialization."""
        assert aws_sender.from_email == "noreply@example.com"
        assert aws_sender.region_name == "us-east-1"

    def test_send_basic_email(self, aws_sender):
        """Test sending email via AWS SES."""
        # Mock SES client
        aws_sender.ses_client.send_email = Mock(
            return_value={'MessageId': 'msg_123'}
        )

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>"
        )

        result = aws_sender.send(message)

        assert result["success"] is True
        assert result["message_id"] == "msg_123"

    def test_send_with_text_content(self, aws_sender):
        """Test sending email with text content."""
        aws_sender.ses_client.send_email = Mock(
            return_value={'MessageId': 'msg_123'}
        )

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>",
            text_content="Test"
        )

        result = aws_sender.send(message)

        assert result["success"] is True

        # Verify text content was included
        call_args = aws_sender.ses_client.send_email.call_args
        assert 'Text' in call_args[1]['Message']['Body']


class TestMailgunEmailSender:
    """Test Mailgun email sender."""

    @pytest.fixture
    def mailgun_sender(self):
        """Create Mailgun sender for testing."""
        return MailgunEmailSender(
            from_email="noreply@example.com",
            api_key="test_api_key",
            domain="example.com"
        )

    def test_mailgun_initialization(self, mailgun_sender):
        """Test Mailgun sender initialization."""
        assert mailgun_sender.from_email == "noreply@example.com"
        assert mailgun_sender.api_key == "test_api_key"
        assert mailgun_sender.domain == "example.com"

    @patch('email_sender.requests.post')
    def test_send_basic_email(self, mock_post, mailgun_sender):
        """Test sending email via Mailgun."""
        # Mock response
        mock_response = Mock()
        mock_response.json.return_value = {'id': 'msg_123'}
        mock_post.return_value = mock_response

        message = EmailMessage(
            to_email="user@example.com",
            subject="Test",
            html_content="<h1>Test</h1>"
        )

        result = mailgun_sender.send(message)

        assert result["success"] is True
        assert result["message_id"] == "msg_123"

        # Verify API call
        mock_post.assert_called_once()
        call_args = mock_post.call_args
        assert call_args[1]['auth'] == ("api", "test_api_key")


class TestEmailSenderFactory:
    """Test email sender factory."""

    def test_create_smtp_sender(self):
        """Test creating SMTP sender."""
        sender = create_email_sender(
            provider=EmailProvider.SMTP,
            from_email="test@example.com",
            smtp_host="smtp.example.com",
            smtp_port=587
        )

        assert isinstance(sender, SMTPEmailSender)
        assert sender.from_email == "test@example.com"

    def test_create_sendgrid_sender(self):
        """Test creating SendGrid sender."""
        with patch('email_sender.SendGridAPIClient'):
            sender = create_email_sender(
                provider=EmailProvider.SENDGRID,
                from_email="test@example.com",
                api_key="test_key"
            )

            assert isinstance(sender, SendGridEmailSender)

    def test_create_aws_sender(self):
        """Test creating AWS SES sender."""
        with patch('email_sender.boto3'):
            sender = create_email_sender(
                provider=EmailProvider.AWS_SES,
                from_email="test@example.com",
                region_name="us-east-1"
            )

            assert isinstance(sender, AWSEmailSender)

    def test_create_mailgun_sender(self):
        """Test creating Mailgun sender."""
        sender = create_email_sender(
            provider=EmailProvider.MAILGUN,
            from_email="test@example.com",
            api_key="test_key",
            domain="example.com"
        )

        assert isinstance(sender, MailgunEmailSender)

    def test_unsupported_provider(self):
        """Test creating sender with unsupported provider."""
        with pytest.raises(ValueError, match="Unsupported email provider"):
            create_email_sender(
                provider="unsupported",
                from_email="test@example.com"
            )


class TestBatchSending:
    """Test batch email sending."""

    @pytest.fixture
    def smtp_sender(self):
        """Create SMTP sender for testing."""
        return SMTPEmailSender(
            from_email="noreply@example.com",
            smtp_host="smtp.example.com",
            smtp_port=587
        )

    @patch('email_sender.smtplib.SMTP')
    def test_send_batch(self, mock_smtp, smtp_sender):
        """Test sending batch of emails."""
        mock_server = MagicMock()
        mock_smtp.return_value.__enter__.return_value = mock_server

        messages = [
            EmailMessage(
                to_email=f"user{i}@example.com",
                subject="Test",
                html_content="<h1>Test</h1>"
            )
            for i in range(5)
        ]

        results = smtp_sender.send_batch(messages)

        assert len(results) == 5
        assert all(r["success"] for r in results)
        assert mock_server.sendmail.call_count == 5

    @patch('email_sender.smtplib.SMTP')
    def test_send_batch_with_failures(self, mock_smtp, smtp_sender):
        """Test batch sending with some failures."""
        mock_server = MagicMock()
        mock_smtp.return_value.__enter__.return_value = mock_server

        # Make every other send fail
        mock_server.sendmail.side_effect = [
            None,
            Exception("Failed"),
            None,
            Exception("Failed"),
            None
        ]

        messages = [
            EmailMessage(
                to_email=f"user{i}@example.com",
                subject="Test",
                html_content="<h1>Test</h1>"
            )
            for i in range(5)
        ]

        results = smtp_sender.send_batch(messages)

        assert len(results) == 5
        assert sum(1 for r in results if r["success"]) == 3
        assert sum(1 for r in results if not r["success"]) == 2


# Integration tests
@pytest.mark.integration
class TestEmailSenderIntegration:
    """Integration tests with real email providers."""

    @pytest.mark.skipif(
        not pytest.config.getoption("--run-integration"),
        reason="Integration tests disabled"
    )
    def test_send_real_email_smtp(self):
        """Test sending real email via SMTP."""
        import os

        sender = SMTPEmailSender(
            from_email=os.getenv("SMTP_FROM_EMAIL"),
            smtp_host=os.getenv("SMTP_HOST"),
            smtp_port=int(os.getenv("SMTP_PORT", "587")),
            smtp_username=os.getenv("SMTP_USERNAME"),
            smtp_password=os.getenv("SMTP_PASSWORD")
        )

        message = EmailMessage(
            to_email=os.getenv("TEST_EMAIL"),
            subject="Test Email from Integration Test",
            html_content="<h1>This is a test email</h1>",
            text_content="This is a test email"
        )

        result = sender.send(message)

        assert result["success"] is True


# Pytest configuration
def pytest_addoption(parser):
    """Add custom pytest options."""
    parser.addoption(
        "--run-integration",
        action="store_true",
        default=False,
        help="Run integration tests"
    )


# Run tests
if __name__ == "__main__":
    pytest.main([__file__, "-v"])
