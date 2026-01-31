"""add_push_subscriptions

Revision ID: 135a6e0101bd
Revises: b5d3e7f9a2c4
Create Date: 2026-01-31 23:40:36.544649

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "135a6e0101bd"
down_revision: Union[str, None] = "b5d3e7f9a2c4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "push_subscriptions",
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("endpoint", sa.Text(), nullable=False),
        sa.Column("p256dh_key", sa.String(length=255), nullable=False),
        sa.Column("auth_key", sa.String(length=255), nullable=False),
        sa.Column("user_agent", sa.String(length=512), nullable=True),
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("endpoint"),
    )
    op.create_index("ix_push_subscriptions_user_id", "push_subscriptions", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_push_subscriptions_user_id", table_name="push_subscriptions")
    op.drop_table("push_subscriptions")
