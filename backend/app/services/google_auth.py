from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

from app.core.config import get_settings


class GoogleAuthError(Exception):
    """Raised when Google ID token verification fails."""

    pass


def verify_google_id_token(token: str) -> dict:
    """Verify a Google ID token and return the decoded payload.

    Returns dict with keys: sub, email, email_verified, name, picture, etc.
    Raises GoogleAuthError on failure.
    """
    settings = get_settings()

    try:
        payload = google_id_token.verify_oauth2_token(
            token,
            google_requests.Request(),
            audience=settings.google_client_id,
        )
    except ValueError as e:
        raise GoogleAuthError(f"Invalid Google ID token: {e}")

    # Verify issuer
    if payload.get("iss") not in ("accounts.google.com", "https://accounts.google.com"):
        raise GoogleAuthError("Invalid token issuer")

    # Verify email is present and verified
    if not payload.get("email_verified"):
        raise GoogleAuthError("Google email not verified")

    if not payload.get("email"):
        raise GoogleAuthError("No email in Google token")

    return payload
