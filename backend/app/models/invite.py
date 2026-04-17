"""
Invite Model — User invitation tokens.

Created by a tenant admin; exchanged via `POST /accept-invite` for an
activated user account. Tokens are stored as SHA-256 hashes; raw tokens
are shown to the admin once (email or copy-link dialog).
"""
from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.database import Base


class Invite(Base):
    __tablename__ = "invites"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(
        String(36),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    email = Column(String(255), nullable=False, index=True)
    role = Column(String(32), nullable=False)                 # "admin" | "analyst" | "viewer"
    token_hash = Column(String(64), nullable=False, unique=True)   # SHA-256 hex
    expires_at = Column(DateTime(timezone=True), nullable=False)
    used_at = Column(DateTime(timezone=True), nullable=True)
    created_by = Column(
        String(36),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at = Column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        server_default=func.now(),
        nullable=False,
    )
    group_id = Column(
        String(36),
        ForeignKey("user_groups.id", ondelete="SET NULL"),
        nullable=True,
    )

    # Relationships
    tenant = relationship("Tenant")
    creator = relationship("User", foreign_keys=[created_by])
    group = relationship("UserGroup", foreign_keys=[group_id])

    def __repr__(self) -> str:
        return f"<Invite(id={self.id}, email={self.email}, role={self.role})>"
