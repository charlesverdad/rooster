"""Add sys admin support

Revision ID: f6a7b8c9d0e1
Revises: e5f6a7b8c9d0
Create Date: 2026-03-02 12:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision: str = "f6a7b8c9d0e1"
down_revision: Union[str, None] = "e5f6a7b8c9d0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add sys admin columns to users
    op.add_column(
        "users",
        sa.Column(
            "is_superadmin", sa.Boolean(), nullable=False, server_default="false"
        ),
    )
    op.add_column(
        "users",
        sa.Column(
            "is_deactivated", sa.Boolean(), nullable=False, server_default="false"
        ),
    )

    # Create auth_settings table
    op.create_table(
        "auth_settings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("email_enabled", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column(
            "google_enabled", sa.Boolean(), nullable=False, server_default="false"
        ),
        sa.Column("google_client_id", sa.String(500), nullable=True),
        sa.Column(
            "updated_by_id",
            sa.Uuid(),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("auth_settings")
    op.drop_column("users", "is_deactivated")
    op.drop_column("users", "is_superadmin")
