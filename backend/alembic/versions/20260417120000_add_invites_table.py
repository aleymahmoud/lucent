"""add_invites_table

Revision ID: 20260417120000
Revises: 20260331120000
Create Date: 2026-04-17 12:00:00.000000

Spec 003 P2 — user invite flow. Creates the invites table used by
invite_service.py. Uses VARCHAR(36) for UUID columns to match the rest
of the schema (existing tables follow that convention).
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260417120000"
down_revision: Union[str, None] = "20260331120000"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "invites",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column(
            "tenant_id",
            sa.String(length=36),
            sa.ForeignKey("tenants.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("role", sa.String(length=32), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_by",
            sa.String(length=36),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "group_id",
            sa.String(length=36),
            sa.ForeignKey("user_groups.id", ondelete="SET NULL"),
            nullable=True,
        ),
    )
    op.create_unique_constraint("uq_invites_token_hash", "invites", ["token_hash"])
    op.create_index("ix_invites_tenant", "invites", ["tenant_id"])
    op.create_index("ix_invites_email", "invites", ["email"])
    op.create_index(
        "ix_invites_pending_expires",
        "invites",
        ["expires_at"],
        postgresql_where=sa.text("used_at IS NULL"),
    )


def downgrade() -> None:
    op.drop_index("ix_invites_pending_expires", table_name="invites")
    op.drop_index("ix_invites_email", table_name="invites")
    op.drop_index("ix_invites_tenant", table_name="invites")
    op.drop_constraint("uq_invites_token_hash", "invites", type_="unique")
    op.drop_table("invites")
