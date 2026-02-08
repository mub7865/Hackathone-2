"""
SMS Notification Sender

This module provides SMS sending functionality with multiple provider support.
"""

import os
import logging
from typing import Optional, Dict, Any, List
from enum import Enum
from dataclasses import dataclass

logger = logging.getLogger(__name__)


class SMSProvider(str, Enum):
    """Supported SMS providers."""
    TWILIO = "twilio"
    AWS_SNS = "aws_sns"
    VONAGE = "vonage"
    MESSAGEBIRD = "messagebird"


@dataclass
class SMSMessage:
    """SMS message data."""
    to_phone: str
    message: str
    from_phone: Optional[str] = None
    media_urls: Optional[List[str]] = None  # For MMS


class SMSSender:
    """Base SMS sender class."""

    def __init__(self, provider: SMSProvider, from_phone: str, **kwargs):
        self.provider = provider
        self.from_phone = from_phone
        self.config = kwargs

    def send(self, message: SMSMessage) -> Dict[str, Any]:
        """Send SMS message."""
        raise NotImplementedError("Subclass must implement send()")

    def send_batch(self, messages: List[SMSMessage]) -> List[Dict[str, Any]]:
        """Send multiple SMS messages."""
        results = []
        for message in messages:
            try:
                result = self.send(message)
                results.append(result)
            except Exception as e:
                logger.error(f"Failed to send SMS to {message.to_phone}: {e}")
                results.append({"success": False, "error": str(e)})
        return results


class TwilioSMSSender(SMSSender):
    """Twilio SMS sender."""

    def __init__(
        self,
        from_phone: str,
        account_sid: str,
        auth_token: str,
        **kwargs
    ):
        super().__init__(SMSProvider.TWILIO, from_phone, **kwargs)
        self.account_sid = account_sid
        self.auth_token = auth_token

        try:
            from twilio.rest import Client
            self.client = Client(account_sid, auth_token)
        except ImportError:
            raise ImportError("twilio package not installed. Install with: pip install twilio")

    def send(self, message: SMSMessage) -> Dict[str, Any]:
        """Send SMS via Twilio."""
        try:
            # Prepare message parameters
            params = {
                'body': message.message,
                'from_': message.from_phone or self.from_phone,
                'to': message.to_phone
            }

            # Add media URLs for MMS
            if message.media_urls:
                params['media_url'] = message.media_urls

            # Send message
            twilio_message = self.client.messages.create(**params)

            logger.info(f"SMS sent via Twilio to {message.to_phone}")
            return {
                "success": True,
                "message_id": twilio_message.sid,
                "status": twilio_message.status,
                "price": twilio_message.price,
                "price_unit": twilio_message.price_unit
            }

        except Exception as e:
            logger.error(f"Failed to send SMS via Twilio: {e}")
            raise

    def get_message_status(self, message_id: str) -> Dict[str, Any]:
        """Get message delivery status."""
        try:
            message = self.client.messages(message_id).fetch()
            return {
                "status": message.status,
                "error_code": message.error_code,
                "error_message": message.error_message,
                "date_sent": message.date_sent,
                "date_updated": message.date_updated
            }
        except Exception as e:
            logger.error(f"Failed to get message status: {e}")
            raise


class AWSSNSSMSSender(SMSSender):
    """AWS SNS SMS sender."""

    def __init__(
        self,
        from_phone: str,
        region_name: str = 'us-east-1',
        aws_access_key_id: Optional[str] = None,
        aws_secret_access_key: Optional[str] = None,
        **kwargs
    ):
        super().__init__(SMSProvider.AWS_SNS, from_phone, **kwargs)
        self.region_name = region_name

        try:
            import boto3
            self.sns_client = boto3.client(
                'sns',
                region_name=region_name,
                aws_access_key_id=aws_access_key_id,
                aws_secret_access_key=aws_secret_access_key
            )
        except ImportError:
            raise ImportError("boto3 package not installed. Install with: pip install boto3")

    def send(self, message: SMSMessage) -> Dict[str, Any]:
        """Send SMS via AWS SNS."""
        try:
            # Send message
            response = self.sns_client.publish(
                PhoneNumber=message.to_phone,
                Message=message.message,
                MessageAttributes={
                    'AWS.SNS.SMS.SenderID': {
                        'DataType': 'String',
                        'StringValue': self.from_phone
                    },
                    'AWS.SNS.SMS.SMSType': {
                        'DataType': 'String',
                        'StringValue': 'Transactional'  # or 'Promotional'
                    }
                }
            )

            logger.info(f"SMS sent via AWS SNS to {message.to_phone}")
            return {
                "success": True,
                "message_id": response['MessageId']
            }

        except Exception as e:
            logger.error(f"Failed to send SMS via AWS SNS: {e}")
            raise


class VonageSMSSender(SMSSender):
    """Vonage (Nexmo) SMS sender."""

    def __init__(
        self,
        from_phone: str,
        api_key: str,
        api_secret: str,
        **kwargs
    ):
        super().__init__(SMSProvider.VONAGE, from_phone, **kwargs)
        self.api_key = api_key
        self.api_secret = api_secret

        try:
            import vonage
            self.client = vonage.Client(key=api_key, secret=api_secret)
            self.sms = vonage.Sms(self.client)
        except ImportError:
            raise ImportError("vonage package not installed. Install with: pip install vonage")

    def send(self, message: SMSMessage) -> Dict[str, Any]:
        """Send SMS via Vonage."""
        try:
            # Send message
            response = self.sms.send_message({
                'from': message.from_phone or self.from_phone,
                'to': message.to_phone,
                'text': message.message
            })

            if response['messages'][0]['status'] == '0':
                logger.info(f"SMS sent via Vonage to {message.to_phone}")
                return {
                    "success": True,
                    "message_id": response['messages'][0]['message-id'],
                    "remaining_balance": response['messages'][0]['remaining-balance'],
                    "message_price": response['messages'][0]['message-price']
                }
            else:
                error = response['messages'][0]['error-text']
                logger.error(f"Failed to send SMS via Vonage: {error}")
                raise Exception(error)

        except Exception as e:
            logger.error(f"Failed to send SMS via Vonage: {e}")
            raise


class MessageBirdSMSSender(SMSSender):
    """MessageBird SMS sender."""

    def __init__(
        self,
        from_phone: str,
        api_key: str,
        **kwargs
    ):
        super().__init__(SMSProvider.MESSAGEBIRD, from_phone, **kwargs)
        self.api_key = api_key

        try:
            import messagebird
            self.client = messagebird.Client(api_key)
        except ImportError:
            raise ImportError("messagebird package not installed. Install with: pip install messagebird")

    def send(self, message: SMSMessage) -> Dict[str, Any]:
        """Send SMS via MessageBird."""
        try:
            # Send message
            response = self.client.message_create(
                originator=message.from_phone or self.from_phone,
                recipients=[message.to_phone],
                body=message.message
            )

            logger.info(f"SMS sent via MessageBird to {message.to_phone}")
            return {
                "success": True,
                "message_id": response.id,
                "recipients": response.recipients
            }

        except Exception as e:
            logger.error(f"Failed to send SMS via MessageBird: {e}")
            raise


def create_sms_sender(
    provider: SMSProvider,
    from_phone: str,
    **kwargs
) -> SMSSender:
    """Factory function to create SMS sender."""
    if provider == SMSProvider.TWILIO:
        return TwilioSMSSender(from_phone, **kwargs)
    elif provider == SMSProvider.AWS_SNS:
        return AWSSNSSMSSender(from_phone, **kwargs)
    elif provider == SMSProvider.VONAGE:
        return VonageSMSSender(from_phone, **kwargs)
    elif provider == SMSProvider.MESSAGEBIRD:
        return MessageBirdSMSSender(from_phone, **kwargs)
    else:
        raise ValueError(f"Unsupported SMS provider: {provider}")


# Phone number validation
def validate_phone_number(phone: str) -> bool:
    """Validate phone number format (E.164)."""
    import re
    # E.164 format: +[country code][number]
    pattern = r'^\+[1-9]\d{1,14}$'
    return bool(re.match(pattern, phone))


def format_phone_number(phone: str, country_code: str = '+1') -> str:
    """Format phone number to E.164 format."""
    # Remove all non-digit characters
    digits = ''.join(filter(str.isdigit, phone))

    # Add country code if not present
    if not phone.startswith('+'):
        return f"{country_code}{digits}"

    return f"+{digits}"


# Example usage
if __name__ == "__main__":
    # Twilio example
    twilio_sender = create_sms_sender(
        provider=SMSProvider.TWILIO,
        from_phone=os.getenv("TWILIO_PHONE_NUMBER"),
        account_sid=os.getenv("TWILIO_ACCOUNT_SID"),
        auth_token=os.getenv("TWILIO_AUTH_TOKEN")
    )

    message = SMSMessage(
        to_phone="+1234567890",
        message="Hello from Twilio!"
    )

    result = twilio_sender.send(message)
    print(f"SMS sent: {result}")

    # Check status
    if isinstance(twilio_sender, TwilioSMSSender):
        status = twilio_sender.get_message_status(result['message_id'])
        print(f"Message status: {status}")
