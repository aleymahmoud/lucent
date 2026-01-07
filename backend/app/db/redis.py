# ============================================
# Redis Connection & Cache Management
# ============================================

from redis import asyncio as aioredis
from typing import Optional, Any
import json
import logging

from app.config import settings

logger = logging.getLogger(__name__)

# Global Redis client
redis_client: Optional[aioredis.Redis] = None


async def init_redis():
    """Initialize Redis connection"""
    global redis_client
    try:
        redis_client = await aioredis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
            socket_connect_timeout=5,
            socket_keepalive=True,
        )
        # Test connection
        await redis_client.ping()
        logger.info("✅ Redis connection successful")
        return redis_client
    except Exception as e:
        logger.error(f"❌ Redis connection failed: {e}")
        raise


async def close_redis():
    """Close Redis connection"""
    global redis_client
    if redis_client:
        await redis_client.close()
        logger.info("Redis connection closed")


async def get_redis() -> aioredis.Redis:
    """Get Redis client"""
    global redis_client
    if redis_client is None:
        redis_client = await init_redis()
    return redis_client


class CacheManager:
    """Redis cache manager with helper methods"""

    def __init__(self, redis: aioredis.Redis):
        self.redis = redis

    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        value = await self.redis.get(key)
        if value:
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return value
        return None

    async def set(self, key: str, value: Any, ttl: int = 3600) -> bool:
        """Set value in cache with TTL (default 1 hour)"""
        try:
            if isinstance(value, (dict, list)):
                value = json.dumps(value)
            return await self.redis.setex(key, ttl, value)
        except Exception as e:
            logger.error(f"Cache set error: {e}")
            return False

    async def delete(self, key: str) -> bool:
        """Delete key from cache"""
        return await self.redis.delete(key) > 0

    async def exists(self, key: str) -> bool:
        """Check if key exists"""
        return await self.redis.exists(key) > 0

    async def increment(self, key: str, amount: int = 1) -> int:
        """Increment counter"""
        return await self.redis.incrby(key, amount)

    async def expire(self, key: str, ttl: int) -> bool:
        """Set expiration on key"""
        return await self.redis.expire(key, ttl)

    async def get_or_set(
        self,
        key: str,
        factory,
        ttl: int = 3600
    ) -> Any:
        """Get from cache or compute and cache"""
        cached = await self.get(key)
        if cached is not None:
            return cached

        result = await factory() if callable(factory) else factory
        await self.set(key, result, ttl)
        return result
