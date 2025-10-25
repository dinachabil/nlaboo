from fastapi import APIRouter, HTTPException, Depends, status
from typing import List
from ..schemas import Notification, NotificationCreate
from ..routers.auth import get_current_user
from ..supabase_client import supabase
from ..schemas import User

router = APIRouter()

@router.get("/", response_model=List[Notification])
async def get_notifications(current_user: User = Depends(get_current_user)):
    try:
        response = supabase.table("notifications").select("*").eq("user_id", current_user.id).order("created_at", desc=True).execute()
        notifications = [Notification(**notification_data) for notification_data in response.data]
        return notifications
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve notifications: {str(e)}"
        )

@router.put("/mark_read")
async def mark_notifications_read(current_user: User = Depends(get_current_user)):
    try:
        supabase.table("notifications").update({"read": True}).eq("user_id", current_user.id).eq("read", False).execute()
        return {"message": "Notifications marked as read"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to mark notifications as read: {str(e)}"
        )

@router.post("/", response_model=Notification)
async def create_notification(
    notification: NotificationCreate,
    current_user: User = Depends(get_current_user)
):
    # Only admins can create notifications for others
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create notifications"
        )

    try:
        notification_data = {
            "user_id": notification.user_id,
            "type": notification.type,
            "message": notification.message,
            "read": False
        }

        response = supabase.table("notifications").insert(notification_data).execute()
        created_notification = Notification(**response.data[0])
        return created_notification
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create notification: {str(e)}"
        )