from fastapi import APIRouter, HTTPException, Depends, status
from typing import List
from ..schemas import User, UserUpdate
from ..routers.auth import get_current_user
from ..supabase_client import supabase, supabase_admin
from fastapi import UploadFile, File

router = APIRouter()

@router.post("/me/avatar")
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """Upload avatar image for current user"""
    try:
        # Validate file type
        allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        if file.content_type not in allowed_types:
            raise HTTPException(status_code=400, detail="Invalid file type. Only JPEG, PNG, GIF, and WebP are allowed.")

        # Validate file size (max 5MB)
        file_size = 0
        content = await file.read()
        file_size = len(content)

        if file_size > 5 * 1024 * 1024:  # 5MB
            raise HTTPException(status_code=400, detail="File too large. Maximum size is 5MB.")

        # Create unique filename
        import uuid
        file_extension = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
        unique_filename = f"{current_user.id}_{uuid.uuid4()}.{file_extension}"
        file_path = f"{current_user.id}/{unique_filename}"

        print(f"Uploading avatar for user {current_user.id}, file: {file_path}, size: {file_size} bytes")

        # Upload to Supabase Storage using admin client (bypasses RLS)
        bucket = supabase_admin.storage.from_('avatars')
        bucket.upload(
            path=file_path,
            file=content,
            file_options={
                'content-type': file.content_type,
                'upsert': True
            }
        )

        # Get public URL
        public_url = bucket.get_public_url(file_path)

        print(f"Avatar uploaded successfully: {public_url}")

        return {"avatar_url": public_url}

    except HTTPException:
        raise
    except Exception as e:
        print(f"Error uploading avatar: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to upload avatar: {str(e)}")

@router.get("/me", response_model=User)
async def get_current_user_profile(current_user: User = Depends(get_current_user)):
    # Fetch fresh user data from database using admin client
    response = supabase_admin.table("users").select("*").eq("id", current_user.id).execute()
    if not response.data:
        raise HTTPException(status_code=404, detail="User not found")
    return User(**response.data[0])

@router.put("/me", response_model=User)
async def update_current_user_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user)
):
    try:
        print(f"DEBUG: Updating profile for user {current_user.id}")
        print(f"DEBUG: User update data: {user_update.dict()}")

        # Check current user data to enforce field restrictions
        current_user_data = supabase_admin.table("users").select("*").eq("id", current_user.id).execute()
        if not current_user_data.data:
            raise HTTPException(status_code=404, detail="User not found")

        current_user_record = current_user_data.data[0]

        update_data = {}
        if user_update.name is not None:
            update_data["full_name"] = user_update.name
        if user_update.position is not None:
            update_data["position"] = user_update.position
        if user_update.bio is not None:
            update_data["bio"] = user_update.bio
        if user_update.image_url is not None:
            update_data["avatar_url"] = user_update.image_url

        # Only allow gender update if not already set (first registration only)
        if user_update.gender is not None and current_user_record.get("gender") is None:
            update_data["gender"] = user_update.gender
        elif user_update.gender is not None and current_user_record.get("gender") is not None:
            print(f"DEBUG: Attempted to update gender for user {current_user.id}, but gender is already set to {current_user_record.get('gender')}")

        # Note: Age is not included in UserUpdate schema, so no restriction needed here

        print(f"DEBUG: Update data to be sent to Supabase: {update_data}")

        if update_data:
            # Check if user exists before update
            check_response = supabase_admin.table("users").select("*").eq("id", current_user.id).execute()
            print(f"DEBUG: User exists check - found {len(check_response.data)} records")

            update_result = supabase_admin.table("users").update(update_data).eq("id", current_user.id).execute()
            print(f"DEBUG: Update result: {update_result}")

            # Fetch updated user
            response = supabase_admin.table("users").select("*").eq("id", current_user.id).execute()
            print(f"DEBUG: Fetch after update - found {len(response.data)} records")

            if not response.data:
                print("DEBUG: ERROR - No user found after update!")
                raise HTTPException(status_code=404, detail="User not found after update")

            updated_user = response.data[0]
            print(f"DEBUG: Updated user data: {updated_user}")
            return User(**updated_user)
        else:
            print("DEBUG: No update data provided, returning current user")
            return current_user

    except Exception as e:
        print(f"DEBUG: Exception during profile update: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update profile: {str(e)}"
        )

@router.get("/", response_model=List[User])
async def get_all_users(current_user: User = Depends(get_current_user)):
    # Only admins can view all users
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to view all users"
        )

    try:
        response = supabase.table("users").select("*").execute()
        users = [User(**user_data) for user_data in response.data]
        return users
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve users: {str(e)}"
        )

@router.delete("/{user_id}")
async def delete_user(
    user_id: str,
    current_user: User = Depends(get_current_user)
):
    # Only admins can delete users
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete users"
        )

    try:
        # Delete from Supabase Auth
        supabase.auth.admin.delete_user(user_id)

        # Delete profile (cascade should handle this)
        supabase.table("users").delete().eq("id", user_id).execute()

        return {"message": "User deleted successfully"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete user: {str(e)}"
        )