"""Add reference_id to notifications and team_joined type

Revision ID: 4b2c1d7a9f3e
Revises: a1b2c3d4e5f6
Create Date: 2026-01-26 03:45:00.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "4b2c1d7a9f3e"
down_revision: Union[str, None] = "a1b2c3d4e5f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TYPE notificationtype ADD VALUE IF NOT EXISTS 'TEAM_JOINED'")
    op.add_column("notifications", sa.Column("reference_id", sa.Uuid(), nullable=True))


def downgrade() -> None:
    op.drop_column("notifications", "reference_id")
