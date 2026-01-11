"""Add datasets table for Phase 3 Data Module

Revision ID: a1b2c3d4e5f6
Revises: fe0abdbaa869
Create Date: 2026-01-11 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = 'fe0abdbaa869'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create datasets table
    op.create_table('datasets',
        sa.Column('id', sa.String(length=36), nullable=False),
        sa.Column('tenant_id', sa.String(length=36), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('filename', sa.String(length=255), nullable=False),
        sa.Column('file_path', sa.String(length=500), nullable=True),
        sa.Column('file_size', sa.BigInteger(), nullable=False),
        sa.Column('file_type', sa.String(length=50), nullable=False),
        sa.Column('row_count', sa.Integer(), nullable=True),
        sa.Column('column_count', sa.Integer(), nullable=True),
        sa.Column('entity_column', sa.String(length=100), nullable=True),
        sa.Column('date_column', sa.String(length=100), nullable=True),
        sa.Column('value_column', sa.String(length=100), nullable=True),
        sa.Column('columns', sa.JSON(), nullable=True, default=[]),
        sa.Column('column_types', sa.JSON(), nullable=True, default={}),
        sa.Column('date_range', sa.JSON(), nullable=True, default={}),
        sa.Column('entities', sa.JSON(), nullable=True, default=[]),
        sa.Column('summary', sa.JSON(), nullable=True, default={}),
        sa.Column('redis_key', sa.String(length=100), nullable=True),
        sa.Column('uploaded_by', sa.String(length=36), nullable=True),
        sa.Column('uploaded_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.Column('is_processed', sa.Boolean(), nullable=False, default=False),
        sa.Column('processing_error', sa.Text(), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, default=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['tenant_id'], ['tenants.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['uploaded_by'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_datasets_tenant_id'), 'datasets', ['tenant_id'], unique=False)
    op.create_index(op.f('ix_datasets_is_active'), 'datasets', ['is_active'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_datasets_is_active'), table_name='datasets')
    op.drop_index(op.f('ix_datasets_tenant_id'), table_name='datasets')
    op.drop_table('datasets')
