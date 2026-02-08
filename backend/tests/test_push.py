import json
import pytest
from unittest.mock import patch, MagicMock

from app.services.push import PushService


@pytest.mark.asyncio
async def test_get_vapid_public_key_not_configured(test_client):
    """Test that /push/vapid-public-key returns 503 when not configured."""
    with patch("app.api.push.get_settings") as mock_settings:
        mock_settings.return_value.vapid_public_key = ""
        mock_settings.return_value.vapid_private_key = ""

        response = await test_client.get("/api/push/vapid-public-key")
        assert response.status_code == 503
        assert "not configured" in response.json()["detail"]


@pytest.mark.asyncio
async def test_get_vapid_public_key_configured(test_client):
    """Test that /push/vapid-public-key returns key when configured."""
    with patch("app.api.push.get_settings") as mock_settings:
        mock_settings.return_value.vapid_public_key = "test-public-key"
        mock_settings.return_value.vapid_private_key = "test-private-key"

        response = await test_client.get("/api/push/vapid-public-key")
        assert response.status_code == 200
        assert response.json()["publicKey"] == "test-public-key"


@pytest.mark.asyncio
async def test_subscribe_requires_auth(test_client):
    """Test that /push/subscribe requires authentication."""
    response = await test_client.post(
        "/api/push/subscribe",
        json={
            "endpoint": "https://example.com/push",
            "p256dh_key": "test-key",
            "auth_key": "test-auth",
        },
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_subscribe_not_configured(test_client, auth_headers):
    """Test that /push/subscribe returns 503 when VAPID not configured."""
    # Patch get_settings in the push service (where PushService is created)
    with patch("app.services.push.get_settings") as mock_settings:
        mock_settings.return_value.vapid_public_key = ""
        mock_settings.return_value.vapid_private_key = ""

        response = await test_client.post(
            "/api/push/subscribe",
            headers=auth_headers,
            json={
                "endpoint": "https://example.com/push",
                "p256dh_key": "test-key",
                "auth_key": "test-auth",
            },
        )
        assert response.status_code == 503


@pytest.mark.asyncio
async def test_subscribe_success(test_client, auth_headers, db_session):
    """Test successful push subscription."""
    with patch("app.api.push.get_settings") as mock_settings:
        mock_settings.return_value.vapid_public_key = "test-public-key"
        mock_settings.return_value.vapid_private_key = "test-private-key"

        response = await test_client.post(
            "/api/push/subscribe",
            headers=auth_headers,
            json={
                "endpoint": "https://fcm.googleapis.com/fcm/send/test123",
                "p256dh_key": "test-p256dh-key",
                "auth_key": "test-auth-key",
            },
        )
        assert response.status_code == 200
        assert response.json()["success"] is True


@pytest.mark.asyncio
async def test_unsubscribe_requires_auth(test_client):
    """Test that /push/unsubscribe requires authentication."""
    response = await test_client.post(
        "/api/push/unsubscribe",
        json={
            "endpoint": "https://example.com/push",
            "p256dh_key": "",
            "auth_key": "",
        },
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_unsubscribe_not_found(test_client, auth_headers):
    """Test that /push/unsubscribe returns 404 when subscription not found."""
    response = await test_client.post(
        "/api/push/unsubscribe",
        headers=auth_headers,
        json={
            "endpoint": "https://example.com/nonexistent",
            "p256dh_key": "",
            "auth_key": "",
        },
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_push_service_is_configured(db_session):
    """Test PushService.is_configured property."""
    # Patch get_settings before creating service since settings are cached in __init__
    with patch("app.services.push.get_settings") as mock_get_settings:
        mock_settings = MagicMock()
        mock_get_settings.return_value = mock_settings

        # Test not configured
        mock_settings.vapid_public_key = ""
        mock_settings.vapid_private_key = ""
        service = PushService(db_session)
        assert service.is_configured is False

        # Test configured
        mock_settings.vapid_public_key = "test-key"
        mock_settings.vapid_private_key = "test-private"
        assert service.is_configured is True


@pytest.mark.asyncio
async def test_push_service_subscribe_and_unsubscribe(db_session, test_user):
    """Test PushService subscribe and unsubscribe flow."""
    service = PushService(db_session)

    # Subscribe
    subscription = await service.subscribe(
        user_id=test_user.id,
        endpoint="https://fcm.googleapis.com/fcm/send/test-endpoint",
        p256dh_key="test-p256dh",
        auth_key="test-auth",
        user_agent="Test Browser",
    )

    assert subscription is not None
    assert subscription.user_id == test_user.id
    assert subscription.endpoint == "https://fcm.googleapis.com/fcm/send/test-endpoint"
    assert subscription.p256dh_key == "test-p256dh"
    assert subscription.auth_key == "test-auth"

    # Get subscriptions
    subscriptions = await service.get_user_subscriptions(test_user.id)
    assert len(subscriptions) == 1

    # Unsubscribe
    removed = await service.unsubscribe(
        user_id=test_user.id,
        endpoint="https://fcm.googleapis.com/fcm/send/test-endpoint",
    )
    assert removed is True

    # Verify removed
    subscriptions = await service.get_user_subscriptions(test_user.id)
    assert len(subscriptions) == 0


@pytest.mark.asyncio
async def test_push_service_subscribe_updates_existing(db_session, test_user):
    """Test that subscribing with same endpoint updates existing subscription."""
    service = PushService(db_session)
    endpoint = "https://fcm.googleapis.com/fcm/send/test-endpoint"

    # First subscription
    sub1 = await service.subscribe(
        user_id=test_user.id,
        endpoint=endpoint,
        p256dh_key="key1",
        auth_key="auth1",
    )

    # Second subscription with same endpoint should update
    sub2 = await service.subscribe(
        user_id=test_user.id,
        endpoint=endpoint,
        p256dh_key="key2",
        auth_key="auth2",
    )

    assert sub1.id == sub2.id
    assert sub2.p256dh_key == "key2"
    assert sub2.auth_key == "auth2"

    # Should still only have one subscription
    subscriptions = await service.get_user_subscriptions(test_user.id)
    assert len(subscriptions) == 1


@pytest.mark.asyncio
async def test_push_service_send_to_user_no_subscriptions(db_session, test_user):
    """Test send_to_user with no subscriptions returns 0."""
    service = PushService(db_session)

    sent = await service.send_to_user(
        user_id=test_user.id,
        title="Test",
        body="Test message",
    )

    assert sent == 0


@pytest.mark.asyncio
async def test_push_service_send_to_user_not_configured(db_session, test_user):
    """Test send_to_user when VAPID not configured returns 0."""
    service = PushService(db_session)

    # Add a subscription
    await service.subscribe(
        user_id=test_user.id,
        endpoint="https://example.com/push",
        p256dh_key="key",
        auth_key="auth",
    )

    # Mock settings to have no VAPID keys
    with patch.object(service, "settings") as mock_settings:
        mock_settings.vapid_public_key = ""
        mock_settings.vapid_private_key = ""

        # Should return 0 because VAPID not configured
        sent = await service.send_to_user(
            user_id=test_user.id,
            title="Test",
            body="Test message",
        )

        assert sent == 0


@pytest.mark.asyncio
async def test_push_service_send_payload_includes_tag_and_url(db_session, test_user):
    """Test that send_to_user passes tag and url in the push payload."""
    service = PushService(db_session)

    # Add a subscription
    await service.subscribe(
        user_id=test_user.id,
        endpoint="https://fcm.googleapis.com/fcm/send/test",
        p256dh_key="test-key",
        auth_key="test-auth",
    )

    with (
        patch.object(service, "settings") as mock_settings,
        patch("app.services.push.webpush") as mock_webpush,
    ):
        mock_settings.vapid_public_key = "test-pub"
        mock_settings.vapid_private_key = "test-priv"
        mock_settings.vapid_subject = "mailto:test@example.com"

        sent = await service.send_to_user(
            user_id=test_user.id,
            title="New Assignment",
            body="You've been assigned",
            url="/?focus=action-required",
            tag="new-assignment",
        )

        assert sent == 1
        mock_webpush.assert_called_once()
        payload = json.loads(mock_webpush.call_args.kwargs["data"])
        assert payload["title"] == "New Assignment"
        assert payload["body"] == "You've been assigned"
        assert payload["url"] == "/?focus=action-required"
        assert payload["tag"] == "new-assignment"
        assert "actions" not in payload
        assert "data" not in payload


@pytest.mark.asyncio
async def test_push_service_send_without_tag(db_session, test_user):
    """Test that send_to_user omits tag from payload when not provided."""
    service = PushService(db_session)

    await service.subscribe(
        user_id=test_user.id,
        endpoint="https://fcm.googleapis.com/fcm/send/test",
        p256dh_key="test-key",
        auth_key="test-auth",
    )

    with (
        patch.object(service, "settings") as mock_settings,
        patch("app.services.push.webpush") as mock_webpush,
    ):
        mock_settings.vapid_public_key = "test-pub"
        mock_settings.vapid_private_key = "test-priv"
        mock_settings.vapid_subject = "mailto:test@example.com"

        sent = await service.send_to_user(
            user_id=test_user.id,
            title="Team Joined",
            body="Welcome",
            url="/teams/123",
        )

        assert sent == 1
        payload = json.loads(mock_webpush.call_args.kwargs["data"])
        assert payload["title"] == "Team Joined"
        assert payload["url"] == "/teams/123"
        assert "tag" not in payload
