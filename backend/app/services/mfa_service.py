"""
MFA service — TOTP enrolment, verification, backup-code handling.

TOTP is via pyotp (RFC 6238). Backup codes are stored as SHA-256 hashes;
shown in plain text once at enrolment.
"""
from __future__ import annotations

import hashlib
import logging
import secrets
from typing import List, Optional

import pyotp

from app.config import get_settings
from app.models.user import User


logger = logging.getLogger(__name__)

TOTP_ISSUER = "LUCENT"
N_BACKUP_CODES = 10
BACKUP_CODE_BYTES = 6   # -> ~10 url-safe chars


def _hash_code(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def generate_secret() -> str:
    """Generate a fresh TOTP base32 secret."""
    return pyotp.random_base32()


def generate_backup_codes(n: int = N_BACKUP_CODES) -> list[str]:
    """Generate `n` single-use backup codes. Plain text; hash before storing."""
    codes: list[str] = []
    for _ in range(n):
        raw = secrets.token_urlsafe(BACKUP_CODE_BYTES)
        # format as xxxx-xxxx for readability
        formatted = "-".join([raw[:4], raw[4:8]])[:9].lower()
        codes.append(formatted)
    return codes


def qr_uri(secret: str, email: str) -> str:
    """Build the otpauth:// URI consumed by authenticator apps."""
    return pyotp.totp.TOTP(secret).provisioning_uri(name=email, issuer_name=TOTP_ISSUER)


def verify_totp(secret: str, code: str, valid_window: int = 1) -> bool:
    """Verify a TOTP code with a small window for clock drift."""
    try:
        totp = pyotp.TOTP(secret)
        return bool(totp.verify(code.strip(), valid_window=valid_window))
    except Exception as exc:
        logger.warning(f"TOTP verify failed: {exc}")
        return False


def verify_backup_code(user: User, code: str) -> tuple[bool, Optional[list[str]]]:
    """
    Verify a backup code against user.mfa_backup_codes.

    Returns (matched, updated_codes_list). Caller must persist the updated list
    so the consumed code is removed.
    """
    if not user.mfa_backup_codes:
        return False, None
    stored = list(user.mfa_backup_codes) if isinstance(user.mfa_backup_codes, list) else []
    h = _hash_code(code.strip().lower())
    if h not in stored:
        return False, None
    stored.remove(h)
    return True, stored


def store_backup_codes(plain_codes: list[str]) -> list[str]:
    """Convert plain codes to their hashes for DB storage."""
    return [_hash_code(c) for c in plain_codes]
