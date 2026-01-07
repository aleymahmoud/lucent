"""
Forecast History Model - Tracks Forecast Execution Metadata
"""
from sqlalchemy import Column, String, Integer, JSON, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid
import enum

from app.db.database import Base


class ForecastStatus(str, enum.Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class ForecastMethod(str, enum.Enum):
    ARIMA = "arima"
    ETS = "ets"
    PROPHET = "prophet"


class ForecastHistory(Base):
    __tablename__ = "forecast_history"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String(36), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)

    # Forecast details
    dataset_id = Column(String(36))  # Redis key reference
    entity_id = Column(String(255))
    method = Column(Enum(ForecastMethod), nullable=False)

    # Configuration snapshot
    config = Column(JSON)

    # Results summary
    status = Column(Enum(ForecastStatus), default=ForecastStatus.PENDING, index=True)
    error_message = Column(String(500))

    # Metrics
    mae = Column(Integer)  # Mean Absolute Error
    rmse = Column(Integer)  # Root Mean Square Error
    mape = Column(Integer)  # Mean Absolute Percentage Error

    # Performance
    processing_time_ms = Column(Integer)
    entity_count = Column(Integer, default=1)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now(), index=True)
    started_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="forecast_histories")
    user = relationship("User", back_populates="forecast_histories")

    def __repr__(self):
        return f"<ForecastHistory(id={self.id}, method={self.method}, status={self.status})>"
