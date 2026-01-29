"""Add swap_request model

Revision ID: 20260129_143513
Revises: 4b2c1d7a9f3e
Create Date: 2026-01-29 14:35:13.000000

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "20260129_143513"
down_revision: Union[str, None] = "4b2c1d7a9f3e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create enum type for swap request status
    op.execute(
        "CREATE TYPE swaprequeststatus AS ENUM ('pending', 'accepted', 'declined', 'expired')"
    )

    # Create swap_requests table
    op.create_table(
        "swap_requests",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("requester_assignment_id", sa.Uuid(), nullable=False),
        sa.Column("target_user_id", sa.Uuid(), nullable=False),
        sa.Column(
            "status",
            sa.Enum("pending", "accepted", "declined", "expired", name="swaprequeststatus"),
            nullable=False,
        ),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["requester_assignment_id"],
            ["event_assignments.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["target_user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("swap_requests")
    op.execute("DROP TYPE swaprequeststatus")
