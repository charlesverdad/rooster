"""Add unique constraint on event_assignments for event_id and user_id

Revision ID: b5d3e7f9a2c4
Revises: 4b2c1d7a9f3e
Create Date: 2026-01-31 10:00:00.000000

"""

from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = "b5d3e7f9a2c4"
down_revision: Union[str, None] = "4b2c1d7a9f3e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add unique constraint to prevent duplicate assignments of the same user to the same event
    # This ensures data integrity at the database level, complementing the application-level check
    op.create_unique_constraint(
        "uq_event_user_assignment",
        "event_assignments",
        ["event_id", "user_id"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_event_user_assignment", "event_assignments", type_="unique")
