"""Permission constants and utilities for team-based authorization."""


class TeamPermission:
    """Constants for team member permissions."""

    MANAGE_TEAM = "manage_team"
    MANAGE_MEMBERS = "manage_members"
    SEND_INVITES = "send_invites"
    MANAGE_ROSTERS = "manage_rosters"
    ASSIGN_VOLUNTEERS = "assign_volunteers"
    VIEW_RESPONSES = "view_responses"

    ALL = [
        MANAGE_TEAM,
        MANAGE_MEMBERS,
        SEND_INVITES,
        MANAGE_ROSTERS,
        ASSIGN_VOLUNTEERS,
        VIEW_RESPONSES,
    ]

    # Default permissions for different scenarios
    TEAM_CREATOR_DEFAULT = ALL.copy()
    INVITED_MEMBER_DEFAULT: list[str] = []
