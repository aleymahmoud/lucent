"""
Groups API Endpoints - Tenant Admin operations for managing user groups and RLS values
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, delete
from sqlalchemy.orm import selectinload
from typing import Optional, List

from app.core.deps import get_db, get_current_admin
from app.models import User, UserRole, UserGroup, UserGroupMembership
from app.schemas.groups import (
    GroupCreate,
    GroupUpdate,
    GroupResponse,
    GroupDetailResponse,
    GroupListResponse,
    GroupMemberInfo,
    AddGroupMember,
    AddGroupMembers,
    GroupMembershipResponse,
)

router = APIRouter()


# ============================================
# Group CRUD Operations
# ============================================

@router.get("", response_model=GroupListResponse)
async def list_groups(
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = None,
    is_active: Optional[bool] = None
):
    """List all user groups in the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Base query
    query = select(UserGroup).where(UserGroup.tenant_id == tenant_id)
    count_query = select(func.count(UserGroup.id)).where(UserGroup.tenant_id == tenant_id)

    # Apply filters
    if search:
        search_filter = f"%{search}%"
        query = query.where(
            (UserGroup.name.ilike(search_filter)) | (UserGroup.description.ilike(search_filter))
        )
        count_query = count_query.where(
            (UserGroup.name.ilike(search_filter)) | (UserGroup.description.ilike(search_filter))
        )

    if is_active is not None:
        query = query.where(UserGroup.is_active == is_active)
        count_query = count_query.where(UserGroup.is_active == is_active)

    # Get total count
    total = await db.scalar(count_query)

    # Get groups with pagination
    query = query.order_by(UserGroup.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    groups = result.scalars().all()

    # Build response with member counts
    group_responses = []
    for group in groups:
        member_count = await db.scalar(
            select(func.count(UserGroupMembership.id)).where(
                UserGroupMembership.group_id == group.id
            )
        )
        group_responses.append(GroupResponse(
            id=group.id,
            name=group.name,
            description=group.description,
            rls_values=group.rls_values or [],
            is_active=group.is_active,
            created_at=group.created_at,
            updated_at=group.updated_at,
            member_count=member_count or 0
        ))

    return GroupListResponse(groups=group_responses, total=total or 0)


@router.post("", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
async def create_group(
    group_data: GroupCreate,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Create a new user group in the current tenant (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Check if group name already exists in this tenant
    existing_group = await db.scalar(
        select(UserGroup).where(
            UserGroup.tenant_id == tenant_id,
            UserGroup.name == group_data.name
        )
    )
    if existing_group:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A group with this name already exists in your organization"
        )

    # Create group
    group = UserGroup(
        tenant_id=tenant_id,
        name=group_data.name,
        description=group_data.description,
        rls_values=group_data.rls_values or []
    )

    db.add(group)
    await db.commit()
    await db.refresh(group)

    return GroupResponse(
        id=group.id,
        name=group.name,
        description=group.description,
        rls_values=group.rls_values or [],
        is_active=group.is_active,
        created_at=group.created_at,
        updated_at=group.updated_at,
        member_count=0
    )


@router.get("/{group_id}", response_model=GroupDetailResponse)
async def get_group(
    group_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific user group with members (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    result = await db.execute(
        select(UserGroup)
        .options(selectinload(UserGroup.memberships).selectinload(UserGroupMembership.user))
        .where(UserGroup.id == group_id, UserGroup.tenant_id == tenant_id)
    )
    group = result.scalar_one_or_none()

    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )

    # Build member list
    members = [
        GroupMemberInfo(
            id=m.user.id,
            email=m.user.email,
            full_name=m.user.full_name,
            role=m.user.role.value if m.user.role else "analyst"
        )
        for m in group.memberships
        if m.user and m.user.is_active
    ]

    return GroupDetailResponse(
        id=group.id,
        name=group.name,
        description=group.description,
        rls_values=group.rls_values or [],
        is_active=group.is_active,
        created_at=group.created_at,
        updated_at=group.updated_at,
        members=members
    )


@router.put("/{group_id}", response_model=GroupResponse)
async def update_group(
    group_id: str,
    group_data: GroupUpdate,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Update a user group (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    group = await db.scalar(
        select(UserGroup).where(UserGroup.id == group_id, UserGroup.tenant_id == tenant_id)
    )

    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )

    # Check if new name already exists (if changing name)
    if group_data.name and group_data.name != group.name:
        existing_group = await db.scalar(
            select(UserGroup).where(
                UserGroup.tenant_id == tenant_id,
                UserGroup.name == group_data.name,
                UserGroup.id != group_id
            )
        )
        if existing_group:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A group with this name already exists in your organization"
            )

    # Update fields
    update_data = group_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(group, field, value)

    await db.commit()
    await db.refresh(group)

    # Get member count
    member_count = await db.scalar(
        select(func.count(UserGroupMembership.id)).where(
            UserGroupMembership.group_id == group.id
        )
    )

    return GroupResponse(
        id=group.id,
        name=group.name,
        description=group.description,
        rls_values=group.rls_values or [],
        is_active=group.is_active,
        created_at=group.created_at,
        updated_at=group.updated_at,
        member_count=member_count or 0
    )


@router.delete("/{group_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_group(
    group_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Delete a user group (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    group = await db.scalar(
        select(UserGroup).where(UserGroup.id == group_id, UserGroup.tenant_id == tenant_id)
    )

    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )

    await db.delete(group)
    await db.commit()


# ============================================
# Group Membership Operations
# ============================================

@router.post("/{group_id}/members", response_model=GroupMembershipResponse)
async def add_group_member(
    group_id: str,
    member_data: AddGroupMember,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Add a single member to a group (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify group exists and belongs to tenant
    group = await db.scalar(
        select(UserGroup).where(UserGroup.id == group_id, UserGroup.tenant_id == tenant_id)
    )
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )

    # Verify user exists and belongs to tenant
    user = await db.scalar(
        select(User).where(User.id == member_data.user_id, User.tenant_id == tenant_id)
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Check if membership already exists
    existing_membership = await db.scalar(
        select(UserGroupMembership).where(
            UserGroupMembership.group_id == group_id,
            UserGroupMembership.user_id == member_data.user_id
        )
    )
    if existing_membership:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already a member of this group"
        )

    # Create membership
    membership = UserGroupMembership(
        group_id=group_id,
        user_id=member_data.user_id
    )
    db.add(membership)
    await db.commit()

    return GroupMembershipResponse(
        message="Member added successfully",
        group_id=group_id,
        added_count=1
    )


@router.post("/{group_id}/members/bulk", response_model=GroupMembershipResponse)
async def add_group_members_bulk(
    group_id: str,
    members_data: AddGroupMembers,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Add multiple members to a group (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify group exists and belongs to tenant
    group = await db.scalar(
        select(UserGroup).where(UserGroup.id == group_id, UserGroup.tenant_id == tenant_id)
    )
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )

    # Verify all users exist and belong to tenant
    result = await db.execute(
        select(User.id).where(
            User.id.in_(members_data.user_ids),
            User.tenant_id == tenant_id
        )
    )
    valid_user_ids = set(row[0] for row in result.fetchall())

    if len(valid_user_ids) != len(members_data.user_ids):
        invalid_ids = set(members_data.user_ids) - valid_user_ids
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Some users not found or not in your organization: {list(invalid_ids)}"
        )

    # Get existing memberships
    result = await db.execute(
        select(UserGroupMembership.user_id).where(
            UserGroupMembership.group_id == group_id,
            UserGroupMembership.user_id.in_(members_data.user_ids)
        )
    )
    existing_user_ids = set(row[0] for row in result.fetchall())

    # Create new memberships for users not already in group
    new_user_ids = valid_user_ids - existing_user_ids
    added_count = 0

    for user_id in new_user_ids:
        membership = UserGroupMembership(
            group_id=group_id,
            user_id=user_id
        )
        db.add(membership)
        added_count += 1

    await db.commit()

    return GroupMembershipResponse(
        message=f"Added {added_count} members to group",
        group_id=group_id,
        added_count=added_count
    )


@router.delete("/{group_id}/members/{user_id}", response_model=GroupMembershipResponse)
async def remove_group_member(
    group_id: str,
    user_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Remove a member from a group (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify group exists and belongs to tenant
    group = await db.scalar(
        select(UserGroup).where(UserGroup.id == group_id, UserGroup.tenant_id == tenant_id)
    )
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )

    # Find and delete membership
    membership = await db.scalar(
        select(UserGroupMembership).where(
            UserGroupMembership.group_id == group_id,
            UserGroupMembership.user_id == user_id
        )
    )

    if not membership:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User is not a member of this group"
        )

    await db.delete(membership)
    await db.commit()

    return GroupMembershipResponse(
        message="Member removed successfully",
        group_id=group_id,
        removed_count=1
    )


@router.delete("/{group_id}/members", response_model=GroupMembershipResponse)
async def remove_all_group_members(
    group_id: str,
    current_user: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """Remove all members from a group (Tenant Admin only)"""
    tenant_id = current_user.tenant_id

    # Verify group exists and belongs to tenant
    group = await db.scalar(
        select(UserGroup).where(UserGroup.id == group_id, UserGroup.tenant_id == tenant_id)
    )
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )

    # Count and delete all memberships
    count = await db.scalar(
        select(func.count(UserGroupMembership.id)).where(
            UserGroupMembership.group_id == group_id
        )
    )

    await db.execute(
        delete(UserGroupMembership).where(UserGroupMembership.group_id == group_id)
    )
    await db.commit()

    return GroupMembershipResponse(
        message=f"Removed {count or 0} members from group",
        group_id=group_id,
        removed_count=count or 0
    )
