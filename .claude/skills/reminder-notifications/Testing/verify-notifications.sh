#!/bin/bash
# Verification Script for Notification System Setup
# This script verifies that all notification providers are properly configured

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
echo "Notification System Verification"
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
python3 -c "import sqlmodel" 2>/dev/null
print_result $? "SQLModel installed"

python3 -c "import jinja2" 2>/dev/null
print_result $? "Jinja2 installed"

python3 -c "import pytz" 2>/dev/null
print_result $? "pytz installed"

echo ""

# Test 2: Check email provider dependencies
echo "Test 2: Checking email provider dependencies..."
python3 -c "import sendgrid" 2>/dev/null
print_result $? "SendGrid installed (optional)"

python3 -c "import boto3" 2>/dev/null
print_result $? "boto3 (AWS) installed (optional)"

echo ""

# Test 3: Check SMS provider dependencies
echo "Test 3: Checking SMS provider dependencies..."
python3 -c "import twilio" 2>/dev/null
print_result $? "Twilio installed (optional)"

python3 -c "import vonage" 2>/dev/null
print_result $? "Vonage installed (optional)"

echo ""

# Test 4: Check push notification dependencies
echo "Test 4: Checking push notification dependencies..."
python3 -c "import firebase_admin" 2>/dev/null
print_result $? "Firebase Admin installed (optional)"

echo ""

# Test 5: Verify environment variables
echo "Test 5: Checking environment variables..."

check_env_var() {
    if [ -n "${!1}" ]; then
        echo -e "${GREEN}✓${NC} $1 is set"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $1 is not set (optional)"
        return 1
    fi
}

# Email variables
check_env_var "SENDGRID_API_KEY"
check_env_var "SMTP_HOST"
check_env_var "SMTP_USERNAME"

# SMS variables
check_env_var "TWILIO_ACCOUNT_SID"
check_env_var "TWILIO_AUTH_TOKEN"
check_env_var "TWILIO_PHONE_NUMBER"

# Push variables
check_env_var "FIREBASE_CREDENTIALS_PATH"

echo ""

# Test 6: Test email sender creation
echo "Test 6: Testing email sender creation..."
python3 << 'EOF'
import sys
try:
    from email_sender import create_email_sender, EmailProvider

    # Test SMTP sender creation
    sender = create_email_sender(
        provider=EmailProvider.SMTP,
        from_email="test@example.com",
        smtp_host="smtp.example.com",
        smtp_port=587
    )

    print("Email sender created successfully")
    sys.exit(0)
except Exception as e:
    print(f"Failed to create email sender: {e}")
    sys.exit(1)
EOF
print_result $? "Email sender creation"

echo ""

# Test 7: Test SMS sender creation
echo "Test 7: Testing SMS sender creation..."
python3 << 'EOF'
import sys
try:
    from sms_sender import create_sms_sender, SMSProvider

    # Test AWS SNS sender creation (doesn't require external deps)
    sender = create_sms_sender(
        provider=SMSProvider.AWS_SNS,
        from_phone="+1234567890",
        region_name="us-east-1"
    )

    print("SMS sender created successfully")
    sys.exit(0)
except Exception as e:
    print(f"Failed to create SMS sender: {e}")
    sys.exit(1)
EOF
print_result $? "SMS sender creation"

echo ""

# Test 8: Test notification models
echo "Test 8: Testing notification models..."
python3 << 'EOF'
import sys
try:
    from notification_model import (
        Notification,
        NotificationChannel,
        NotificationStatus,
        NotificationPreference
    )

    # Create notification instance
    notification = Notification(
        user_id="test_user",
        channel=NotificationChannel.EMAIL,
        template_name="test_template",
        data={"key": "value"}
    )

    # Create preference instance
    preference = NotificationPreference(
        user_id="test_user",
        email_enabled=True
    )

    print("Notification models working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Failed to create notification models: {e}")
    sys.exit(1)
EOF
print_result $? "Notification models"

echo ""

# Test 9: Test template manager
echo "Test 9: Testing template manager..."
python3 << 'EOF'
import sys
try:
    from notification_templates import TemplateManager
    from notification_model import NotificationChannel

    manager = TemplateManager()

    # Test rendering built-in template
    content = manager.render(
        template_name="task_reminder",
        channel=NotificationChannel.EMAIL,
        data={
            "user_name": "Test User",
            "task_title": "Test Task",
            "due_date": "2024-01-10",
            "task_url": "https://example.com"
        }
    )

    assert 'subject' in content
    assert 'html' in content
    assert 'Test User' in content['html']

    print("Template manager working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Failed to render template: {e}")
    sys.exit(1)
EOF
print_result $? "Template manager"

echo ""

# Test 10: Test phone number validation
echo "Test 10: Testing phone number validation..."
python3 << 'EOF'
import sys
try:
    from sms_sender import validate_phone_number, format_phone_number

    # Test validation
    assert validate_phone_number("+1234567890") is True
    assert validate_phone_number("1234567890") is False

    # Test formatting
    assert format_phone_number("1234567890") == "+11234567890"
    assert format_phone_number("+1234567890") == "+1234567890"

    print("Phone number validation working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Phone number validation failed: {e}")
    sys.exit(1)
EOF
print_result $? "Phone number validation"

echo ""

# Test 11: Test database models
echo "Test 11: Testing database models..."
python3 << 'EOF'
import sys
try:
    from sqlmodel import create_engine, Session, SQLModel
    from notification_model import Notification, NotificationPreference, NotificationChannel

    # Create in-memory database
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)

    with Session(engine) as session:
        # Create notification
        notification = Notification(
            user_id="test_user",
            channel=NotificationChannel.EMAIL,
            template_name="test_template",
            data={"key": "value"}
        )
        session.add(notification)
        session.commit()
        session.refresh(notification)

        assert notification.id is not None

        # Create preference
        preference = NotificationPreference(
            user_id="test_user",
            email_enabled=True
        )
        session.add(preference)
        session.commit()

    print("Database models working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Database models failed: {e}")
    sys.exit(1)
EOF
print_result $? "Database models"

echo ""

# Test 12: Test notification service
echo "Test 12: Testing notification service..."
python3 << 'EOF'
import sys
try:
    from sqlmodel import create_engine, Session, SQLModel
    from notification_service import NotificationService
    from notification_model import NotificationChannel

    # Create in-memory database
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)

    # Create notification service (without actual senders)
    service = NotificationService(
        session_factory=lambda: Session(engine)
    )

    print("Notification service created successfully")
    sys.exit(0)
except Exception as e:
    print(f"Notification service failed: {e}")
    sys.exit(1)
EOF
print_result $? "Notification service"

echo ""

# Test 13: Test preference manager
echo "Test 13: Testing preference manager..."
python3 << 'EOF'
import sys
try:
    from sqlmodel import create_engine, Session, SQLModel
    from notification_preferences import PreferenceManager
    from notification_model import NotificationChannel

    # Create in-memory database
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)

    # Create preference manager
    manager = PreferenceManager(lambda: Session(engine))

    # Get preferences (should create default)
    preferences = manager.get_preferences("test_user")
    assert preferences.email_enabled is True

    # Update preferences
    manager.update_preferences("test_user", email_enabled=False)

    # Check if can send
    can_send = manager.can_send("test_user", NotificationChannel.EMAIL)
    assert can_send is False

    print("Preference manager working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Preference manager failed: {e}")
    sys.exit(1)
EOF
print_result $? "Preference manager"

echo ""

# Test 14: Test rate limiter
echo "Test 14: Testing rate limiter..."
python3 << 'EOF'
import sys
try:
    from sqlmodel import create_engine, Session, SQLModel
    from notification_preferences import NotificationThrottler
    from notification_model import NotificationChannel

    # Create in-memory database
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)

    # Create throttler
    throttler = NotificationThrottler(lambda: Session(engine))

    # Check rate limit (should pass for new user)
    can_send = throttler.can_send("test_user", NotificationChannel.EMAIL)
    assert can_send is True

    # Get rate limit info
    info = throttler.get_rate_limit_info("test_user", NotificationChannel.EMAIL)
    assert info["current_count"] == 0

    print("Rate limiter working correctly")
    sys.exit(0)
except Exception as e:
    print(f"Rate limiter failed: {e}")
    sys.exit(1)
EOF
print_result $? "Rate limiter"

echo ""

# Summary
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Notification system is ready to use.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please check the output above.${NC}"
    exit 1
fi
