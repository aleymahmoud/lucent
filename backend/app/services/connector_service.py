"""
Connector Service - Database connection and column discovery
"""
import json
from typing import List, Any, Dict
from cryptography.fernet import Fernet

from app.models.connector import Connector, ConnectorType
from app.config import settings


def decrypt_config(encrypted_config: str) -> Dict[str, Any]:
    """Decrypt connector configuration"""
    try:
        # If encryption is configured
        if hasattr(settings, 'ENCRYPTION_KEY') and settings.ENCRYPTION_KEY:
            f = Fernet(settings.ENCRYPTION_KEY.encode())
            decrypted = f.decrypt(encrypted_config.encode())
            return json.loads(decrypted.decode())
        else:
            # If no encryption, assume plain JSON
            return json.loads(encrypted_config)
    except Exception:
        # Fallback: try as plain JSON
        return json.loads(encrypted_config)


async def get_connector_columns_from_db(connector: Connector) -> List[str]:
    """
    Get column names from a connector's data source.
    Supports PostgreSQL, MySQL, SQL Server connectors.
    """
    config = decrypt_config(connector.config)
    connector_type = connector.type

    if connector_type == ConnectorType.POSTGRES:
        return await _get_postgres_columns(config)
    elif connector_type == ConnectorType.MYSQL:
        return await _get_mysql_columns(config)
    elif connector_type == ConnectorType.SQLSERVER:
        return await _get_sqlserver_columns(config)
    elif connector_type == ConnectorType.BIGQUERY:
        return await _get_bigquery_columns(config)
    elif connector_type == ConnectorType.SNOWFLAKE:
        return await _get_snowflake_columns(config)
    else:
        # For file-based connectors (S3, GCS, Azure Blob),
        # columns need to be discovered differently or entered manually
        raise ValueError(f"Column discovery not supported for connector type: {connector_type.value}")


async def _get_postgres_columns(config: Dict[str, Any]) -> List[str]:
    """Get columns from PostgreSQL database"""
    import asyncpg

    host = config.get('host', 'localhost')
    port = config.get('port', 5432)
    database = config.get('database')
    user = config.get('user')
    password = config.get('password')
    schema = config.get('schema', 'public')
    table = config.get('table')
    query = config.get('query')

    conn = await asyncpg.connect(
        host=host,
        port=port,
        database=database,
        user=user,
        password=password
    )

    try:
        if table:
            # Get columns from specific table
            columns = await conn.fetch("""
                SELECT column_name
                FROM information_schema.columns
                WHERE table_schema = $1 AND table_name = $2
                ORDER BY ordinal_position
            """, schema, table)
            return [row['column_name'] for row in columns]
        elif query:
            # Get columns from query by executing with LIMIT 0
            limited_query = f"SELECT * FROM ({query}) AS q LIMIT 0"
            stmt = await conn.prepare(limited_query)
            return [attr.name for attr in stmt.get_attributes()]
        else:
            raise ValueError("Either 'table' or 'query' must be specified in connector config")
    finally:
        await conn.close()


async def _get_mysql_columns(config: Dict[str, Any]) -> List[str]:
    """Get columns from MySQL database"""
    import aiomysql

    host = config.get('host', 'localhost')
    port = config.get('port', 3306)
    database = config.get('database')
    user = config.get('user')
    password = config.get('password')
    table = config.get('table')
    query = config.get('query')

    conn = await aiomysql.connect(
        host=host,
        port=port,
        db=database,
        user=user,
        password=password
    )

    try:
        async with conn.cursor() as cur:
            if table:
                await cur.execute(f"""
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_schema = %s AND table_name = %s
                    ORDER BY ordinal_position
                """, (database, table))
                rows = await cur.fetchall()
                return [row[0] for row in rows]
            elif query:
                # Get columns from query by executing with LIMIT 0
                limited_query = f"SELECT * FROM ({query}) AS q LIMIT 0"
                await cur.execute(limited_query)
                return [desc[0] for desc in cur.description]
            else:
                raise ValueError("Either 'table' or 'query' must be specified in connector config")
    finally:
        conn.close()


async def _get_sqlserver_columns(config: Dict[str, Any]) -> List[str]:
    """Get columns from SQL Server database"""
    import aioodbc

    host = config.get('host', 'localhost')
    port = config.get('port', 1433)
    database = config.get('database')
    user = config.get('user')
    password = config.get('password')
    schema = config.get('schema', 'dbo')
    table = config.get('table')
    query = config.get('query')

    dsn = f"DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={host},{port};DATABASE={database};UID={user};PWD={password}"

    async with aioodbc.connect(dsn=dsn) as conn:
        async with conn.cursor() as cur:
            if table:
                await cur.execute("""
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_schema = ? AND table_name = ?
                    ORDER BY ordinal_position
                """, schema, table)
                rows = await cur.fetchall()
                return [row[0] for row in rows]
            elif query:
                # Get columns from query by executing with TOP 0
                limited_query = f"SELECT TOP 0 * FROM ({query}) AS q"
                await cur.execute(limited_query)
                return [desc[0] for desc in cur.description]
            else:
                raise ValueError("Either 'table' or 'query' must be specified in connector config")


async def _get_bigquery_columns(config: Dict[str, Any]) -> List[str]:
    """Get columns from BigQuery"""
    from google.cloud import bigquery
    from google.oauth2 import service_account
    import json

    credentials_json = config.get('credentials')
    project_id = config.get('project_id')
    dataset = config.get('dataset')
    table = config.get('table')
    query = config.get('query')

    if credentials_json:
        credentials = service_account.Credentials.from_service_account_info(
            json.loads(credentials_json) if isinstance(credentials_json, str) else credentials_json
        )
        client = bigquery.Client(credentials=credentials, project=project_id)
    else:
        client = bigquery.Client(project=project_id)

    if table:
        table_ref = f"{project_id}.{dataset}.{table}"
        table_obj = client.get_table(table_ref)
        return [field.name for field in table_obj.schema]
    elif query:
        # Dry run to get schema
        job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
        query_job = client.query(query, job_config=job_config)
        return [field.name for field in query_job.schema]
    else:
        raise ValueError("Either 'table' or 'query' must be specified in connector config")


async def _get_snowflake_columns(config: Dict[str, Any]) -> List[str]:
    """Get columns from Snowflake"""
    import snowflake.connector

    account = config.get('account')
    user = config.get('user')
    password = config.get('password')
    warehouse = config.get('warehouse')
    database = config.get('database')
    schema = config.get('schema', 'PUBLIC')
    table = config.get('table')
    query = config.get('query')

    conn = snowflake.connector.connect(
        account=account,
        user=user,
        password=password,
        warehouse=warehouse,
        database=database,
        schema=schema
    )

    try:
        cur = conn.cursor()
        if table:
            cur.execute(f"DESCRIBE TABLE {schema}.{table}")
            rows = cur.fetchall()
            return [row[0] for row in rows]  # Column name is first field
        elif query:
            # Get columns from query by executing with LIMIT 0
            limited_query = f"SELECT * FROM ({query}) LIMIT 0"
            cur.execute(limited_query)
            return [desc[0] for desc in cur.description]
        else:
            raise ValueError("Either 'table' or 'query' must be specified in connector config")
    finally:
        conn.close()
