"""
Platform Admin Authentication Endpoints
Completely separate from tenant user authentication
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
from pydantic import BaseModel, EmailStr
from typing import Optional

from app.core.deps import get_db, get_current_platform_admin
from app.core.security import verify_password, get_password_hash, create_access_token
from app.models.platform_admin import PlatformAdmin

router = APIRouter()


# ============================================
# Schemas
# ============================================

class PlatformAdminLogin(BaseModel):
    email: EmailStr
    password: str


class PlatformAdminResponse(BaseModel):
    id: str
    email: str
    full_name: Optional[str]
    is_active: bool
    created_at: datetime
    last_login: Optional[datetime]

    class Config:
        from_attributes = True


class PlatformAuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    admin: PlatformAdminResponse


# ============================================
# Endpoints
# ============================================

@router.post("/login", response_model=PlatformAuthResponse)
async def platform_admin_login(
    credentials: PlatformAdminLogin,
    db: AsyncSession = Depends(get_db)
):
    """
    Login for platform administrators only.
    This is completely separate from tenant user login.
    """
    # Get platform admin by email
    result = await db.execute(
        select(PlatformAdmin).where(PlatformAdmin.email == credentials.email)
    )
    admin = result.scalar_one_or_none()

    if not admin:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify password
    if not verify_password(credentials.password, admin.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check if active
    if not admin.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled"
        )

    # Update last login
    admin.last_login = datetime.utcnow()
    await db.commit()
    await db.refresh(admin)

    # Create access token with platform_admin type
    access_token = create_access_token(
        data={"sub": admin.id, "type": "platform_admin"}
    )

    return PlatformAuthResponse(
        access_token=access_token,
        token_type="bearer",
        admin=PlatformAdminResponse(
            id=admin.id,
            email=admin.email,
            full_name=admin.full_name,
            is_active=admin.is_active,
            created_at=admin.created_at,
            last_login=admin.last_login
        )
    )


@router.get("/me", response_model=PlatformAdminResponse)
async def get_current_admin(
    admin: PlatformAdmin = Depends(get_current_platform_admin)
):
    """Get current platform admin info"""
    return PlatformAdminResponse(
        id=admin.id,
        email=admin.email,
        full_name=admin.full_name,
        is_active=admin.is_active,
        created_at=admin.created_at,
        last_login=admin.last_login
    )
