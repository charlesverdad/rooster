import pytest

from app.services.email import EmailService


@pytest.mark.asyncio
async def test_send_invite_email_logs_in_debug(caplog):
    """Ensure invite email logs the debug message with link and recipient."""
    service = EmailService()
    service.settings.debug = False
    service.settings.app_url = "http://localhost:3000"
    service.settings.email_enabled = False

    token = "test-token"
    expected_link = f"{service.settings.app_url}/invite/{token}"

    with caplog.at_level("WARNING"):
        result = await service.send_invite_email(
            to_email="recipient@example.com",
            invitee_name="Recipient",
            team_name="Media Team",
            inviter_name="Team Lead",
            token=token,
        )

    assert result is False
    assert (
        "Would've sent email to recipient@example.com with invite link "
        f"{expected_link} (email disabled)"
        in caplog.text
    )
