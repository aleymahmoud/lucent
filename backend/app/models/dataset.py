"""
Dataset Model - Uploaded data files
"""
from sqlalchemy import Column, String, Boolean, JSON, DateTime, Integer, BigInteger, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime
import uuid

from app.db.database import Base


class Dataset(Base):
    __tablename__ = "datasets"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    tenant_id = Column(String(36), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)

    # File info
    name = Column(String(255), nullable=False)  # User-friendly name
    filename = Column(String(255), nullable=False)  # Original filename
    file_path = Column(String(500), nullable=True)  # Path to stored file (if stored)
    file_size = Column(BigInteger, nullable=False)  # Size in bytes
    file_type = Column(String(50), nullable=False)  # csv, xlsx, etc.

    # Data stats
    row_count = Column(Integer, nullable=True)
    column_count = Column(Integer, nullable=True)
    entity_column = Column(String(100), nullable=True)  # Column used to identify entities
    date_column = Column(String(100), nullable=True)  # Column containing dates
    value_column = Column(String(100), nullable=True)  # Column containing values to forecast

    # Parsed metadata
    columns = Column(JSON, default=[])  # List of column names
    column_types = Column(JSON, default={})  # Column name -> type mapping
    date_range = Column(JSON, default={})  # {start: string, end: string}
    entities = Column(JSON, default=[])  # List of unique entity values

    # Data summary (cached)
    summary = Column(JSON, default={})  # Cached summary statistics

    # Session-based: data stored in Redis
    redis_key = Column(String(100), nullable=True)  # Key for Redis cached data

    # Upload info
    uploaded_by = Column(String(36), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    uploaded_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())

    # Status
    is_processed = Column(Boolean, default=False)  # Whether initial processing is complete
    processing_error = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, index=True)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, server_default=func.now())
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, server_default=func.now())
    expires_at = Column(DateTime, nullable=True)  # For session-based expiry

    # Relationships
    tenant = relationship("Tenant", backref="datasets")
    uploader = relationship("User", backref="uploaded_datasets")

    def __repr__(self):
        return f"<Dataset(id={self.id}, name={self.name}, tenant_id={self.tenant_id})>"

    @property
    def size_mb(self):
        """Return file size in MB"""
        return round(self.file_size / (1024 * 1024), 2) if self.file_size else 0
