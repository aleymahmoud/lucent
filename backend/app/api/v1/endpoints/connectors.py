"""
Connectors API Endpoints - Tenant Admin operations for managing connector RLS
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import Optional

from app.core.deps import get_db, get_current_admin, get_current_user
from app.models import User, Connector, ConnectorRLS
from app.schemas.connectors import (
    ConnectorRLSCreate,
    ConnectorRLSUpdate,
    ConnectorRLSResponse,
    ConnectorBasicResponse,
    ConnectorListResponse,
    ConnectorColumnsResponse,
)
from app.services.connector_service import get_connector_columns_from_db

router = APIRouter()


# ============================================
# Connector List with RLS Info
# ============================================

@router.get("", response_model=ConnectorListResponse)
async def list_connectors(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = None,
    is_active: Optional[bool] = None
):
    """List all connectors in the current tenant with RLS config (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Base query
    query = select(Connector).where(Connector.tenant_id == tenant_id)
    count_query = select(func.count(Connector.id)).where(Connector.tenant_id == tenant_id)

    # Apply filters
    if search:
        search_filter = f"%{search}%"
        query = query.where(Connector.name.ilike(search_filter))
        count_query = count_query.where(Connector.name.ilike(search_filter))

    if is_active is not None:
        query = query.where(Connector.is_active == is_active)
        count_query = count_query.where(Connector.is_active == is_active)

    # Get total count
    total = await db.scalar(count_query)

    # Get connectors with RLS config
    query = (
        query
        .options(selectinload(Connector.rls_config))
        .order_by(Connector.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    result = await db.execute(query)
    connectors = result.scalars().all()

    # Build response
    connector_responses = []
    for connector in connectors:
        rls_config = None
        if connector.rls_config:
            rls_config = ConnectorRLSResponse(
                id=connector.rls_config.id,
                connector_id=connector.rls_config.connector_id,
                rls_column=connector.rls_config.rls_column,
                is_enabled=connector.rls_config.is_enabled,
                created_at=connector.rls_config.created_at,
                updated_at=connector.rls_config.updated_at
            )

        connector_responses.append(ConnectorBasicResponse(
            id=connector.id,
            name=connector.name,
            type=connector.type.value,
            is_active=connector.is_active,
            created_at=connector.created_at,
            rls_config=rls_config
        ))

    return ConnectorListResponse(connectors=connector_responses, total=total or 0)


@router.get("/{connector_id}", response_model=ConnectorBasicResponse)
async def get_connector(
    connector_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific connector with RLS config (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    result = await db.execute(
        select(Connector)
        .options(selectinload(Connector.rls_config))
        .where(Connector.id == connector_id, Connector.tenant_id == tenant_id)
    )
    connector = result.scalar_one_or_none()

    if not connector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connector not found"
        )

    rls_config = None
    if connector.rls_config:
        rls_config = ConnectorRLSResponse(
            id=connector.rls_config.id,
            connector_id=connector.rls_config.connector_id,
            rls_column=connector.rls_config.rls_column,
            is_enabled=connector.rls_config.is_enabled,
            created_at=connector.rls_config.created_at,
            updated_at=connector.rls_config.updated_at
        )

    return ConnectorBasicResponse(
        id=connector.id,
        name=connector.name,
        type=connector.type.value,
        is_active=connector.is_active,
        created_at=connector.created_at,
        rls_config=rls_config
    )


# ============================================
# RLS Configuration Operations
# ============================================

@router.get("/{connector_id}/rls", response_model=ConnectorRLSResponse)
async def get_connector_rls(
    connector_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get RLS configuration for a connector (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify connector exists and belongs to tenant
    connector = await db.scalar(
        select(Connector).where(Connector.id == connector_id, Connector.tenant_id == tenant_id)
    )
    if not connector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connector not found"
        )

    # Get RLS config
    rls_config = await db.scalar(
        select(ConnectorRLS).where(ConnectorRLS.connector_id == connector_id)
    )

    if not rls_config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="RLS configuration not found for this connector"
        )

    return ConnectorRLSResponse(
        id=rls_config.id,
        connector_id=rls_config.connector_id,
        rls_column=rls_config.rls_column,
        is_enabled=rls_config.is_enabled,
        created_at=rls_config.created_at,
        updated_at=rls_config.updated_at
    )


@router.post("/{connector_id}/rls", response_model=ConnectorRLSResponse, status_code=status.HTTP_201_CREATED)
async def create_connector_rls(
    connector_id: str,
    rls_data: ConnectorRLSCreate,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create RLS configuration for a connector (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify connector exists and belongs to tenant
    connector = await db.scalar(
        select(Connector).where(Connector.id == connector_id, Connector.tenant_id == tenant_id)
    )
    if not connector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connector not found"
        )

    # Check if RLS config already exists
    existing_rls = await db.scalar(
        select(ConnectorRLS).where(ConnectorRLS.connector_id == connector_id)
    )
    if existing_rls:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="RLS configuration already exists for this connector. Use PUT to update."
        )

    # Create RLS config
    rls_config = ConnectorRLS(
        connector_id=connector_id,
        rls_column=rls_data.rls_column,
        is_enabled=rls_data.is_enabled
    )

    db.add(rls_config)
    await db.commit()
    await db.refresh(rls_config)

    return ConnectorRLSResponse(
        id=rls_config.id,
        connector_id=rls_config.connector_id,
        rls_column=rls_config.rls_column,
        is_enabled=rls_config.is_enabled,
        created_at=rls_config.created_at,
        updated_at=rls_config.updated_at
    )


@router.put("/{connector_id}/rls", response_model=ConnectorRLSResponse)
async def update_connector_rls(
    connector_id: str,
    rls_data: ConnectorRLSUpdate,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update RLS configuration for a connector (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify connector exists and belongs to tenant
    connector = await db.scalar(
        select(Connector).where(Connector.id == connector_id, Connector.tenant_id == tenant_id)
    )
    if not connector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connector not found"
        )

    # Get RLS config
    rls_config = await db.scalar(
        select(ConnectorRLS).where(ConnectorRLS.connector_id == connector_id)
    )

    if not rls_config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="RLS configuration not found for this connector"
        )

    # Update fields
    update_data = rls_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(rls_config, field, value)

    await db.commit()
    await db.refresh(rls_config)

    return ConnectorRLSResponse(
        id=rls_config.id,
        connector_id=rls_config.connector_id,
        rls_column=rls_config.rls_column,
        is_enabled=rls_config.is_enabled,
        created_at=rls_config.created_at,
        updated_at=rls_config.updated_at
    )


@router.delete("/{connector_id}/rls", status_code=status.HTTP_204_NO_CONTENT)
async def delete_connector_rls(
    connector_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete RLS configuration for a connector (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify connector exists and belongs to tenant
    connector = await db.scalar(
        select(Connector).where(Connector.id == connector_id, Connector.tenant_id == tenant_id)
    )
    if not connector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connector not found"
        )

    # Get RLS config
    rls_config = await db.scalar(
        select(ConnectorRLS).where(ConnectorRLS.connector_id == connector_id)
    )

    if not rls_config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="RLS configuration not found for this connector"
        )

    await db.delete(rls_config)
    await db.commit()


@router.put("/{connector_id}/rls/toggle", response_model=ConnectorRLSResponse)
async def toggle_connector_rls(
    connector_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Toggle RLS enabled/disabled for a connector (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify connector exists and belongs to tenant
    connector = await db.scalar(
        select(Connector).where(Connector.id == connector_id, Connector.tenant_id == tenant_id)
    )
    if not connector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connector not found"
        )

    # Get RLS config
    rls_config = await db.scalar(
        select(ConnectorRLS).where(ConnectorRLS.connector_id == connector_id)
    )

    if not rls_config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="RLS configuration not found for this connector"
        )

    # Toggle enabled state
    rls_config.is_enabled = not rls_config.is_enabled
    await db.commit()
    await db.refresh(rls_config)

    return ConnectorRLSResponse(
        id=rls_config.id,
        connector_id=rls_config.connector_id,
        rls_column=rls_config.rls_column,
        is_enabled=rls_config.is_enabled,
        created_at=rls_config.created_at,
        updated_at=rls_config.updated_at
    )


# ============================================
# Connector Column Discovery
# ============================================

@router.get("/{connector_id}/columns", response_model=ConnectorColumnsResponse)
async def get_connector_columns(
    connector_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get column names from a connector's data source (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify connector exists and belongs to tenant
    connector = await db.scalar(
        select(Connector).where(Connector.id == connector_id, Connector.tenant_id == tenant_id)
    )
    if not connector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Connector not found"
        )

    try:
        columns = await get_connector_columns_from_db(connector)
        return ConnectorColumnsResponse(columns=columns)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to get columns: {str(e)}"
        )
