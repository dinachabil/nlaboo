from fastapi import APIRouter, HTTPException, Depends, status
from typing import List
from ..schemas import Participant
from ..routers.auth import get_current_user
from ..supabase_client import supabase
from ..schemas import User

router = APIRouter()

@router.post("/{match_id}/join")
async def join_match(
    match_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        # Check if match exists and is open
        match_response = supabase.table("matches").select("*").eq("id", match_id).eq("status", "open").execute()
        if not match_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found or not open"
            )

        # Check if user is already participating
        existing_response = supabase.table("match_players").select("*").eq("match_id", match_id).eq("user_id", current_user.id).execute()
        if existing_response.data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Already participating in this match"
            )

        # Check participant limit
        match = match_response.data[0]
        participants_response = supabase.table("match_players").select("*").eq("match_id", match_id).execute()
        current_count = len(participants_response.data)

        if current_count >= match["max_players"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Match is full"
            )

        # Add participant
        participant_data = {
            "match_id": match_id,
            "user_id": current_user.id
        }

        supabase.table("match_players").insert(participant_data).execute()

        # Create notification for match owner
        if match["owner_id"] != current_user.id:
            notification_data = {
                "user_id": match["owner_id"],
                "type": "match_join",
                "message": f"{current_user.name or current_user.email} joined your match '{match['title']}'"
            }
            supabase.table("notifications").insert(notification_data).execute()

        return {"message": "Successfully joined match"}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to join match: {str(e)}"
        )

@router.post("/{match_id}/invite")
async def invite_player(
    match_id: str,
    player_email: str,
    current_user: User = Depends(get_current_user)
):
    try:
        # Check if match exists and user is owner
        match_response = supabase.table("matches").select("*").eq("id", match_id).execute()
        if not match_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )

        match = match_response.data[0]
        if match["owner_id"] != current_user.id and not current_user.is_admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to invite players to this match"
            )

        # Find player by email
        player_response = supabase.table("users").select("*").eq("email", player_email).execute()
        if not player_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Player not found"
            )

        player = player_response.data[0]

        # Check if player is already participating
        existing_response = supabase.table("match_players").select("*").eq("match_id", match_id).eq("user_id", player["id"]).execute()
        if existing_response.data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Player is already participating in this match"
            )

        # Create invitation (no status needed for basic functionality)
        participant_data = {
            "match_id": match_id,
            "user_id": player["id"]
        }

        supabase.table("match_players").insert(participant_data).execute()

        # Create notification for invited player
        notification_data = {
            "user_id": player["id"],
            "type": "match_invite",
            "message": f"You've been invited to join '{match['title']}' by {current_user.name or current_user.email}"
        }
        supabase.table("notifications").insert(notification_data).execute()

        return {"message": "Player invited successfully"}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to invite player: {str(e)}"
        )

@router.delete("/{match_id}/leave")
async def leave_match(
    match_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        # Check if user is participating
        existing_response = supabase.table("match_players").select("*").eq("match_id", match_id).eq("user_id", current_user.id).execute()
        if not existing_response.data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Not participating in this match"
            )

        # Remove participant
        supabase.table("match_players").delete().eq("match_id", match_id).eq("user_id", current_user.id).execute()

        # Get match details for notification
        match_response = supabase.table("matches").select("*").eq("id", match_id).execute()
        if match_response.data:
            match = match_response.data[0]
            # Create notification for match owner
            if match["owner_id"] != current_user.id:
                notification_data = {
                    "user_id": match["owner_id"],
                    "type": "match_leave",
                    "message": f"{current_user.name or current_user.email} left your match '{match['title']}'"
                }
                supabase.table("notifications").insert(notification_data).execute()

        return {"message": "Successfully left match"}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to leave match: {str(e)}"
        )

@router.get("/{match_id}/participants", response_model=List[Participant])
async def get_match_participants(match_id: str):
    try:
        response = supabase.table("match_players").select("*").eq("match_id", match_id).execute()
        participants = [Participant(**participant_data) for participant_data in response.data]
        return participants
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve participants: {str(e)}"
        )