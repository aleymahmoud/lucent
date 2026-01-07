"""
Usage Stat Model - Tracks Usage for Quotas and Billing
"""
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid
import enum

from app.db.database import Base


class UsageAction(str, enum.Enum):
    FORECAST_RUN = "forecast_run"
    BATCH_FORECAST = "batch_forecast"
    DATA_UPLOAD = "data_upload"
    EXPORT = "export"
    CONNECTOR_FETCH = "connector_fetch"


class UsageStat(Base):
    __tablename__ = "usage_stats"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String(36), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)

    # Usage details
    action = Column(Enum(UsageAction), nullable=False, index=True)
    entity_count = Column(Integer, default=1)
    processing_time_ms = Column(Integer)

    # Timestamp
    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now(), index=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="usage_stats")
    user = relationship("User", back_populates="usage_stats")

    def __repr__(self):
        return f"<UsageStat(id={self.id}, action={self.action}, tenant_id={self.tenant_id})>"
