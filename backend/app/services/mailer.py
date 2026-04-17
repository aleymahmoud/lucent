"""
Mailer service — optional SMTP wrapper.

When SMTP_HOST is not configured, all `send_*` functions become no-ops
that log a warning but return False. Callers check the return value to
decide whether to fall back to showing a link in-UI.
"""
from __future__ import annotations

import logging
from email.message import EmailMessage
from typing import Optional

from app.config import get_settings


logger = logging.getLogger(__name__)


def _smtp_configured() -> bool:
    s = get_settings()
    return bool(s.SMTP_HOST and s.SMTP_FROM)


async def _send(subject: str, to_email: str, plain_body: str, html_body: Optional[str] = None) -> bool:
    """Send one email. Returns True on success, False if SMTP disabled / failed."""
    if not _smtp_configured():
        logger.info(f"SMTP disabled; skipping send to {to_email} (subject: {subject})")
        return False

    s = get_settings()
    msg = EmailMessage()
    msg["From"] = s.SMTP_FROM
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.set_content(plain_body)
    if html_body:
        msg.add_alternative(html_body, subtype="html")

    try:
        import aiosmtplib
        await aiosmtplib.send(
            msg,
            hostname=s.SMTP_HOST,
            port=s.SMTP_PORT,
            username=s.SMTP_USER,
            password=s.SMTP_PASSWORD,
            start_tls=s.SMTP_USE_TLS,
        )
        logger.info(f"Email sent to {to_email} (subject: {subject})")
        return True
    except Exception as exc:
        logger.warning(f"Email send failed for {to_email}: {exc}")
        return False


# ============================================
# Specific email types
# ============================================

async def send_invite(to_email: str, invite_link: str, inviter_email: Optional[str] = None) -> bool:
    inviter = inviter_email or "Your team admin"
    subject = "You're invited to LUCENT"
    plain = (
        f"Hi,\n\n"
        f"{inviter} has invited you to join LUCENT.\n\n"
        f"Accept the invitation and set your password here:\n{invite_link}\n\n"
        f"This link expires in 7 days.\n\n"
        f"- LUCENT\n"
    )
    html = (
        f"<p>Hi,</p>"
        f"<p><strong>{inviter}</strong> has invited you to join LUCENT.</p>"
        f'<p><a href="{invite_link}">Accept the invitation and set your password</a></p>'
        f"<p><em>This link expires in 7 days.</em></p>"
        f"<p>&mdash; LUCENT</p>"
    )
    return await _send(subject, to_email, plain, html)


async def send_password_reset(to_email: str, reset_link: str) -> bool:
    subject = "Reset your LUCENT password"
    plain = (
        f"Hi,\n\n"
        f"A password reset was requested for your LUCENT account.\n"
        f"If it was you, follow this link to set a new password:\n{reset_link}\n\n"
        f"This link expires in 1 hour. If it wasn't you, you can ignore this email.\n\n"
        f"- LUCENT\n"
    )
    html = (
        f"<p>Hi,</p>"
        f"<p>A password reset was requested for your LUCENT account.</p>"
        f'<p><a href="{reset_link}">Set a new password</a></p>'
        f"<p><em>This link expires in 1 hour.</em></p>"
    )
    return await _send(subject, to_email, plain, html)


async def send_approval_notification(to_email: str, login_url: str) -> bool:
    subject = "Your LUCENT account is now active"
    plain = (
        f"Hi,\n\n"
        f"Your LUCENT account has been approved. You can now log in:\n{login_url}\n\n"
        f"- LUCENT\n"
    )
    html = (
        f"<p>Hi,</p>"
        f"<p>Your LUCENT account has been approved.</p>"
        f'<p><a href="{login_url}">Log in now</a></p>'
    )
    return await _send(subject, to_email, plain, html)
