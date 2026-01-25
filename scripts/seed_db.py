#!/usr/bin/env python3
"""
Seed script to populate the Rooster database with sample data for development.

This creates:
- 3 users (admin, team lead, member)
- 1 organisation
- 2 teams
- 2 rosters
- Several assignments for the next few weeks
- Some unavailability records
"""

import asyncio
import sys
from datetime import date, timedelta
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent.parent / "backend"))

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_password_hash
from app.models.user import User
from app.models.organisation import Organisation, OrganisationMember, OrganisationRole
from app.models.team import Team, TeamMember, TeamRole
from app.models.roster import Roster, Assignment, RecurrencePattern, AssignmentMode, AssignmentStatus
from app.models.availability import Unavailability


async def seed_data():
    """Seed the database with sample data."""
    print("🌱 Seeding database with sample data...")
    
    async for db in get_db():
        # Create users
        print("\n👥 Creating users...")
        admin_user = User(
            email="admin@church.com",
            name="Admin User",
            password_hash=get_password_hash("password123"),
        )
        lead_user = User(
            email="lead@church.com",
            name="Team Lead",
            password_hash=get_password_hash("password123"),
        )
        member_user = User(
            email="member@church.com",
            name="Team Member",
            password_hash=get_password_hash("password123"),
        )
        
        db.add_all([admin_user, lead_user, member_user])
        await db.flush()
        print(f"  ✓ Created {admin_user.name} ({admin_user.email})")
        print(f"  ✓ Created {lead_user.name} ({lead_user.email})")
        print(f"  ✓ Created {member_user.name} ({member_user.email})")
        
        # Create organisation
        print("\n🏛️  Creating organisation...")
        org = Organisation(name="Grace Community Church")
        db.add(org)
        await db.flush()
        print(f"  ✓ Created organisation: {org.name}")
        
        # Add members to organisation
        print("\n👨‍👩‍👧‍👦 Adding members to organisation...")
        org_members = [
            OrganisationMember(
                user_id=admin_user.id,
                organisation_id=org.id,
                role=OrganisationRole.ADMIN,
            ),
            OrganisationMember(
                user_id=lead_user.id,
                organisation_id=org.id,
                role=OrganisationRole.MEMBER,
            ),
            OrganisationMember(
                user_id=member_user.id,
                organisation_id=org.id,
                role=OrganisationRole.MEMBER,
            ),
        ]
        db.add_all(org_members)
        await db.flush()
        print(f"  ✓ Added 3 members to {org.name}")
        
        # Create teams
        print("\n🎯 Creating teams...")
        media_team = Team(name="Media Team", organisation_id=org.id)
        worship_team = Team(name="Worship Team", organisation_id=org.id)
        db.add_all([media_team, worship_team])
        await db.flush()
        print(f"  ✓ Created {media_team.name}")
        print(f"  ✓ Created {worship_team.name}")
        
        # Add members to teams
        print("\n👥 Adding members to teams...")
        team_members = [
            # Media team
            TeamMember(user_id=lead_user.id, team_id=media_team.id, role=TeamRole.LEAD),
            TeamMember(user_id=member_user.id, team_id=media_team.id, role=TeamRole.MEMBER),
            # Worship team
            TeamMember(user_id=admin_user.id, team_id=worship_team.id, role=TeamRole.LEAD),
            TeamMember(user_id=member_user.id, team_id=worship_team.id, role=TeamRole.MEMBER),
        ]
        db.add_all(team_members)
        await db.flush()
        print(f"  ✓ Added members to teams")
        
        # Create rosters
        print("\n📅 Creating rosters...")
        sunday_media = Roster(
            name="Sunday Service - Media",
            team_id=media_team.id,
            recurrence_pattern=RecurrencePattern.WEEKLY,
            recurrence_day=6,  # Sunday
            slots_needed=2,
            assignment_mode=AssignmentMode.MANUAL,
        )
        sunday_worship = Roster(
            name="Sunday Service - Worship",
            team_id=worship_team.id,
            recurrence_pattern=RecurrencePattern.WEEKLY,
            recurrence_day=6,  # Sunday
            slots_needed=3,
            assignment_mode=AssignmentMode.MANUAL,
        )
        db.add_all([sunday_media, sunday_worship])
        await db.flush()
        print(f"  ✓ Created {sunday_media.name}")
        print(f"  ✓ Created {sunday_worship.name}")
        
        # Create assignments for the next 4 weeks
        print("\n📝 Creating assignments...")
        today = date.today()
        assignments = []
        
        for week in range(4):
            sunday = today + timedelta(days=(6 - today.weekday()) + (week * 7))
            
            # Media team assignments
            assignments.append(Assignment(
                roster_id=sunday_media.id,
                user_id=lead_user.id,
                date=sunday,
                status=AssignmentStatus.CONFIRMED if week < 2 else AssignmentStatus.PENDING,
            ))
            assignments.append(Assignment(
                roster_id=sunday_media.id,
                user_id=member_user.id,
                date=sunday,
                status=AssignmentStatus.CONFIRMED if week < 2 else AssignmentStatus.PENDING,
            ))
            
            # Worship team assignments
            assignments.append(Assignment(
                roster_id=sunday_worship.id,
                user_id=admin_user.id,
                date=sunday,
                status=AssignmentStatus.CONFIRMED if week < 2 else AssignmentStatus.PENDING,
            ))
            assignments.append(Assignment(
                roster_id=sunday_worship.id,
                user_id=member_user.id,
                date=sunday,
                status=AssignmentStatus.CONFIRMED if week < 2 else AssignmentStatus.PENDING,
            ))
        
        db.add_all(assignments)
        await db.flush()
        print(f"  ✓ Created {len(assignments)} assignments for the next 4 weeks")
        
        # Create some unavailability
        print("\n🚫 Creating unavailability records...")
        unavailabilities = [
            Unavailability(
                user_id=member_user.id,
                date=today + timedelta(days=21),  # 3 weeks from now
                reason="Family vacation",
            ),
        ]
        db.add_all(unavailabilities)
        await db.flush()
        print(f"  ✓ Created {len(unavailabilities)} unavailability records")
        
        await db.commit()
        
        print("\n✅ Database seeded successfully!")
        print("\n📋 Test Accounts:")
        print("  Admin:  admin@church.com / password123")
        print("  Lead:   lead@church.com / password123")
        print("  Member: member@church.com / password123")
        print("\n🎉 You can now login and see sample data!")


if __name__ == "__main__":
    asyncio.run(seed_data())
