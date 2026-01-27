import uuid

from fastapi import APIRouter, HTTPException, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.organisation import (
    AddMemberRequest,
    OrganisationCreate,
    OrganisationMemberResponse,
    OrganisationResponse,
    OrganisationUpdate,
    OrganisationWithRole,
)
from app.services.organisation import OrganisationService

router = APIRouter(prefix="/organisations", tags=["organisations"])


@router.post(
    "", response_model=OrganisationResponse, status_code=status.HTTP_201_CREATED
)
async def create_organisation(
    data: OrganisationCreate,
    current_user: CurrentUser,
    db: DbSession,
) -> OrganisationResponse:
    """Create a new organisation. The creator becomes admin."""
    service = OrganisationService(db)
    org = await service.create_organisation(data, current_user.id)
    return OrganisationResponse.model_validate(org)


@router.get("", response_model=list[OrganisationWithRole])
async def list_my_organisations(
    current_user: CurrentUser,
    db: DbSession,
) -> list[OrganisationWithRole]:
    """List all organisations the current user belongs to."""
    service = OrganisationService(db)
    orgs = await service.get_user_organisations(current_user.id)
    return [
        OrganisationWithRole(
            id=org.id,
            name=org.name,
            role=role,
            created_at=org.created_at,
        )
        for org, role in orgs
    ]


@router.get("/{org_id}", response_model=OrganisationResponse)
async def get_organisation(
    org_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> OrganisationResponse:
    """Get an organisation by ID. Must be a member."""
    service = OrganisationService(db)

    # Check membership
    membership = await service.get_membership(current_user.id, org_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    org = await service.get_organisation(org_id)
    if not org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organisation not found",
        )
    return OrganisationResponse.model_validate(org)


@router.patch("/{org_id}", response_model=OrganisationResponse)
async def update_organisation(
    org_id: uuid.UUID,
    data: OrganisationUpdate,
    current_user: CurrentUser,
    db: DbSession,
) -> OrganisationResponse:
    """Update an organisation. Admin only."""
    service = OrganisationService(db)

    if not await service.is_admin(current_user.id, org_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

    org = await service.update_organisation(org_id, data)
    if not org:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organisation not found",
        )
    return OrganisationResponse.model_validate(org)


@router.delete("/{org_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_organisation(
    org_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> None:
    """Delete an organisation. Admin only."""
    service = OrganisationService(db)

    if not await service.is_admin(current_user.id, org_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

    if not await service.delete_organisation(org_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Organisation not found",
        )


@router.get("/{org_id}/members", response_model=list[OrganisationMemberResponse])
async def list_members(
    org_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> list[OrganisationMemberResponse]:
    """List all members of an organisation. Must be a member."""
    service = OrganisationService(db)

    membership = await service.get_membership(current_user.id, org_id)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a member of this organisation",
        )

    members = await service.get_members(org_id)
    return [
        OrganisationMemberResponse(
            user_id=m.user_id,
            organisation_id=m.organisation_id,
            role=m.role,
            user_email=m.user.email,
            user_name=m.user.name,
        )
        for m in members
    ]


@router.post(
    "/{org_id}/members",
    response_model=OrganisationMemberResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_member(
    org_id: uuid.UUID,
    data: AddMemberRequest,
    current_user: CurrentUser,
    db: DbSession,
) -> OrganisationMemberResponse:
    """Add a member to an organisation. Admin only."""
    service = OrganisationService(db)

    if not await service.is_admin(current_user.id, org_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

    membership = await service.add_member(org_id, data.user_id, data.role)
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Reload with user info
    members = await service.get_members(org_id)
    for m in members:
        if m.user_id == data.user_id:
            return OrganisationMemberResponse(
                user_id=m.user_id,
                organisation_id=m.organisation_id,
                role=m.role,
                user_email=m.user.email,
                user_name=m.user.name,
            )

    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)


@router.delete("/{org_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_member(
    org_id: uuid.UUID,
    user_id: uuid.UUID,
    current_user: CurrentUser,
    db: DbSession,
) -> None:
    """Remove a member from an organisation. Admin only."""
    service = OrganisationService(db)

    if not await service.is_admin(current_user.id, org_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )

    if not await service.remove_member(org_id, user_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Member not found",
        )
