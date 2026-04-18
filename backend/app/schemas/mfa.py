"""MFA schemas."""
from __future__ import annotations

from typing import List
from pydantic import BaseModel, Field


class MfaEnrollResponse(BaseModel):
    secret: str              # base32
    qr_uri: str              # otpauth:// URI for QR code
    backup_codes: List[str]  # shown once, plain text


class MfaVerifyRequest(BaseModel):
    code: str = Field(..., min_length=6, max_length=12)


class MfaChallengeRequest(BaseModel):
    """Used during login to complete 2FA."""
    challenge_token: str     # opaque token from /auth/login when MFA is required
    code: str = Field(..., min_length=6, max_length=12)


class MfaDisableRequest(BaseModel):
    password: str            # confirm current password
