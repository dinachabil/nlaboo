import os
from dotenv import load_dotenv
from supabase import create_client, Client

# Load environment variables from backend/.env
load_dotenv('backend/.env')

# Initialize Supabase client
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_ANON_KEY")
)

def test_connection():
    try:
        # Test basic connection
        print("Testing Supabase connection...")

        # Try to get current user (should be None since we're not authenticated)
        user = supabase.auth.get_user()
        print(f"Current user: {user}")

        # Test signup
        print("Testing signup...")
        response = supabase.auth.sign_up({
            "email": "test@example.com",
            "password": "testpassword123",
            "data": {
                "full_name": "Test User"
            }
        })
        print(f"Signup response: {response}")

        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    test_connection()