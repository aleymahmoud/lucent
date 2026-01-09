"""
Admin API Endpoints - Platform Admin operations for managing tenants and users
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, delete
from sqlalchemy.orm import selectinload
from typing import Optional
import re

from app.core.deps import get_db, get_current_platform_admin
from app.core.security import get_password_hash
from app.models import Tenant, User, UserRole, PlatformAdmin
from app.schemas.admin import (
    TenantCreate,
    TenantUpdate,
    TenantResponse,
    TenantListResponse,
    AdminUserCreate,
    AdminUserResponse,
    AdminUserListResponse,
    PlatformStats,
)

router = APIRouter()


# ============================================
# Platform Stats
# ============================================

@router.get("/stats", response_model=PlatformStats)
async def get_platform_stats(
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get platform-wide statistics (Super Admin only)"""
    # Total tenants
    total_tenants = await db.scalar(select(func.count(Tenant.id)))
    active_tenants = await db.scalar(
        select(func.count(Tenant.id)).where(Tenant.is_active == True)
    )

    # Total users
    total_users = await db.scalar(select(func.count(User.id)))
    active_users = await db.scalar(
        select(func.count(User.id)).where(User.is_active == True)
    )

    # Pending approvals
    pending_approvals = await db.scalar(
        select(func.count(User.id)).where(User.is_approved == False, User.is_active == True)
    )

    return PlatformStats(
        total_tenants=total_tenants or 0,
        active_tenants=active_tenants or 0,
        total_users=total_users or 0,
        active_users=active_users or 0,
        pending_approvals=pending_approvals or 0
    )


# ============================================
# Tenant Management
# ============================================

@router.get("/tenants", response_model=TenantListResponse)
async def list_tenants(
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = None,
    is_active: Optional[bool] = None
):
    """List all tenants with user counts (Super Admin only)"""
    # Base query
    query = select(Tenant)
    count_query = select(func.count(Tenant.id))

    # Apply filters
    if search:
        search_filter = f"%{search}%"
        query = query.where(
            (Tenant.name.ilike(search_filter)) | (Tenant.slug.ilike(search_filter))
        )
        count_query = count_query.where(
            (Tenant.name.ilike(search_filter)) | (Tenant.slug.ilike(search_filter))
        )

    if is_active is not None:
        query = query.where(Tenant.is_active == is_active)
        count_query = count_query.where(Tenant.is_active == is_active)

    # Get total count
    total = await db.scalar(count_query)

    # Get tenants with pagination
    query = query.order_by(Tenant.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    tenants = result.scalars().all()

    # Get user counts for each tenant
    tenant_responses = []
    for tenant in tenants:
        user_count = await db.scalar(
            select(func.count(User.id)).where(User.tenant_id == tenant.id)
        )
        tenant_responses.append(TenantResponse(
            id=tenant.id,
            name=tenant.name,
            slug=tenant.slug,
            settings=tenant.settings or {},
            limits=tenant.limits or {},
            is_active=tenant.is_active,
            created_at=tenant.created_at,
            updated_at=tenant.updated_at,
            user_count=user_count or 0
        ))

    return TenantListResponse(tenants=tenant_responses, total=total or 0)


@router.post("/tenants", response_model=TenantResponse, status_code=status.HTTP_201_CREATED)
async def create_tenant(
    tenant_data: TenantCreate,
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create a new tenant (Super Admin only)"""
    # Check if slug already exists
    existing = await db.scalar(
        select(Tenant).where(Tenant.slug == tenant_data.slug)
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tenant with this slug already exists"
        )

    # Create tenant with default limits if not provided
    default_limits = {
        "max_users": 10,
        "max_file_size_mb": 100,
        "max_entities_per_batch": 50,
        "max_concurrent_forecasts": 3,
        "max_forecast_horizon": 365,
        "rate_limit_forecasts_per_hour": 20
    }

    tenant = Tenant(
        name=tenant_data.name,
        slug=tenant_data.slug,
        settings=tenant_data.settings or {},
        limits=tenant_data.limits or default_limits
    )

    db.add(tenant)
    await db.commit()
    await db.refresh(tenant)

    return TenantResponse(
        id=tenant.id,
        name=tenant.name,
        slug=tenant.slug,
        settings=tenant.settings or {},
        limits=tenant.limits or {},
        is_active=tenant.is_active,
        created_at=tenant.created_at,
        updated_at=tenant.updated_at,
        user_count=0
    )


@router.get("/tenants/{tenant_id}", response_model=TenantResponse)
async def get_tenant(
    tenant_id: str,
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific tenant (Super Admin only)"""
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tenant not found"
        )

    user_count = await db.scalar(
        select(func.count(User.id)).where(User.tenant_id == tenant.id)
    )

    return TenantResponse(
        id=tenant.id,
        name=tenant.name,
        slug=tenant.slug,
        settings=tenant.settings or {},
        limits=tenant.limits or {},
        is_active=tenant.is_active,
        created_at=tenant.created_at,
        updated_at=tenant.updated_at,
        user_count=user_count or 0
    )


@router.put("/tenants/{tenant_id}", response_model=TenantResponse)
async def update_tenant(
    tenant_id: str,
    tenant_data: TenantUpdate,
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update a tenant (Super Admin only)"""
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tenant not found"
        )

    # Check if new slug already exists (if changing slug)
    if tenant_data.slug and tenant_data.slug != tenant.slug:
        existing = await db.scalar(
            select(Tenant).where(Tenant.slug == tenant_data.slug, Tenant.id != tenant_id)
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tenant with this slug already exists"
            )

    # Update fields
    update_data = tenant_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(tenant, field, value)

    await db.commit()
    await db.refresh(tenant)

    user_count = await db.scalar(
        select(func.count(User.id)).where(User.tenant_id == tenant.id)
    )

    return TenantResponse(
        id=tenant.id,
        name=tenant.name,
        slug=tenant.slug,
        settings=tenant.settings or {},
        limits=tenant.limits or {},
        is_active=tenant.is_active,
        created_at=tenant.created_at,
        updated_at=tenant.updated_at,
        user_count=user_count or 0
    )


@router.delete("/tenants/{tenant_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tenant(
    tenant_id: str,
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a tenant and all associated data (Super Admin only)"""
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tenant not found"
        )

    await db.delete(tenant)
    await db.commit()


# ============================================
# Tenant Admin User Creation
# ============================================

@router.post("/tenants/{tenant_id}/admin", response_model=AdminUserResponse, status_code=status.HTTP_201_CREATED)
async def create_tenant_admin(
    tenant_id: str,
    user_data: AdminUserCreate,
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create a tenant admin user (Super Admin only)"""
    # Verify tenant exists
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Tenant not found"
        )

    # Check if email already exists
    existing_user = await db.scalar(
        select(User).where(User.email == user_data.email)
    )
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )

    # Map role string to enum
    role_map = {
        "admin": UserRole.ADMIN,
        "analyst": UserRole.ANALYST,
        "viewer": UserRole.VIEWER
    }
    role = role_map.get(user_data.role.lower(), UserRole.ADMIN)

    # Create user
    user = User(
        email=user_data.email,
        password_hash=get_password_hash(user_data.password),
        full_name=user_data.full_name,
        role=role,
        tenant_id=tenant_id,
        is_active=True,
        is_approved=True  # Auto-approve users created by super admin
    )

    db.add(user)
    await db.commit()
    await db.refresh(user)

    return AdminUserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value,
        tenant_id=user.tenant_id,
        tenant_name=tenant.name,
        is_active=user.is_active,
        is_approved=user.is_approved,
        created_at=user.created_at,
        last_login=user.last_login
    )


# ============================================
# User Management (All Tenants)
# ============================================

@router.get("/users", response_model=AdminUserListResponse)
async def list_all_users(
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    tenant_id: Optional[str] = None,
    search: Optional[str] = None,
    is_active: Optional[bool] = None,
    is_approved: Optional[bool] = None,
    role: Optional[str] = None
):
    """List all users across all tenants (Super Admin only)"""
    # Base query with tenant join
    query = select(User).options(selectinload(User.tenant))
    count_query = select(func.count(User.id))

    # Apply filters
    if tenant_id:
        query = query.where(User.tenant_id == tenant_id)
        count_query = count_query.where(User.tenant_id == tenant_id)

    if search:
        search_filter = f"%{search}%"
        query = query.where(
            (User.email.ilike(search_filter)) | (User.full_name.ilike(search_filter))
        )
        count_query = count_query.where(
            (User.email.ilike(search_filter)) | (User.full_name.ilike(search_filter))
        )

    if is_active is not None:
        query = query.where(User.is_active == is_active)
        count_query = count_query.where(User.is_active == is_active)

    if is_approved is not None:
        query = query.where(User.is_approved == is_approved)
        count_query = count_query.where(User.is_approved == is_approved)

    if role:
        try:
            role_enum = UserRole(role.upper())
            query = query.where(User.role == role_enum)
            count_query = count_query.where(User.role == role_enum)
        except ValueError:
            pass  # Invalid role, ignore filter

    # Get total count
    total = await db.scalar(count_query)

    # Get users with pagination
    query = query.order_by(User.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    users = result.scalars().all()

    user_responses = [
        AdminUserResponse(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            role=user.role.value if user.role else "analyst",
            tenant_id=user.tenant_id,
            tenant_name=user.tenant.name if user.tenant else None,
            is_active=user.is_active,
            is_approved=user.is_approved,
            created_at=user.created_at,
            last_login=user.last_login
        )
        for user in users
    ]

    return AdminUserListResponse(users=user_responses, total=total or 0)


@router.put("/users/{user_id}/approve", response_model=AdminUserResponse)
async def approve_user(
    user_id: str,
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db)
):
    """Approve a pending user (Super Admin only)"""
    result = await db.execute(
        select(User).options(selectinload(User.tenant)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    user.is_approved = True
    await db.commit()
    await db.refresh(user)

    return AdminUserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value if user.role else "analyst",
        tenant_id=user.tenant_id,
        tenant_name=user.tenant.name if user.tenant else None,
        is_active=user.is_active,
        is_approved=user.is_approved,
        created_at=user.created_at,
        last_login=user.last_login
    )


@router.put("/users/{user_id}/toggle-active", response_model=AdminUserResponse)
async def toggle_user_active(
    user_id: str,
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db)
):
    """Toggle user active status (Super Admin only)"""
    result = await db.execute(
        select(User).options(selectinload(User.tenant)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    user.is_active = not user.is_active
    await db.commit()
    await db.refresh(user)

    return AdminUserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value if user.role else "analyst",
        tenant_id=user.tenant_id,
        tenant_name=user.tenant.name if user.tenant else None,
        is_active=user.is_active,
        is_approved=user.is_approved,
        created_at=user.created_at,
        last_login=user.last_login
    )


@router.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: str,
    current_admin: PlatformAdmin = Depends(get_current_platform_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a user (Super Admin only)"""
    user = await db.get(User, user_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    await db.delete(user)
    await db.commit()
