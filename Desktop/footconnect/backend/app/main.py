from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from .routers import auth, users, matches, participants, notifications, teams, messages




app = FastAPI(
    title="Amateur Football API",
    description="Backend API for Amateur Football Match Organizer",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware - Restrict to specific origins for security
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8080",    # Flutter web dev server
        "http://127.0.0.1:8080",   # Alternative localhost
        "http://localhost:8081",    # Alternative port
        "http://127.0.0.1:8081",   # Alternative port
        "http://localhost:3000",    # React dev server
        "http://127.0.0.1:3000",   # React dev server
        # Flutter web dev server ports (56500-56600 range)
        "http://localhost:56551",
        "http://127.0.0.1:56551",
        "http://localhost:56500",
        "http://localhost:56501",
        "http://localhost:56502",
        "http://localhost:56503",
        "http://localhost:56504",
        "http://localhost:56505",
        "http://localhost:56506",
        "http://localhost:56507",
        "http://localhost:56508",
        "http://localhost:56509",
        "http://localhost:56600",
        # Add your production domains here when deploying
        # "https://yourdomain.com",
        # "https://www.yourdomain.com"
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
)

# Include routers
app.include_router(
    auth.router,
    prefix="/api/v1/auth",
    tags=["Authentication"]
)

app.include_router(
    users.router,
    prefix="/api/v1/users",
    tags=["Users"]
)

app.include_router(
    matches.router,
    prefix="/api/v1/matches",
    tags=["Matches"]
)

app.include_router(
    participants.router,
    prefix="/api/v1/participants",
    tags=["Participants"]
)

app.include_router(
    notifications.router,
    prefix="/api/v1/notifications",
    tags=["Notifications"]
)

app.include_router(
    teams.router,
    prefix="/api/v1/teams",
    tags=["Teams"]
)

app.include_router(
    messages.router,
    prefix="/api/v1/messages",
    tags=["Messages"]
)

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler for unhandled exceptions"""
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "type": "internal_error"
        }
    )

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Custom HTTP exception handler"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": exc.detail,
            "type": "http_error"
        }
    )

@app.get("/")
async def root():
    return {"message": "Amateur Football API", "version": "1.0.0", "docs": "/docs"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}