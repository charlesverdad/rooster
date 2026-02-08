from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text

from app.api.auth import router as auth_router
from app.api.organisations import router as organisations_router
from app.api.teams import router as teams_router
from app.api.rosters import router as rosters_router
from app.api.availability import router as availability_router
from app.api.notifications import router as notifications_router
from app.api.dashboard import router as dashboard_router
from app.api.invites import router as invites_router
from app.api.push import router as push_router
from app.core.config import get_settings

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    description="Church volunteer rostering application",
    version="0.1.0",
)

# Parse CORS origins from config
cors_origins = (
    ["*"]
    if settings.cors_origins == "*"
    else [
        origin.strip() for origin in settings.cors_origins.split(",") if origin.strip()
    ]
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, prefix="/api")
app.include_router(organisations_router, prefix="/api")
app.include_router(teams_router, prefix="/api")
app.include_router(rosters_router, prefix="/api")
app.include_router(availability_router, prefix="/api")
app.include_router(notifications_router, prefix="/api")
app.include_router(dashboard_router, prefix="/api")
app.include_router(invites_router, prefix="/api")
app.include_router(push_router, prefix="/api")


@app.get("/health")
async def health_check():
    """Health check endpoint that verifies database connectivity."""
    from app.core.database import async_session_maker

    try:
        async with async_session_maker() as session:
            await session.execute(text("SELECT 1"))
        return {"status": "healthy"}
    except Exception:
        return JSONResponse(
            status_code=503,
            content={"status": "unhealthy", "detail": "database unreachable"},
        )
