from fastapi import APIRouter, Depends, HTTPException
from typing import List
from ..supabase_client import supabase
from .. import schemas
from .auth import get_current_user

router = APIRouter()

@router.get("/{team_id}", response_model=List[schemas.Message])
def get_team_messages(team_id: str, current_user = Depends(get_current_user)):
    """Get all messages for a team"""
    try:
        # Check if user is a member of the team
        member_check = supabase.table('team_members').select('*').eq('team_id', team_id).eq('user_id', current_user.id).execute()
        if not member_check.data:
            raise HTTPException(status_code=403, detail="Not a member of this team")

        # Get messages with sender details
        response = supabase.table('messages').select('*, users!messages_sender_id_fkey(full_name)').eq('team_id', team_id).order('created_at').execute()

        # Format the response
        messages = []
        for msg in response.data:
            msg['sender_name'] = msg['users']['full_name'] if msg.get('users') else 'Unknown'
            del msg['users']  # Remove nested user object
            messages.append(msg)

        return messages
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to fetch messages: {str(e)}")

@router.post("/", response_model=schemas.Message)
def send_message(message: schemas.MessageCreate, current_user = Depends(get_current_user)):
    """Send a message to a team"""
    try:
        # Check if user is a member of the team
        member_check = supabase.table('team_members').select('*').eq('team_id', message.team_id).eq('user_id', current_user.id).execute()
        if not member_check.data:
            raise HTTPException(status_code=403, detail="Not a member of this team")

        # For direct messages, check if receiver is also a team member
        if message.message_type == 'direct' and message.receiver_id:
            receiver_check = supabase.table('team_members').select('*').eq('team_id', message.team_id).eq('user_id', message.receiver_id).execute()
            if not receiver_check.data:
                raise HTTPException(status_code=400, detail="Receiver is not a member of this team")

        # Create message
        message_data = {
            "team_id": message.team_id,
            "sender_id": current_user.id,
            "receiver_id": message.receiver_id,
            "content": message.content,
            "message_type": message.message_type
        }

        response = supabase.table('messages').insert(message_data).select('*, users!messages_sender_id_fkey(full_name)').single().execute()
        created_message = response.data
        created_message['sender_name'] = created_message['users']['full_name'] if created_message.get('users') else 'Unknown'
        del created_message['users']

        return created_message
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to send message: {str(e)}")

@router.get("/direct/{other_user_id}", response_model=List[schemas.Message])
def get_direct_messages(other_user_id: str, current_user = Depends(get_current_user)):
    """Get direct messages between current user and another user"""
    try:
        # Find teams where both users are members
        user_teams = supabase.table('team_members').select('team_id').eq('user_id', current_user.id).execute()
        team_ids = [member['team_id'] for member in user_teams.data]

        if not team_ids:
            return []

        # Get direct messages between the two users in shared teams
        response = supabase.table('messages').select('*, users!messages_sender_id_fkey(full_name)').in_('team_id', team_ids).eq('message_type', 'direct').or_(
            f"and(sender_id.eq.{current_user.id},receiver_id.eq.{other_user_id}),and(sender_id.eq.{other_user_id},receiver_id.eq.{current_user.id})"
        ).order('created_at').execute()

        # Format the response
        messages = []
        for msg in response.data:
            msg['sender_name'] = msg['users']['full_name'] if msg.get('users') else 'Unknown'
            del msg['users']
            messages.append(msg)

        return messages
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to fetch direct messages: {str(e)}")

@router.delete("/{message_id}")
def delete_message(message_id: str, current_user = Depends(get_current_user)):
    """Delete a message (only sender can delete their own messages)"""
    try:
        # Check if message exists and user is the sender
        message_check = supabase.table('messages').select('*').eq('id', message_id).eq('sender_id', current_user.id).execute()
        if not message_check.data:
            raise HTTPException(status_code=403, detail="Can only delete your own messages")

        # Delete the message
        supabase.table('messages').delete().eq('id', message_id).execute()

        return {"message": "Message deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to delete message: {str(e)}")