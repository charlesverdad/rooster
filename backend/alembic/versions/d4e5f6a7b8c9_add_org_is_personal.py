"""Add is_personal flag to organisations

Revision ID: d4e5f6a7b8c9
Revises: a3b7c9d1e5f2
Create Date: 2026-02-11 10:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op


# revision identifiers, used by Alembic.
revision: str = "d4e5f6a7b8c9"
down_revision: Union[str, None] = "a3b7c9d1e5f2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "organisations",
        sa.Column(
            "is_personal",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
    # Mark existing auto-created personal orgs
    op.execute(
        "UPDATE organisations SET is_personal = true "
        "WHERE name LIKE '%''s Organisation'"
    )


def downgrade() -> None:
    op.drop_column("organisations", "is_personal")
