from fastapi import APIRouter, HTTPException, Depends, status, Header
from ..schemas import UserSignup, UserLogin, Token, User
from ..supabase_client import supabase, supabase_admin

router = APIRouter()

@router.post("/signup")
async def signup(user: UserSignup):
    try:
        # Create user profile in database first
        # For development, we'll skip Supabase Auth and just create the user directly
        import uuid

        user_id = str(uuid.uuid4())

        # Create user profile in database
        user_data = {
            "id": user_id,
            "email": user.email,
            "full_name": user.name,
            "role": user.role,
        }
        if user.gender:
            user_data["gender"] = user.gender

        supabase_admin.table("users").insert(user_data).execute()

        # For development: Skip actual Supabase auth signup to avoid email confirmation
        # In production, you'd want to use proper Supabase auth with email confirmation

        return {
            "message": "User created successfully (development mode - no email confirmation required)",
            "user_id": user_id,
            "email_confirmed": True,
            "dev_mode": True
        }

    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login")
async def login(user: UserLogin):
    try:
        # For development: Simple email/password check against our database
        # In production, you'd use proper Supabase auth with JWT tokens

        # Find user by email
        user_response = supabase_admin.table("users").select("*").eq("email", user.email).execute()

        if not user_response.data:
            # For development: If user doesn't exist, create them automatically
            import uuid
            user_id = str(uuid.uuid4())

            # Create user profile in database
            user_data = {
                "id": user_id,
                "email": user.email,
                "full_name": user.email.split('@')[0],  # Use email prefix as name
                "role": "player",
            }

            supabase_admin.table("users").insert(user_data).execute()
        else:
            user_data = user_response.data[0]

        # For development: Accept any password (simplified auth)
        # In production, you'd verify the password hash properly
        if user.password:  # Basic check - any non-empty password works for dev
            # Generate a simple token (in production, use proper JWT)
            import jwt
            import datetime
            import os

            secret_key = os.getenv('JWT_SECRET', 'dev-secret-key-change-in-production')

            token_payload = {
                "user_id": user_data["id"],
                "email": user_data["email"],
                "exp": datetime.datetime.utcnow() + datetime.timedelta(days=30)
            }

            token = jwt.encode(token_payload, secret_key, algorithm="HS256")

            return {
                "access_token": token,
                "token_type": "bearer",
                "user": {
                    "id": user_data["id"],
                    "name": user_data.get("full_name"),
                    "email": user_data["email"],
                    "role": user_data.get("role", "player"),
                    "gender": user_data.get("gender"),
                    "image_url": user_data.get("avatar_url"),
                    "created_at": user_data["created_at"]
                }
            }
        else:
            raise HTTPException(status_code=401, detail="Invalid credentials")

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=401, detail="Login failed")

async def get_current_user(authorization: str = Header(None)) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = authorization.split(" ")[1]

    try:
        # Verify our custom JWT token
        import jwt
        import os

        secret_key = os.getenv('JWT_SECRET', 'dev-secret-key-change-in-production')

        # Decode and verify token
        payload = jwt.decode(token, secret_key, algorithms=["HS256"])

        user_id = payload.get("user_id")
        email = payload.get("email")

        if not user_id or not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )

        # Get user profile from database
        response = supabase_admin.table("users").select("*").eq("id", user_id).execute()

        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )

        user_data = response.data[0]

        # Map database fields to User schema
        mapped_data = {
            "id": user_data["id"],
            "name": user_data.get("full_name"),
            "email": user_data["email"],
            "position": user_data.get("position"),
            "bio": user_data.get("bio"),
            "image_url": user_data.get("avatar_url"),
            "is_admin": user_data.get("role") == "admin",
            "created_at": user_data["created_at"]
        }
        return User(**mapped_data)

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )