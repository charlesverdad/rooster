import uuid
from datetime import date

from fastapi import APIRouter, HTTPException, Query, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.availability import (
    ConflictResponse,
    UnavailabilityCreate,
    UnavailabilityResponse,
)
from app.services.availability import AvailabilityService

router = APIRouter(prefix="/availability", tags=["availability"])


@router.post("", response_model=UnavailabilityResponse, status_code=status.HTTP_201_CREATED)
async def mark_unavailable(
    data: UnavailabilityCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> UnavailabilityResponse:
    """Mark a date as unavailable for the current user."""
    service = AvailabilityService(db)
    unavailability = await service.mark_unavailable(current_user.id, data)
    return UnavailabilityResponse.model_validate(unavailability)


@router.get("/me", response_model=list[UnavailabilityResponse])
async def list_my_unavailabilities(
    current_user: CurrentUser,
    db: DbSession,
    start_date: date | None = Query(None),
    end_date: date | None = Query(None),
) -> list[UnavailabilityResponse]:
    """List all unavailabilities for the current user."""
    service = AvailabilityService(db)
    unavailabilities = await service.get_user_unavailabilities(
        current_user.id, start_date, end_date
    )
    return [UnavailabilityResponse.model_validate(u) for u in unavailabilities]


@router.delete("/{unavailability_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_unavailability(
    unavailability_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> None:
    """Delete an unavailability record. User can only delete their own."""
    service = AvailabilityService(db)
    
    # First check if the unavailability exists and belongs to the user
    unavailabilities = await service.get_user_unavailabilities(current_user.id)
    if not any(u.id == unavailability_id for u in unavailabilities):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Unavailability not found or not authorized",
        )
    
    await service.delete_unavailability(unavailability_id)


@router.get("/conflicts", response_model=list[ConflictResponse])
async def check_conflicts(
    current_user: CurrentUser,
    db: DbSession,
) -> list[ConflictResponse]:
    """Check for conflicts between assignments and unavailabilities."""
    service = AvailabilityService(db)
    conflicts = await service.check_user_conflicts(current_user.id)
    
    return [
        ConflictResponse(
            assignment_id=assignment.id,
            unavailability_id=unavailability.id,
            date=assignment.date,
            roster_name=assignment.roster.name if assignment.roster else "Unknown",
            team_name=assignment.roster.team.name if assignment.roster and assignment.roster.team else "Unknown",
            reason=unavailability.reason,
        )
        for assignment, unavailability in conflicts
    ]
