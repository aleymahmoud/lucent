"""
Tenant Model - Organization/Company Information
"""
from sqlalchemy import Column, String, Boolean, JSON, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid

from app.db.database import Base


class Tenant(Base):
    __tablename__ = "tenants"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False)
    slug = Column(String(100), unique=True, nullable=False, index=True)

    # JSON field for tenant settings
    settings = Column(JSON, default={})

    # JSON field for usage limits
    limits = Column(JSON, default={
        "max_users": 10,
        "max_file_size_mb": 100,
        "max_entities_per_batch": 50,
        "max_concurrent_forecasts": 3,
        "max_forecast_horizon": 365,
        "rate_limit_forecasts_per_hour": 20
    })

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default=func.now())

    # Status
    is_active = Column(Boolean, default=True, index=True)

    # Relationships
    users = relationship("User", back_populates="tenant", cascade="all, delete-orphan")
    connectors = relationship("Connector", back_populates="tenant", cascade="all, delete-orphan")
    audit_logs = relationship("AuditLog", back_populates="tenant", cascade="all, delete-orphan")
    usage_stats = relationship("UsageStat", back_populates="tenant", cascade="all, delete-orphan")
    forecast_histories = relationship("ForecastHistory", back_populates="tenant", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Tenant(id={self.id}, name={self.name}, slug={self.slug})>"
