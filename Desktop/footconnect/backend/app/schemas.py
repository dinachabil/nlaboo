from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional
from datetime import datetime

# Auth schemas
class UserSignup(BaseModel):
    name: str
    email: str  # Changed from EmailStr for development flexibility
    password: str
    role: str  # 'player', 'team', 'admin'
    gender: Optional[str] = None  # 'male', 'female'

    @validator('email')
    def validate_email(cls, v):
        # Basic email validation for development
        if '@' not in v or '.' not in v:
            raise ValueError('Invalid email format')
        return v.lower().strip()

class UserLogin(BaseModel):
    email: str  # Changed from EmailStr for development flexibility
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    email: Optional[str] = None

# User/Profile schemas
class User(BaseModel):
    id: str
    name: Optional[str] = None
    email: str
    position: Optional[str] = None
    bio: Optional[str] = None
    image_url: Optional[str] = None
    gender: Optional[str] = None  # 'male', 'female'
    is_admin: bool = False
    created_at: datetime

class UserUpdate(BaseModel):
    name: Optional[str] = None
    position: Optional[str] = None
    bio: Optional[str] = None
    image_url: Optional[str] = None
    gender: Optional[str] = None  # 'male', 'female'

# Match schemas
class MatchBase(BaseModel):
    title: str
    location: str
    match_date: datetime
    max_players: int = 22
    match_type: str = "male"  # 'male', 'female', 'mixed'
    team1_id: str
    team2_id: str

class MatchCreate(MatchBase):
    pass

class Match(MatchBase):
    id: str
    owner_id: str
    status: str = "open"
    created_at: datetime

    class Config:
        from_attributes = True

# Participant schemas
class Participant(BaseModel):
    id: str
    match_id: str
    user_id: str
    joined_at: datetime

# Team member schemas
class TeamMemberBase(BaseModel):
    team_id: str
    user_id: str
    role: str = "member"

class TeamMember(TeamMemberBase):
    id: str
    joined_at: datetime

    class Config:
        from_attributes = True

class TeamMemberCreate(BaseModel):
    team_id: str

# Message schemas
class MessageBase(BaseModel):
    team_id: str
    sender_id: str
    receiver_id: Optional[str] = None
    content: str
    message_type: str = "group"

class Message(MessageBase):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True

class MessageCreate(BaseModel):
    receiver_id: Optional[str] = None
    content: str
    message_type: str = "group"

# Enhanced Team schema
class TeamBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=50, description="Team name")
    location: Optional[str] = Field(None, max_length=100, description="Team location")
    description: Optional[str] = Field(None, max_length=500, description="Team description")
    logo_url: Optional[str] = Field(None, description="Team logo URL")
    max_players: int = Field(11, ge=5, le=50, description="Maximum players (5-50)")
    is_recruiting: bool = False

    @validator('name')
    def validate_name(cls, v):
        if not v.strip():
            raise ValueError('Team name cannot be empty')
        return v.strip()

    @validator('description')
    def validate_description(cls, v):
        if v is not None and len(v.strip()) == 0:
            return None  # Convert empty strings to None
        return v.strip() if v else v

class TeamCreate(TeamBase):
    pass

class Team(TeamBase):
    id: str
    owner_id: str
    created_at: datetime

    class Config:
        from_attributes = True

# Notification schemas
class Notification(BaseModel):
    id: str
    user_id: str
    type: str
    message: str
    read: bool = False
    created_at: datetime

class NotificationCreate(BaseModel):
    user_id: str
    type: str
    message: str

# Team Join Request schemas
class TeamJoinRequestBase(BaseModel):
    team_id: str
    user_id: str
    message: Optional[str] = None

class TeamJoinRequestCreate(BaseModel):
    team_id: str
    message: Optional[str] = None

class TeamJoinRequest(TeamJoinRequestBase):
    id: str
    status: str = "pending"
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class TeamJoinRequestUpdate(BaseModel):
    status: str  # 'approved', 'rejected'