"""
API v1 Router - Aggregates all endpoint routers
"""
from fastapi import APIRouter

from app.api.v1.endpoints import auth

api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])

# Add more routers here as we build them
# api_router.include_router(datasets.router, prefix="/datasets", tags=["Datasets"])
# api_router.include_router(forecast.router, prefix="/forecast", tags=["Forecast"])
# etc...
