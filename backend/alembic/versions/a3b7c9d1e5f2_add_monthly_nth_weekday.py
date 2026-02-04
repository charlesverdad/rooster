"""Add monthly nth weekday recurrence pattern

Revision ID: a3b7c9d1e5f2
Revises: c9f4a2b8d1e7
Create Date: 2026-02-05 10:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision: str = "a3b7c9d1e5f2"
down_revision: Union[str, None] = "c9f4a2b8d1e7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add new enum value to recurrencepattern
    # PostgreSQL enum stores uppercase names (WEEKLY, BIWEEKLY, etc.)
    op.execute(
        "ALTER TYPE recurrencepattern ADD VALUE IF NOT EXISTS 'MONTHLY_NTH_WEEKDAY'"
    )

    # Add new columns for nth weekday recurrence
    op.add_column(
        "rosters",
        sa.Column("recurrence_weekday", sa.Integer(), nullable=True),
    )
    op.add_column(
        "rosters",
        sa.Column("recurrence_week_number", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("rosters", "recurrence_week_number")
    op.drop_column("rosters", "recurrence_weekday")
    # Note: PostgreSQL does not support removing enum values directly.
    # The 'monthly_nth_weekday' value will remain in the enum type.
