"""
User Model - User Accounts with Tenant Association
"""
from sqlalchemy import Column, String, Boolean, JSON, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid
import enum

from app.db.database import Base


class UserRole(str, enum.Enum):
    ADMIN = "admin"
    ANALYST = "analyst"
    VIEWER = "viewer"


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String(36), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)

    # Authentication
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)

    # Profile
    full_name = Column(String(255))
    role = Column(Enum(UserRole), default=UserRole.ANALYST)

    # User settings
    settings = Column(JSON, default={})

    # Activity tracking
    last_login = Column(DateTime, nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default=func.now())

    # Status
    is_active = Column(Boolean, default=True, index=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="users")
    created_connectors = relationship("Connector", back_populates="creator", foreign_keys="Connector.created_by")
    audit_logs = relationship("AuditLog", back_populates="user")
    usage_stats = relationship("UsageStat", back_populates="user")
    forecast_histories = relationship("ForecastHistory", back_populates="user")

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, role={self.role})>"
