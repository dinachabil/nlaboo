from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ..supabase_client import supabase, supabase_admin
from .. import schemas
from .auth import get_current_user

router = APIRouter()

@router.post("/", response_model=schemas.Team)
def create_team(team: schemas.TeamCreate, current_user = Depends(get_current_user)):
    """Create a new team - ONLY stores in teams table"""
    try:
        # Check for duplicate team name by this user
        existing_team = supabase_admin.table('teams').select('*').eq('owner_id', current_user.id).eq('name', team.name).execute()
        if existing_team.data:
            raise HTTPException(status_code=400, detail="You already have a team with this name")

        # Create the team ONLY in teams table
        team_data = {
            "name": team.name,
            "owner_id": current_user.id,
            "location": team.location,
            "description": team.description,
            "logo_url": team.logo_url,
            "max_players": team.max_players,
            "is_recruiting": team.is_recruiting
        }

        response = supabase_admin.table('teams').insert(team_data).select().single().execute()
        created_team = response.data

        # Add creator as admin member in team_members table
        member_data = {
            "team_id": created_team['id'],
            "user_id": current_user.id,
            "role": "admin"
        }
        supabase_admin.table('team_members').insert(member_data).execute()

        return created_team
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to create team: {str(e)}")

@router.get("/", response_model=List[schemas.Team])
def get_all_teams():
    """Get all teams"""
    try:
        response = supabase.table('teams').select('*').execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to fetch teams: {str(e)}")

@router.get("/{team_id}", response_model=schemas.Team)
def get_team(team_id: str):
    """Get a specific team by ID"""
    try:
        response = supabase.table('teams').select('*').eq('id', team_id).single().execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=404, detail="Team not found")

@router.get("/{team_id}/members", response_model=List[schemas.User])
def get_team_members(team_id: str):
    """Get all members of a team"""
    try:
        # Get team members with their user details
        response = supabase_admin.table('team_members').select('*, users(*)').eq('team_id', team_id).execute()
        members = []
        for member in response.data:
            user_data = member['users']
            user_data['role'] = member['role']  # Add role to user data
            members.append(user_data)
        return members
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to fetch team members: {str(e)}")

@router.post("/{team_id}/join")
def join_team(team_id: str, current_user = Depends(get_current_user)):
    """Send a join request to a team (legacy endpoint - redirects to request system)"""
    try:
        # Check if team exists and is recruiting
        team_response = supabase_admin.table('teams').select('*').eq('id', team_id).single().execute()
        team = team_response.data

        if not team:
            raise HTTPException(status_code=404, detail="Team not found")

        if not team['is_recruiting']:
            raise HTTPException(status_code=400, detail="Team is not currently recruiting")

        # Check if user already has a pending or approved request
        existing_request = supabase_admin.table('team_join_requests').select('*').eq('team_id', team_id).eq('user_id', current_user.id).execute()
        if existing_request.data:
            request_data = existing_request.data[0]
            if request_data['status'] == 'approved':
                raise HTTPException(status_code=400, detail="You are already a member of this team")
            elif request_data['status'] == 'pending':
                raise HTTPException(status_code=400, detail="You already have a pending join request")

        # Check if user is already a member
        existing_member = supabase_admin.table('team_members').select('*').eq('team_id', team_id).eq('user_id', current_user.id).execute()
        if existing_member.data:
            raise HTTPException(status_code=400, detail="You are already a member of this team")

        # Create join request
        request_data = {
            "team_id": team_id,
            "user_id": current_user.id,
            "message": "Join request via legacy endpoint",
            "status": "pending"
        }

        supabase_admin.table('team_join_requests').insert(request_data).execute()

        return {"message": "Join request sent successfully. Waiting for team admin approval."}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to send join request: {str(e)}")

@router.delete("/{team_id}/leave")
def leave_team(team_id: str, current_user = Depends(get_current_user)):
    """Leave a team"""
    try:
        # Check if user is admin (admins can't leave, must transfer ownership or delete team)
        member_response = supabase_admin.table('team_members').select('*').eq('team_id', team_id).eq('user_id', current_user.id).single().execute()
        if member_response.data['role'] == 'admin':
            raise HTTPException(status_code=400, detail="Team admin cannot leave. Transfer ownership or delete team.")

        # Remove member
        supabase_admin.table('team_members').delete().eq('team_id', team_id).eq('user_id', current_user.id).execute()

        return {"message": "Successfully left the team"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to leave team: {str(e)}")

@router.get("/search/{query}", response_model=List[schemas.Team])
def search_teams(query: str):
    """Search teams by name or location"""
    try:
        # Sanitize input to prevent SQL injection
        safe_query = query.replace('%', '').replace('_', '').strip()
        if not safe_query:
            return []

        # Use Supabase's built-in text search for safety
        response = supabase.table('teams').select('*').or_(
            f"name.ilike.%{safe_query}%,location.ilike.%{safe_query}%"
        ).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to search teams: {str(e)}")

@router.put("/{team_id}/recruiting")
def toggle_recruiting(team_id: str, current_user = Depends(get_current_user)):
    """Toggle recruiting status for a team (admin only)"""
    try:
        # Check if user is admin of the team
        member_response = supabase_admin.table('team_members').select('*').eq('team_id', team_id).eq('user_id', current_user.id).eq('role', 'admin').execute()
        if not member_response.data:
            raise HTTPException(status_code=403, detail="Only team admin can toggle recruiting status")

        # Get current recruiting status
        team_response = supabase_admin.table('teams').select('is_recruiting').eq('id', team_id).single().execute()
        current_status = team_response.data['is_recruiting']

        # Toggle status
        supabase_admin.table('teams').update({'is_recruiting': not current_status}).eq('id', team_id).execute()

        return {"message": f"Recruiting {'enabled' if not current_status else 'disabled'}"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to toggle recruiting: {str(e)}")

# Team Join Request endpoints
@router.post("/{team_id}/join-requests", response_model=schemas.TeamJoinRequest)
def create_join_request(team_id: str, request: schemas.TeamJoinRequestCreate, current_user = Depends(get_current_user)):
    """Create a join request for a team"""
    try:
        # Check if team exists and is recruiting
        team_response = supabase_admin.table('teams').select('*').eq('id', team_id).single().execute()
        team = team_response.data

        if not team:
            raise HTTPException(status_code=404, detail="Team not found")

        if not team['is_recruiting']:
            raise HTTPException(status_code=400, detail="Team is not currently recruiting")

        # Check if user already has a pending or approved request
        existing_request = supabase_admin.table('team_join_requests').select('*').eq('team_id', team_id).eq('user_id', current_user.id).execute()
        if existing_request.data:
            request_data = existing_request.data[0]
            if request_data['status'] == 'approved':
                raise HTTPException(status_code=400, detail="You are already a member of this team")
            elif request_data['status'] == 'pending':
                raise HTTPException(status_code=400, detail="You already have a pending join request")

        # Check if user is already a member
        existing_member = supabase_admin.table('team_members').select('*').eq('team_id', team_id).eq('user_id', current_user.id).execute()
        if existing_member.data:
            raise HTTPException(status_code=400, detail="You are already a member of this team")

        # Create join request
        request_data = {
            "team_id": team_id,
            "user_id": current_user.id,
            "message": request.message,
            "status": "pending"
        }

        response = supabase_admin.table('team_join_requests').insert(request_data).select().single().execute()
        return response.data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to create join request: {str(e)}")

@router.get("/{team_id}/join-requests", response_model=List[schemas.TeamJoinRequest])
def get_team_join_requests(team_id: str, current_user = Depends(get_current_user)):
    """Get join requests for a team (team admin only)"""
    try:
        # Check if user is admin of the team
        member_response = supabase_admin.table('team_members').select('*').eq('team_id', team_id).eq('user_id', current_user.id).eq('role', 'admin').execute()
        if not member_response.data:
            raise HTTPException(status_code=403, detail="Only team admin can view join requests")

        # Get join requests with user details
        response = supabase_admin.table('team_join_requests').select('*, users(*)').eq('team_id', team_id).execute()
        return response.data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to get join requests: {str(e)}")

@router.put("/{team_id}/join-requests/{request_id}", response_model=schemas.TeamJoinRequest)
def update_join_request_status(team_id: str, request_id: str, update: schemas.TeamJoinRequestUpdate, current_user = Depends(get_current_user)):
    """Approve or reject a join request (team admin only)"""
    try:
        # Check if user is admin of the team
        member_response = supabase_admin.table('team_members').select('*').eq('team_id', team_id).eq('user_id', current_user.id).eq('role', 'admin').execute()
        if not member_response.data:
            raise HTTPException(status_code=403, detail="Only team admin can update join requests")

        # Update the request status
        update_data = {
            "status": update.status,
            "updated_at": "now()"
        }

        response = supabase_admin.table('team_join_requests').update(update_data).eq('id', request_id).eq('team_id', team_id).select('*, users(*)').single().execute()

        # If approved, add user to team members
        if update.status == 'approved':
            request_data = response.data
            member_data = {
                "team_id": team_id,
                "user_id": request_data['user_id'],
                "role": "member"
            }
            supabase_admin.table('team_members').insert(member_data).execute()

        return response.data

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to update join request: {str(e)}")

@router.get("/my-join-requests", response_model=List[schemas.TeamJoinRequest])
def get_my_join_requests(current_user = Depends(get_current_user)):
    """Get current user's join requests"""
    try:
        response = supabase_admin.table('team_join_requests').select('*, teams(*)').eq('user_id', current_user.id).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to get join requests: {str(e)}")