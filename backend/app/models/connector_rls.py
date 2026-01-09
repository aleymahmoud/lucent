"""
ConnectorRLS Model - Row-Level Security configuration for data connectors
"""
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid

from app.db.database import Base


class ConnectorRLS(Base):
    __tablename__ = "connector_rls_configs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    connector_id = Column(String(36), ForeignKey("connectors.id", ondelete="CASCADE"), nullable=False, unique=True, index=True)

    # RLS column - the column name used for filtering (e.g., "store_name", "region", "department")
    rls_column = Column(String(255), nullable=False)

    # Status
    is_enabled = Column(Boolean, default=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default=func.now())

    # Relationships
    connector = relationship("Connector", back_populates="rls_config")

    def __repr__(self):
        return f"<ConnectorRLS(connector_id={self.connector_id}, rls_column={self.rls_column}, enabled={self.is_enabled})>"
