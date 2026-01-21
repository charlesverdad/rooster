"""Add permissions to team_members

Revision ID: a1b2c3d4e5f6
Revises: d79c335d1532
Create Date: 2026-01-21 14:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = 'd79c335d1532'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# Permission constants (duplicated here to avoid import issues)
ALL_PERMISSIONS = [
    "manage_team",
    "manage_members",
    "send_invites",
    "manage_rosters",
    "assign_volunteers",
    "view_responses",
]


def upgrade() -> None:
    # Add permissions column with empty JSON array default
    op.add_column(
        'team_members',
        sa.Column(
            'permissions',
            sa.JSON(),
            nullable=False,
            server_default='[]'
        )
    )

    # Migrate existing data: team leads get all permissions, members get none
    # Use JSON format for PostgreSQL
    # Note: PostgreSQL enums are case-sensitive, use uppercase to match the enum definition
    op.execute(
        """
        UPDATE team_members
        SET permissions = '["manage_team", "manage_members", "send_invites",
                           "manage_rosters", "assign_volunteers", "view_responses"]'::json
        WHERE role = 'LEAD'
        """
    )


def downgrade() -> None:
    op.drop_column('team_members', 'permissions')
