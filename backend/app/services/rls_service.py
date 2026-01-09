"""
RLS (Row-Level Security) Service - Data filtering based on user groups
"""
from typing import List, Set, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models import User, UserGroup, UserGroupMembership, Connector, ConnectorRLS


async def get_user_rls_values(user_id: str, db: AsyncSession) -> Set[str]:
    """
    Get all RLS values that a user has access to based on their group memberships.

    Args:
        user_id: The user's ID
        db: Database session

    Returns:
        Set of all RLS values the user can access
    """
    # Get all groups the user belongs to with their RLS values
    result = await db.execute(
        select(UserGroup)
        .join(UserGroupMembership, UserGroup.id == UserGroupMembership.group_id)
        .where(
            UserGroupMembership.user_id == user_id,
            UserGroup.is_active == True
        )
    )
    groups = result.scalars().all()

    # Collect all RLS values from all groups
    rls_values = set()
    for group in groups:
        if group.rls_values:
            for value in group.rls_values:
                rls_values.add(value)

    return rls_values


async def get_connector_rls_config(connector_id: str, db: AsyncSession) -> Optional[ConnectorRLS]:
    """
    Get the RLS configuration for a connector.

    Args:
        connector_id: The connector's ID
        db: Database session

    Returns:
        ConnectorRLS config or None if not configured
    """
    return await db.scalar(
        select(ConnectorRLS).where(
            ConnectorRLS.connector_id == connector_id,
            ConnectorRLS.is_enabled == True
        )
    )


async def should_filter_data(connector_id: str, user: User, db: AsyncSession) -> bool:
    """
    Determine if data should be filtered for a given connector and user.

    Admins and super admins bypass RLS filtering.

    Args:
        connector_id: The connector's ID
        user: The current user
        db: Database session

    Returns:
        True if data should be filtered, False otherwise
    """
    # Super admins and tenant admins bypass RLS
    if user.is_super_admin or user.role.value == 'admin':
        return False

    # Check if connector has RLS enabled
    rls_config = await get_connector_rls_config(connector_id, db)
    if not rls_config:
        return False

    return True


def build_rls_filter_clause(
    rls_column: str,
    rls_values: Set[str],
    connector_type: str
) -> str:
    """
    Build SQL WHERE clause for RLS filtering.

    Args:
        rls_column: The column to filter on
        rls_values: Set of allowed values
        connector_type: Type of database connector

    Returns:
        SQL WHERE clause string
    """
    if not rls_values:
        # No RLS values = no access to any data
        return "1=0"

    # Escape values and build IN clause
    escaped_values = []
    for value in rls_values:
        # Basic SQL escaping - in production, use parameterized queries
        escaped = value.replace("'", "''")
        escaped_values.append(f"'{escaped}'")

    values_list = ", ".join(escaped_values)

    # Quote column name appropriately based on database type
    if connector_type in ['postgres', 'bigquery']:
        quoted_column = f'"{rls_column}"'
    elif connector_type in ['mysql']:
        quoted_column = f'`{rls_column}`'
    elif connector_type in ['sqlserver']:
        quoted_column = f'[{rls_column}]'
    else:
        quoted_column = rls_column

    return f"{quoted_column} IN ({values_list})"


def apply_rls_to_query(
    query: str,
    rls_column: str,
    rls_values: Set[str],
    connector_type: str
) -> str:
    """
    Apply RLS filtering to an existing SQL query.

    Args:
        query: Original SQL query
        rls_column: The column to filter on
        rls_values: Set of allowed values
        connector_type: Type of database connector

    Returns:
        Modified SQL query with RLS filter applied
    """
    rls_clause = build_rls_filter_clause(rls_column, rls_values, connector_type)

    # Wrap the original query and apply filter
    wrapped_query = f"""
    SELECT * FROM (
        {query}
    ) AS rls_filtered
    WHERE {rls_clause}
    """

    return wrapped_query


async def filter_dataframe_by_rls(
    df: Any,  # pandas DataFrame
    rls_column: str,
    rls_values: Set[str]
) -> Any:
    """
    Filter a pandas DataFrame based on RLS values.

    Args:
        df: Pandas DataFrame to filter
        rls_column: The column to filter on
        rls_values: Set of allowed values

    Returns:
        Filtered DataFrame
    """
    if rls_column not in df.columns:
        raise ValueError(f"RLS column '{rls_column}' not found in data")

    if not rls_values:
        # No RLS values = return empty DataFrame
        return df.iloc[0:0]

    # Filter DataFrame
    mask = df[rls_column].isin(rls_values)
    return df[mask]


class RLSContext:
    """
    Context class for RLS filtering that can be used throughout a request.
    """

    def __init__(
        self,
        user: User,
        connector_id: str,
        db: AsyncSession
    ):
        self.user = user
        self.connector_id = connector_id
        self.db = db
        self._rls_values: Optional[Set[str]] = None
        self._rls_config: Optional[ConnectorRLS] = None
        self._should_filter: Optional[bool] = None

    async def get_rls_values(self) -> Set[str]:
        """Get user's RLS values (cached)"""
        if self._rls_values is None:
            self._rls_values = await get_user_rls_values(self.user.id, self.db)
        return self._rls_values

    async def get_rls_config(self) -> Optional[ConnectorRLS]:
        """Get connector's RLS config (cached)"""
        if self._rls_config is None:
            self._rls_config = await get_connector_rls_config(self.connector_id, self.db)
        return self._rls_config

    async def should_filter(self) -> bool:
        """Check if filtering should be applied (cached)"""
        if self._should_filter is None:
            self._should_filter = await should_filter_data(
                self.connector_id, self.user, self.db
            )
        return self._should_filter

    async def apply_to_query(self, query: str, connector_type: str) -> str:
        """Apply RLS to a SQL query if needed"""
        if not await self.should_filter():
            return query

        config = await self.get_rls_config()
        if not config:
            return query

        values = await self.get_rls_values()
        return apply_rls_to_query(query, config.rls_column, values, connector_type)

    async def apply_to_dataframe(self, df: Any) -> Any:
        """Apply RLS to a DataFrame if needed"""
        if not await self.should_filter():
            return df

        config = await self.get_rls_config()
        if not config:
            return df

        values = await self.get_rls_values()
        return await filter_dataframe_by_rls(df, config.rls_column, values)
