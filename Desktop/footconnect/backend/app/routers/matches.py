from fastapi import APIRouter, HTTPException, Depends, status
from typing import List
from ..schemas import Match, MatchCreate, Participant
from ..routers.auth import get_current_user
from ..supabase_client import supabase
from ..schemas import User

router = APIRouter()

@router.get("/", response_model=List[Match])
async def get_matches():
    try:
        response = supabase.table("matches").select("*").eq("status", "open").order("match_date").execute()
        matches = [Match(**match_data) for match_data in response.data]
        return matches
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve matches: {str(e)}"
        )

@router.get("/{match_id}", response_model=Match)
async def get_match(match_id: str):
    try:
        response = supabase.table("matches").select("*").eq("id", match_id).execute()
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        return Match(**response.data[0])
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve match: {str(e)}"
        )

@router.post("/", response_model=Match)
async def create_match(
    match: MatchCreate,
    current_user: User = Depends(get_current_user)
):
    # Only team owners and admins can create matches
    if current_user.is_admin:
        # Admins can create matches
        pass
    else:
        # Check if user is a team owner (this would need team logic)
        # For now, allow all authenticated users to create matches
        pass

    try:
        match_data = {
            "title": match.title,
            "location": match.location,
            "match_date": match.match_date.isoformat(),
            "max_players": match.max_players,
            "match_type": match.match_type,
            "team1_id": match.team1_id,
            "team2_id": match.team2_id,
            "owner_id": current_user.id,
            "status": "open"
        }

        response = supabase.table("matches").insert(match_data).execute()
        created_match = Match(**response.data[0])
        return created_match
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create match: {str(e)}"
        )

@router.put("/{match_id}", response_model=Match)
async def update_match(
    match_id: str,
    match: MatchCreate,
    current_user: User = Depends(get_current_user)
):
    try:
        # Get existing match
        existing_response = supabase.table("matches").select("*").eq("id", match_id).execute()
        if not existing_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )

        existing_match = existing_response.data[0]

        # Check permissions (owner or admin)
        if existing_match["owner_id"] != current_user.id and not current_user.is_admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this match"
            )

        update_data = {
            "title": match.title,
            "location": match.location,
            "match_date": match.match_date.isoformat(),
            "max_players": match.max_players,
            "match_type": match.match_type
        }

        response = supabase.table("matches").update(update_data).eq("id", match_id).execute()
        updated_match = Match(**response.data[0])
        return updated_match
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update match: {str(e)}"
        )

@router.delete("/{match_id}")
async def delete_match(
    match_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        # Get existing match
        existing_response = supabase.table("matches").select("*").eq("id", match_id).execute()
        if not existing_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )

        existing_match = existing_response.data[0]

        # Check permissions (owner or admin)
        if existing_match["owner_id"] != current_user.id and not current_user.is_admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this match"
            )

        supabase.table("matches").delete().eq("id", match_id).execute()
        return {"message": "Match deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete match: {str(e)}"
        )

@router.put("/{match_id}/close")
async def close_match(
    match_id: str,
    current_user: User = Depends(get_current_user)
):
    try:
        # Get existing match
        existing_response = supabase.table("matches").select("*").eq("id", match_id).execute()
        if not existing_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )

        existing_match = existing_response.data[0]

        # Check permissions (owner or admin)
        if existing_match["owner_id"] != current_user.id and not current_user.is_admin:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to close this match"
            )

        supabase.table("matches").update({"status": "closed"}).eq("id", match_id).execute()
        return {"message": "Match closed successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to close match: {str(e)}"
        )