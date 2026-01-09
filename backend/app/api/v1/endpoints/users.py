"""
Users API Endpoints - Tenant Admin operations for managing users within their tenant
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import Optional

from app.core.deps import get_db, get_current_admin
from app.core.security import get_password_hash
from app.models import User, UserRole, UserGroup, UserGroupMembership, Connector
from app.schemas.users import (
    TenantUserCreate,
    TenantUserUpdate,
    TenantUserResponse,
    TenantUserListResponse,
    TenantStats,
    GroupMembershipInfo,
)

router = APIRouter()


# ============================================
# Tenant Stats
# ============================================

@router.get("/stats", response_model=TenantStats)
async def get_tenant_stats(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get statistics for the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Total users in tenant
    total_users = await db.scalar(
        select(func.count(User.id)).where(User.tenant_id == tenant_id)
    )

    # Active users
    active_users = await db.scalar(
        select(func.count(User.id)).where(
            User.tenant_id == tenant_id,
            User.is_active == True
        )
    )

    # Pending approvals
    pending_approvals = await db.scalar(
        select(func.count(User.id)).where(
            User.tenant_id == tenant_id,
            User.is_approved == False,
            User.is_active == True
        )
    )

    # Total groups
    total_groups = await db.scalar(
        select(func.count(UserGroup.id)).where(UserGroup.tenant_id == tenant_id)
    )

    # Total connectors
    total_connectors = await db.scalar(
        select(func.count(Connector.id)).where(Connector.tenant_id == tenant_id)
    )

    return TenantStats(
        total_users=total_users or 0,
        active_users=active_users or 0,
        pending_approvals=pending_approvals or 0,
        total_groups=total_groups or 0,
        total_connectors=total_connectors or 0
    )


# ============================================
# User CRUD Operations
# ============================================

@router.get("", response_model=TenantUserListResponse)
async def list_tenant_users(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = None,
    is_active: Optional[bool] = None,
    is_approved: Optional[bool] = None,
    role: Optional[str] = None
):
    """List all users in the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Base query - users in same tenant
    query = select(User).where(User.tenant_id == tenant_id)
    count_query = select(func.count(User.id)).where(User.tenant_id == tenant_id)

    # Apply filters
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
            role_enum = UserRole(role.lower())
            query = query.where(User.role == role_enum)
            count_query = count_query.where(User.role == role_enum)
        except ValueError:
            pass  # Invalid role, ignore filter

    # Get total count
    total = await db.scalar(count_query)

    # Get users with pagination and group memberships
    query = (
        query
        .options(selectinload(User.group_memberships).selectinload(UserGroupMembership.group))
        .order_by(User.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    result = await db.execute(query)
    users = result.scalars().all()

    # Build response
    user_responses = []
    for user in users:
        groups = [
            GroupMembershipInfo(id=m.group.id, name=m.group.name)
            for m in user.group_memberships
            if m.group and m.group.is_active
        ]
        user_responses.append(TenantUserResponse(
            id=user.id,
            email=user.email,
            full_name=user.full_name,
            role=user.role.value if user.role else "analyst",
            is_active=user.is_active,
            is_approved=user.is_approved,
            created_at=user.created_at,
            last_login=user.last_login,
            groups=groups
        ))

    return TenantUserListResponse(users=user_responses, total=total or 0)


@router.post("", response_model=TenantUserResponse, status_code=status.HTTP_201_CREATED)
async def create_tenant_user(
    user_data: TenantUserCreate,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create a new user in the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

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
    role = role_map.get(user_data.role.lower(), UserRole.ANALYST)

    # Create user
    user = User(
        email=user_data.email,
        password_hash=get_password_hash(user_data.password),
        full_name=user_data.full_name,
        role=role,
        tenant_id=tenant_id,
        is_active=True,
        is_approved=True  # Auto-approve users created by tenant admin
    )

    db.add(user)
    await db.commit()
    await db.refresh(user)

    return TenantUserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value,
        is_active=user.is_active,
        is_approved=user.is_approved,
        created_at=user.created_at,
        last_login=user.last_login,
        groups=[]
    )


@router.get("/{user_id}", response_model=TenantUserResponse)
async def get_tenant_user(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific user in the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    result = await db.execute(
        select(User)
        .options(selectinload(User.group_memberships).selectinload(UserGroupMembership.group))
        .where(User.id == user_id, User.tenant_id == tenant_id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    groups = [
        GroupMembershipInfo(id=m.group.id, name=m.group.name)
        for m in user.group_memberships
        if m.group and m.group.is_active
    ]

    return TenantUserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value if user.role else "analyst",
        is_active=user.is_active,
        is_approved=user.is_approved,
        created_at=user.created_at,
        last_login=user.last_login,
        groups=groups
    )


@router.put("/{user_id}", response_model=TenantUserResponse)
async def update_tenant_user(
    user_id: str,
    user_data: TenantUserUpdate,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update a user in the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    result = await db.execute(
        select(User)
        .options(selectinload(User.group_memberships).selectinload(UserGroupMembership.group))
        .where(User.id == user_id, User.tenant_id == tenant_id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Prevent modifying super admins
    if user.is_super_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot modify a super admin user"
        )

    # Prevent demoting yourself if you're the only admin
    if user.id == current_user.id and user_data.role and user_data.role.lower() != "admin":
        admin_count = await db.scalar(
            select(func.count(User.id)).where(
                User.tenant_id == tenant_id,
                User.role == UserRole.ADMIN,
                User.is_active == True
            )
        )
        if admin_count <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot demote yourself when you are the only admin"
            )

    # Update fields
    update_data = user_data.model_dump(exclude_unset=True)

    if "role" in update_data:
        role_map = {
            "admin": UserRole.ADMIN,
            "analyst": UserRole.ANALYST,
            "viewer": UserRole.VIEWER
        }
        update_data["role"] = role_map.get(update_data["role"].lower(), UserRole.ANALYST)

    for field, value in update_data.items():
        setattr(user, field, value)

    await db.commit()
    await db.refresh(user)

    groups = [
        GroupMembershipInfo(id=m.group.id, name=m.group.name)
        for m in user.group_memberships
        if m.group and m.group.is_active
    ]

    return TenantUserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value if user.role else "analyst",
        is_active=user.is_active,
        is_approved=user.is_approved,
        created_at=user.created_at,
        last_login=user.last_login,
        groups=groups
    )


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tenant_user(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a user from the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    user = await db.scalar(
        select(User).where(User.id == user_id, User.tenant_id == tenant_id)
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Prevent deleting yourself
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete yourself"
        )

    # Prevent deleting super admins
    if user.is_super_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot delete a super admin user"
        )

    await db.delete(user)
    await db.commit()


# ============================================
# User Approval Operations
# ============================================

@router.put("/{user_id}/approve", response_model=TenantUserResponse)
async def approve_tenant_user(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Approve a pending user in the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    result = await db.execute(
        select(User)
        .options(selectinload(User.group_memberships).selectinload(UserGroupMembership.group))
        .where(User.id == user_id, User.tenant_id == tenant_id)
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

    groups = [
        GroupMembershipInfo(id=m.group.id, name=m.group.name)
        for m in user.group_memberships
        if m.group and m.group.is_active
    ]

    return TenantUserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value if user.role else "analyst",
        is_active=user.is_active,
        is_approved=user.is_approved,
        created_at=user.created_at,
        last_login=user.last_login,
        groups=groups
    )


@router.put("/{user_id}/toggle-active", response_model=TenantUserResponse)
async def toggle_tenant_user_active(
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Toggle user active status in the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    result = await db.execute(
        select(User)
        .options(selectinload(User.group_memberships).selectinload(UserGroupMembership.group))
        .where(User.id == user_id, User.tenant_id == tenant_id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Prevent deactivating yourself
    if user.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot deactivate yourself"
        )

    # Prevent modifying super admins
    if user.is_super_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot modify a super admin user"
        )

    user.is_active = not user.is_active
    await db.commit()
    await db.refresh(user)

    groups = [
        GroupMembershipInfo(id=m.group.id, name=m.group.name)
        for m in user.group_memberships
        if m.group and m.group.is_active
    ]

    return TenantUserResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role.value if user.role else "analyst",
        is_active=user.is_active,
        is_approved=user.is_approved,
        created_at=user.created_at,
        last_login=user.last_login,
        groups=groups
    )
