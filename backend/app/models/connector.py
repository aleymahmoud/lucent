"""
Connector Model - Data Connector Configurations (Encrypted)
"""
from sqlalchemy import Column, String, Boolean, Text, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid
import enum

from app.db.database import Base


class ConnectorType(str, enum.Enum):
    POSTGRES = "postgres"
    MYSQL = "mysql"
    SQLSERVER = "sqlserver"
    S3 = "s3"
    AZURE_BLOB = "azure_blob"
    GCS = "gcs"
    BIGQUERY = "bigquery"
    SNOWFLAKE = "snowflake"
    API = "api"


class Connector(Base):
    __tablename__ = "connectors"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String(36), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)

    # Connector details
    name = Column(String(255), nullable=False)
    type = Column(Enum(ConnectorType), nullable=False, index=True)

    # Encrypted configuration (JSON as encrypted text)
    config = Column(Text, nullable=False)  # Will be encrypted

    # Status
    is_active = Column(Boolean, default=True)
    last_tested_at = Column(DateTime, nullable=True)
    last_test_status = Column(String(50), nullable=True)

    # Creator
    created_by = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default=func.now())

    # Relationships
    tenant = relationship("Tenant", back_populates="connectors")
    creator = relationship("User", back_populates="created_connectors", foreign_keys=[created_by])
    rls_config = relationship("ConnectorRLS", back_populates="connector", uselist=False, cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Connector(id={self.id}, name={self.name}, type={self.type})>"
