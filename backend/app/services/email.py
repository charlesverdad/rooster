"""Email service for sending notifications and invites."""

import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Optional
import logging

from app.core.config import get_settings

logger = logging.getLogger(__name__)


class EmailService:
    """Service for sending emails via SMTP."""

    def __init__(self):
        self.settings = get_settings()

    def _refresh_settings(self) -> None:
        """Refresh settings in case debug flags change at runtime."""
        self.settings = get_settings()

    @property
    def is_enabled(self) -> bool:
        """Check if email sending is enabled."""
        return (
            self.settings.email_enabled
            and bool(self.settings.smtp_host)
            and bool(self.settings.smtp_user)
        )

    def _get_invite_url(self, token: str) -> str:
        """Generate the invite acceptance URL."""
        base_url = self.settings.app_url.rstrip("/")
        return f"{base_url}/invite/{token}"

    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
    ) -> bool:
        """Send an email.

        Args:
            to_email: Recipient email address
            subject: Email subject
            html_content: HTML body content
            text_content: Plain text body (optional, will be derived from html if not provided)

        Returns:
            True if email was sent successfully, False otherwise
        """
        self._refresh_settings()
        if not self.is_enabled:
            logger.warning(f"Email not sent (disabled): {subject} -> {to_email}")
            return False

        try:
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = f"{self.settings.smtp_from_name} <{self.settings.smtp_from_email}>"
            message["To"] = to_email

            # Add plain text version
            if text_content:
                part1 = MIMEText(text_content, "plain")
                message.attach(part1)

            # Add HTML version
            part2 = MIMEText(html_content, "html")
            message.attach(part2)

            # Send the email
            if self.settings.smtp_use_tls:
                context = ssl.create_default_context()
                with smtplib.SMTP(self.settings.smtp_host, self.settings.smtp_port) as server:
                    server.starttls(context=context)
                    server.login(self.settings.smtp_user, self.settings.smtp_password)
                    server.sendmail(
                        self.settings.smtp_from_email,
                        to_email,
                        message.as_string(),
                    )
            else:
                with smtplib.SMTP(self.settings.smtp_host, self.settings.smtp_port) as server:
                    server.login(self.settings.smtp_user, self.settings.smtp_password)
                    server.sendmail(
                        self.settings.smtp_from_email,
                        to_email,
                        message.as_string(),
                    )

            logger.info(f"Email sent successfully: {subject} -> {to_email}")
            return True

        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            return False

    async def send_invite_email(
        self,
        to_email: str,
        invitee_name: str,
        team_name: str,
        inviter_name: str,
        token: str,
    ) -> bool:
        """Send an invite email to a placeholder user.

        Args:
            to_email: Recipient email address
            invitee_name: Name of the person being invited
            team_name: Name of the team
            inviter_name: Name of the person sending the invite
            token: Invite token

        Returns:
            True if email was sent successfully, False otherwise
        """
        self._refresh_settings()
        invite_url = self._get_invite_url(token)
        if self.settings.debug:
            logger.warning(
                "Would've sent email to %s with invite link %s",
                to_email,
                invite_url,
            )
        subject = f"You've been invited to join {team_name} on Rooster"

        html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>You're Invited!</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="text-align: center; margin-bottom: 30px;">
        <h1 style="color: #673AB7; margin: 0;">Rooster</h1>
        <p style="color: #666; margin: 5px 0 0 0;">Volunteer Scheduling</p>
    </div>

    <div style="background: #f8f9fa; border-radius: 12px; padding: 30px; margin-bottom: 30px;">
        <h2 style="margin-top: 0; color: #333;">Hi {invitee_name}!</h2>
        <p style="font-size: 16px; margin-bottom: 20px;">
            <strong>{inviter_name}</strong> has invited you to join <strong>{team_name}</strong> on Rooster.
        </p>
        <p style="font-size: 14px; color: #666;">
            Rooster helps you stay on top of your volunteer schedule. Once you join, you'll be able to see your assignments and respond with just a tap.
        </p>
    </div>

    <div style="text-align: center; margin-bottom: 30px;">
        <a href="{invite_url}" style="display: inline-block; background: #673AB7; color: white; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: 600; font-size: 16px;">
            Join {team_name}
        </a>
    </div>

    <div style="text-align: center; color: #999; font-size: 12px;">
        <p>This invite link will expire in 7 days.</p>
        <p>If you weren't expecting this email, you can safely ignore it.</p>
    </div>

    <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">

    <div style="text-align: center; color: #999; font-size: 12px;">
        <p>Rooster - Volunteer Scheduling Made Simple</p>
    </div>
</body>
</html>
"""

        text_content = f"""
Hi {invitee_name}!

{inviter_name} has invited you to join {team_name} on Rooster.

Rooster helps you stay on top of your volunteer schedule. Once you join, you'll be able to see your assignments and respond with just a tap.

Join the team by clicking this link:
{invite_url}

This invite link will expire in 7 days.

If you weren't expecting this email, you can safely ignore it.

---
Rooster - Volunteer Scheduling Made Simple
"""

        return await self.send_email(to_email, subject, html_content, text_content)

    async def send_assignment_notification(
        self,
        to_email: str,
        user_name: str,
        roster_name: str,
        team_name: str,
        event_date: str,
        event_time: Optional[str] = None,
    ) -> bool:
        """Send a notification about a new assignment.

        Args:
            to_email: Recipient email address
            user_name: Name of the assigned user
            roster_name: Name of the roster
            team_name: Name of the team
            event_date: Date of the event (formatted string)
            event_time: Time of the event (optional)

        Returns:
            True if email was sent successfully, False otherwise
        """
        subject = f"New assignment: {roster_name}"
        time_str = f" at {event_time}" if event_time else ""

        html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="text-align: center; margin-bottom: 30px;">
        <h1 style="color: #673AB7; margin: 0;">Rooster</h1>
    </div>

    <div style="background: #fff3e0; border-radius: 12px; padding: 30px; margin-bottom: 30px; border-left: 4px solid #ff9800;">
        <h2 style="margin-top: 0; color: #333;">New Assignment</h2>
        <p style="font-size: 16px;">
            Hi {user_name}, you've been assigned to serve!
        </p>
        <div style="background: white; padding: 16px; border-radius: 8px; margin: 16px 0;">
            <p style="margin: 0;"><strong>{roster_name}</strong></p>
            <p style="margin: 4px 0 0 0; color: #666;">{team_name}</p>
            <p style="margin: 4px 0 0 0; color: #666;">{event_date}{time_str}</p>
        </div>
        <p style="font-size: 14px; color: #666;">
            Open the Rooster app to accept or decline this assignment.
        </p>
    </div>

    <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">

    <div style="text-align: center; color: #999; font-size: 12px;">
        <p>Rooster - Volunteer Scheduling Made Simple</p>
    </div>
</body>
</html>
"""

        text_content = f"""
New Assignment

Hi {user_name}, you've been assigned to serve!

{roster_name}
{team_name}
{event_date}{time_str}

Open the Rooster app to accept or decline this assignment.

---
Rooster - Volunteer Scheduling Made Simple
"""

        return await self.send_email(to_email, subject, html_content, text_content)


# Singleton instance
_email_service: Optional[EmailService] = None


def get_email_service() -> EmailService:
    """Get the email service singleton."""
    global _email_service
    if _email_service is None:
        _email_service = EmailService()
    return _email_service
