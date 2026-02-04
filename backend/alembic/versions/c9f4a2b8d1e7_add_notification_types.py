"""Add new notification types for assignments and teams

Revision ID: c9f4a2b8d1e7
Revises: 135a6e0101bd
Create Date: 2026-02-04 12:00:00.000000

"""

from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "c9f4a2b8d1e7"
down_revision: Union[str, None] = "135a6e0101bd"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "ALTER TYPE notificationtype ADD VALUE IF NOT EXISTS 'ASSIGNMENT_CONFIRMED'"
    )
    op.execute(
        "ALTER TYPE notificationtype ADD VALUE IF NOT EXISTS 'ASSIGNMENT_DECLINED'"
    )
    op.execute("ALTER TYPE notificationtype ADD VALUE IF NOT EXISTS 'TEAM_INVITE'")
    op.execute("ALTER TYPE notificationtype ADD VALUE IF NOT EXISTS 'TEAM_REMOVED'")


def downgrade() -> None:
    # PostgreSQL does not support removing values from enum types
    pass
