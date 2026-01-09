"""
UserGroup Model - Groups for organizing users and RLS values
"""
from sqlalchemy import Column, String, Text, JSON, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid

from app.db.database import Base


class UserGroup(Base):
    __tablename__ = "user_groups"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String(36), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)

    # Group info
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)

    # RLS values - list of values this group can access (e.g., ["Store A", "Store B"])
    rls_values = Column(JSON, default=[])

    # Status
    is_active = Column(Boolean, default=True, index=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default=func.now())

    # Relationships
    tenant = relationship("Tenant", back_populates="user_groups")
    memberships = relationship("UserGroupMembership", back_populates="group", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<UserGroup(id={self.id}, name={self.name}, tenant_id={self.tenant_id})>"
