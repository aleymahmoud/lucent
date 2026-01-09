"""
Platform Admin Model - Separate from tenant users
"""
from sqlalchemy import Column, String, Boolean, DateTime, Text
from sqlalchemy.sql import func
import uuid

from app.db.database import Base


class PlatformAdmin(Base):
    """
    Platform administrators - completely separate from tenant users.
    These users can only access the platform admin portal (/lucent/admin).
    To access a tenant, they must have a separate user account in that tenant.
    """
    __tablename__ = "platform_admins"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=True)

    # Status
    is_active = Column(Boolean, default=True, nullable=False)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    last_login = Column(DateTime(timezone=True), nullable=True)

    def __repr__(self):
        return f"<PlatformAdmin {self.email}>"
