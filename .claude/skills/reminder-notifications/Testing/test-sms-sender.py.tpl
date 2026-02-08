"""
Unit Tests for SMS Sender

This module provides comprehensive tests for SMS sending functionality.
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from sms_sender import (
    SMSSender,
    SMSMessage,
    TwilioSMSSender,
    AWSSNSSMSSender,
    VonageSMSSender,
    MessageBirdSMSSender,
    create_sms_sender,
    SMSProvider,
    validate_phone_number,
    format_phone_number
)


class TestSMSMessage:
    """Test SMSMessage data class."""

    def test_create_basic_message(self):
        """Test creating basic SMS message."""
        message = SMSMessage(
            to_phone="+1234567890",
            message="Test message"
        )

        assert message.to_phone == "+1234567890"
        assert message.message == "Test message"
        assert message.from_phone is None
        assert message.media_urls is None

    def test_create_mms_message(self):
        """Test creating MMS message with media."""
        message = SMSMessage(
            to_phone="+1234567890",
            message="Check this out!",
            media_urls=["https://example.com/image.jpg"]
        )

        assert len(message.media_urls) == 1
        assert message.media_urls[0] == "https://example.com/image.jpg"


class TestTwilioSMSSender:
    """Test Twilio SMS sender."""

    @pytest.fixture
    def twilio_sender(self):
        """Create Twilio sender for testing."""
        with patch('sms_sender.Client'):
            return TwilioSMSSender(
                from_phone="+1234567890",
                account_sid="test_sid",
                auth_token="test_token"
            )

    def test_twilio_initialization(self, twilio_sender):
        """Test Twilio sender initialization."""
        assert twilio_sender.from_phone == "+1234567890"
        assert twilio_sender.account_sid == "test_sid"
        assert twilio_sender.auth_token == "test_token"

    def test_send_basic_sms(self, twilio_sender):
        """Test sending basic SMS via Twilio."""
        # Mock Twilio message
        mock_message = Mock()
        mock_message.sid = "SM123"
        mock_message.status = "sent"
        mock_message.price = "-0.0075"
        mock_message.price_unit = "USD"

        twilio_sender.client.messages.create = Mock(return_value=mock_message)

        message = SMSMessage(
            to_phone="+1234567890",
            message="Test message"
        )

        result = twilio_sender.send(message)

        assert result["success"] is True
        assert result["message_id"] == "SM123"
        assert result["status"] == "sent"
        assert result["price"] == "-0.0075"

    def test_send_mms(self, twilio_sender):
        """Test sending MMS via Twilio."""
        mock_message = Mock()
        mock_message.sid = "MM123"
        mock_message.status = "sent"

        twilio_sender.client.messages.create = Mock(return_value=mock_message)

        message = SMSMessage(
            to_phone="+1234567890",
            message="Check this out!",
            media_urls=["https://example.com/image.jpg"]
        )

        result = twilio_sender.send(message)

        assert result["success"] is True
        assert result["message_id"] == "MM123"

        # Verify media_url was passed
        call_args = twilio_sender.client.messages.create.call_args
        assert 'media_url' in call_args[1]

    def test_send_failure(self, twilio_sender):
        """Test handling Twilio send failure."""
        twilio_sender.client.messages.create = Mock(
            side_effect=Exception("Twilio error")
        )

        message = SMSMessage(
            to_phone="+1234567890",
            message="Test"
        )

        with pytest.raises(Exception, match="Twilio error"):
            twilio_sender.send(message)

    def test_get_message_status(self, twilio_sender):
        """Test getting message status."""
        mock_message = Mock()
        mock_message.status = "delivered"
        mock_message.error_code = None
        mock_message.error_message = None
        mock_message.date_sent = "2024-01-09"
        mock_message.date_updated = "2024-01-09"

        twilio_sender.client.messages = Mock(return_value=Mock(fetch=Mock(return_value=mock_message)))

        status = twilio_sender.get_message_status("SM123")

        assert status["status"] == "delivered"
        assert status["error_code"] is None


class TestAWSSNSSMSSender:
    """Test AWS SNS SMS sender."""

    @pytest.fixture
    def aws_sender(self):
        """Create AWS SNS sender for testing."""
        with patch('sms_sender.boto3'):
            return AWSSNSSMSSender(
                from_phone="+1234567890",
                region_name="us-east-1"
            )

    def test_aws_initialization(self, aws_sender):
        """Test AWS SNS sender initialization."""
        assert aws_sender.from_phone == "+1234567890"
        assert aws_sender.region_name == "us-east-1"

    def test_send_basic_sms(self, aws_sender):
        """Test sending SMS via AWS SNS."""
        aws_sender.sns_client.publish = Mock(
            return_value={'MessageId': 'msg_123'}
        )

        message = SMSMessage(
            to_phone="+1234567890",
            message="Test message"
        )

        result = aws_sender.send(message)

        assert result["success"] is True
        assert result["message_id"] == "msg_123"

        # Verify SNS publish was called correctly
        call_args = aws_sender.sns_client.publish.call_args
        assert call_args[1]['PhoneNumber'] == "+1234567890"
        assert call_args[1]['Message'] == "Test message"

    def test_send_with_sender_id(self, aws_sender):
        """Test sending SMS with sender ID."""
        aws_sender.sns_client.publish = Mock(
            return_value={'MessageId': 'msg_123'}
        )

        message = SMSMessage(
            to_phone="+1234567890",
            message="Test"
        )

        result = aws_sender.send(message)

        # Verify sender ID was included
        call_args = aws_sender.sns_client.publish.call_args
        assert 'MessageAttributes' in call_args[1]
        assert 'AWS.SNS.SMS.SenderID' in call_args[1]['MessageAttributes']


class TestVonageSMSSender:
    """Test Vonage SMS sender."""

    @pytest.fixture
    def vonage_sender(self):
        """Create Vonage sender for testing."""
        with patch('sms_sender.vonage'):
            return VonageSMSSender(
                from_phone="+1234567890",
                api_key="test_key",
                api_secret="test_secret"
            )

    def test_vonage_initialization(self, vonage_sender):
        """Test Vonage sender initialization."""
        assert vonage_sender.from_phone == "+1234567890"
        assert vonage_sender.api_key == "test_key"
        assert vonage_sender.api_secret == "test_secret"

    def test_send_basic_sms(self, vonage_sender):
        """Test sending SMS via Vonage."""
        vonage_sender.sms.send_message = Mock(
            return_value={
                'messages': [{
                    'status': '0',
                    'message-id': 'msg_123',
                    'remaining-balance': '10.50',
                    'message-price': '0.05'
                }]
            }
        )

        message = SMSMessage(
            to_phone="+1234567890",
            message="Test"
        )

        result = vonage_sender.send(message)

        assert result["success"] is True
        assert result["message_id"] == "msg_123"
        assert result["remaining_balance"] == "10.50"

    def test_send_failure(self, vonage_sender):
        """Test handling Vonage send failure."""
        vonage_sender.sms.send_message = Mock(
            return_value={
                'messages': [{
                    'status': '1',
                    'error-text': 'Invalid number'
                }]
            }
        )

        message = SMSMessage(
            to_phone="+1234567890",
            message="Test"
        )

        with pytest.raises(Exception, match="Invalid number"):
            vonage_sender.send(message)


class TestMessageBirdSMSSender:
    """Test MessageBird SMS sender."""

    @pytest.fixture
    def messagebird_sender(self):
        """Create MessageBird sender for testing."""
        with patch('sms_sender.messagebird'):
            return MessageBirdSMSSender(
                from_phone="+1234567890",
                api_key="test_key"
            )

    def test_messagebird_initialization(self, messagebird_sender):
        """Test MessageBird sender initialization."""
        assert messagebird_sender.from_phone == "+1234567890"
        assert messagebird_sender.api_key == "test_key"

    def test_send_basic_sms(self, messagebird_sender):
        """Test sending SMS via MessageBird."""
        mock_response = Mock()
        mock_response.id = "msg_123"
        mock_response.recipients = {"totalCount": 1}

        messagebird_sender.client.message_create = Mock(return_value=mock_response)

        message = SMSMessage(
            to_phone="+1234567890",
            message="Test"
        )

        result = messagebird_sender.send(message)

        assert result["success"] is True
        assert result["message_id"] == "msg_123"


class TestSMSSenderFactory:
    """Test SMS sender factory."""

    def test_create_twilio_sender(self):
        """Test creating Twilio sender."""
        with patch('sms_sender.Client'):
            sender = create_sms_sender(
                provider=SMSProvider.TWILIO,
                from_phone="+1234567890",
                account_sid="test_sid",
                auth_token="test_token"
            )

            assert isinstance(sender, TwilioSMSSender)

    def test_create_aws_sender(self):
        """Test creating AWS SNS sender."""
        with patch('sms_sender.boto3'):
            sender = create_sms_sender(
                provider=SMSProvider.AWS_SNS,
                from_phone="+1234567890",
                region_name="us-east-1"
            )

            assert isinstance(sender, AWSSNSSMSSender)

    def test_create_vonage_sender(self):
        """Test creating Vonage sender."""
        with patch('sms_sender.vonage'):
            sender = create_sms_sender(
                provider=SMSProvider.VONAGE,
                from_phone="+1234567890",
                api_key="test_key",
                api_secret="test_secret"
            )

            assert isinstance(sender, VonageSMSSender)

    def test_create_messagebird_sender(self):
        """Test creating MessageBird sender."""
        with patch('sms_sender.messagebird'):
            sender = create_sms_sender(
                provider=SMSProvider.MESSAGEBIRD,
                from_phone="+1234567890",
                api_key="test_key"
            )

            assert isinstance(sender, MessageBirdSMSSender)

    def test_unsupported_provider(self):
        """Test creating sender with unsupported provider."""
        with pytest.raises(ValueError, match="Unsupported SMS provider"):
            create_sms_sender(
                provider="unsupported",
                from_phone="+1234567890"
            )


class TestPhoneNumberValidation:
    """Test phone number validation and formatting."""

    def test_validate_valid_e164(self):
        """Test validating valid E.164 phone number."""
        assert validate_phone_number("+1234567890") is True
        assert validate_phone_number("+447911123456") is True
        assert validate_phone_number("+861234567890") is True

    def test_validate_invalid_format(self):
        """Test validating invalid phone numbers."""
        assert validate_phone_number("1234567890") is False  # Missing +
        assert validate_phone_number("+0234567890") is False  # Starts with 0
        assert validate_phone_number("+12345") is False  # Too short
        assert validate_phone_number("invalid") is False

    def test_format_phone_number(self):
        """Test formatting phone number to E.164."""
        assert format_phone_number("1234567890") == "+11234567890"
        assert format_phone_number("(123) 456-7890") == "+11234567890"
        assert format_phone_number("+1234567890") == "+1234567890"

    def test_format_with_country_code(self):
        """Test formatting with specific country code."""
        assert format_phone_number("1234567890", "+44") == "+441234567890"
        assert format_phone_number("1234567890", "+86") == "+861234567890"


class TestBatchSending:
    """Test batch SMS sending."""

    @pytest.fixture
    def twilio_sender(self):
        """Create Twilio sender for testing."""
        with patch('sms_sender.Client'):
            return TwilioSMSSender(
                from_phone="+1234567890",
                account_sid="test_sid",
                auth_token="test_token"
            )

    def test_send_batch(self, twilio_sender):
        """Test sending batch of SMS messages."""
        mock_message = Mock()
        mock_message.sid = "SM123"
        mock_message.status = "sent"
        mock_message.price = "-0.0075"
        mock_message.price_unit = "USD"

        twilio_sender.client.messages.create = Mock(return_value=mock_message)

        messages = [
            SMSMessage(
                to_phone=f"+123456789{i}",
                message="Test message"
            )
            for i in range(5)
        ]

        results = twilio_sender.send_batch(messages)

        assert len(results) == 5
        assert all(r["success"] for r in results)
        assert twilio_sender.client.messages.create.call_count == 5

    def test_send_batch_with_failures(self, twilio_sender):
        """Test batch sending with some failures."""
        # Make every other send fail
        side_effects = []
        for i in range(5):
            if i % 2 == 0:
                mock_msg = Mock()
                mock_msg.sid = f"SM{i}"
                mock_msg.status = "sent"
                mock_msg.price = "-0.0075"
                mock_msg.price_unit = "USD"
                side_effects.append(mock_msg)
            else:
                side_effects.append(Exception("Failed"))

        twilio_sender.client.messages.create = Mock(side_effect=side_effects)

        messages = [
            SMSMessage(
                to_phone=f"+123456789{i}",
                message="Test"
            )
            for i in range(5)
        ]

        results = twilio_sender.send_batch(messages)

        assert len(results) == 5
        assert sum(1 for r in results if r["success"]) == 3
        assert sum(1 for r in results if not r["success"]) == 2


class TestMessageLength:
    """Test SMS message length handling."""

    def test_single_sms_length(self):
        """Test message within single SMS limit."""
        message = "A" * 160  # Exactly 160 characters
        assert len(message) == 160

    def test_multi_part_sms(self):
        """Test message requiring multiple SMS parts."""
        message = "A" * 161  # Requires 2 SMS parts
        assert len(message) == 161

        # Calculate number of parts (153 chars per part for multi-part)
        parts = (len(message) + 152) // 153
        assert parts == 2

    def test_unicode_message(self):
        """Test Unicode message (70 chars per SMS)."""
        message = "Hello 👋 World 🌍"
        # Unicode messages have 70 char limit
        assert len(message) <= 70


# Integration tests
@pytest.mark.integration
class TestSMSSenderIntegration:
    """Integration tests with real SMS providers."""

    @pytest.mark.skipif(
        not pytest.config.getoption("--run-integration"),
        reason="Integration tests disabled"
    )
    def test_send_real_sms_twilio(self):
        """Test sending real SMS via Twilio."""
        import os

        sender = TwilioSMSSender(
            from_phone=os.getenv("TWILIO_PHONE_NUMBER"),
            account_sid=os.getenv("TWILIO_ACCOUNT_SID"),
            auth_token=os.getenv("TWILIO_AUTH_TOKEN")
        )

        message = SMSMessage(
            to_phone=os.getenv("TEST_PHONE_NUMBER"),
            message="Test SMS from integration test"
        )

        result = sender.send(message)

        assert result["success"] is True
        assert result["message_id"] is not None

        # Check status
        status = sender.get_message_status(result["message_id"])
        assert status["status"] in ["queued", "sent", "delivered"]


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
