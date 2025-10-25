from supabase import create_client, Client
from .config import settings

# Client for user-facing operations (respects RLS)
supabase: Client = create_client(
    settings.supabase_url,
    settings.supabase_anon_key
)

# Client for admin/backend operations (bypasses RLS)
supabase_admin: Client = create_client(
    settings.supabase_url,
    settings.supabase_service_role_key or settings.supabase_anon_key
)