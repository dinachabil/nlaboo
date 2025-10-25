# ConnectFoot

A complete full-stack application for organizing amateur football matches and connecting teams with user roles and real-time features.

## 🏗️ Architecture

- **Frontend**: Flutter (Web & Mobile)
- **Backend**: FastAPI (Python)
- **Database**: Supabase (PostgreSQL with real-time features)
- **Authentication**: Supabase Auth (Email/Password)
- **State Management**: Provider (Flutter)
- **Navigation**: Go Router (Flutter)

## 📁 Project Structure

```
connectfoot/
├── backend/                    # FastAPI Backend
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py            # FastAPI app with CORS
│   │   ├── config.py          # Environment configuration
│   │   ├── supabase_client.py # Supabase client
│   │   ├── utils/
│   │   │   └── security.py    # JWT utilities
│   │   ├── schemas.py         # Pydantic models
│   │   └── routers/           # API endpoints
│   │       ├── auth.py        # Authentication
│   │       ├── users.py       # User management
│   │       ├── matches.py     # Match operations
│   │       ├── participants.py # Match participation
│   │       └── notifications.py # Notifications
│   ├── requirements.txt       # Python dependencies
│   └── .env                   # Environment variables
├── frontend/                  # Flutter Frontend
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── models/            # Data models
│   │   │   ├── user.dart
│   │   │   ├── match.dart
│   │   │   └── notification.dart
│   │   ├── providers/         # State management
│   │   │   └── auth_provider.dart
│   │   ├── services/          # API services
│   │   │   └── api_service.dart
│   │   └── screens/           # UI screens
│   │       ├── login_screen.dart
│   │       ├── signup_screen.dart
│   │       ├── home_screen.dart
│   │       ├── profile_screen.dart
│   │       ├── create_match_screen.dart
│   │       └── admin_dashboard_screen.dart
│   └── pubspec.yaml           # Flutter dependencies
├── supabase_setup.md          # Database setup instructions
└── README.md                  # This file
```

## 🚀 Features

### 👤 User Roles
- **Player**: Join/leave matches, view profile
- **Team Owner**: Create/manage matches
- **Admin**: Full system access, user/match management

### ⚽ Core Functionality
- User registration and authentication
- Match creation with date/time/location
- Match discovery and participation
- Profile management with avatar support
- Admin dashboard for system management
- Real-time notifications

### 🎨 UI/UX
- Material Design 3
- Mobile-first responsive design
- Dark/light theme support
- Intuitive navigation
- Form validation
- Loading states and error handling

## 🛠️ Setup Instructions

### 1. Supabase Setup
1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Enable Email/Password authentication
3. Run the SQL schema from `supabase_setup.md`
4. Configure Row Level Security policies
5. Get your project URL and anon key

### 2. Backend Setup
```bash
cd backend
pip install -r requirements.txt
# Update .env with your Supabase credentials
python main.py
```
Backend runs on `http://localhost:8001`

### 3. Frontend Setup
```bash
cd frontend
flutter pub get
flutter run -d web-server --web-port=8082
```
Frontend runs on `http://localhost:8082`

## 🔧 Environment Configuration

### Backend (.env)
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Frontend (lib/services/api_service.dart)
Update the `baseUrl` to match your backend:
```dart
static const String baseUrl = 'http://localhost:8001/api/v1';
```

## 📊 Database Schema

### Tables
- **profiles**: User profiles with roles
- **matches**: Football match details
- **participants**: Match participation records
- **notifications**: User notifications

### Key Relationships
- Users can participate in multiple matches
- Matches belong to owners (team owners/admins)
- Notifications are user-specific

## 🔐 Security Features

- JWT-based authentication
- Row Level Security (RLS) policies
- Password hashing with bcrypt
- CORS protection
- Input validation and sanitization

## 📱 API Endpoints

### Authentication
- `POST /api/v1/auth/signup` - User registration
- `POST /api/v1/auth/login` - User login

### Users
- `GET /api/v1/users/me` - Get current user profile
- `PUT /api/v1/users/me` - Update user profile
- `GET /api/v1/users` - Get all users (admin only)
- `DELETE /api/v1/users/{user_id}` - Delete user (admin only)

### Matches
- `GET /api/v1/matches` - Get available matches
- `POST /api/v1/matches` - Create new match
- `PUT /api/v1/matches/{match_id}` - Update match
- `DELETE /api/v1/matches/{match_id}` - Delete match
- `PUT /api/v1/matches/{match_id}/close` - Close match

### Participants
- `POST /api/v1/matches/{match_id}/join` - Join match
- `DELETE /api/v1/matches/{match_id}/leave` - Leave match
- `GET /api/v1/matches/{match_id}/participants` - Get match participants

### Notifications
- `GET /api/v1/notifications` - Get user notifications
- `PUT /api/v1/notifications/mark_read` - Mark notifications as read

## 🎯 User Flows

### Player Flow
1. Register/Login with email
2. Browse available matches
3. Join/leave matches
4. Update profile information

### Team Owner Flow
1. Register/Login (select team owner role)
2. Create matches with details
3. View match participants
4. Manage match status

### Admin Flow
1. Register/Login (select admin role)
2. View all users and matches
3. Delete users or close matches
4. System-wide management

## 🧪 Testing

### Backend Testing
```bash
cd backend
python -m pytest
```

### Frontend Testing
```bash
cd frontend
flutter test
```

## 🚀 Deployment

### Backend (Railway, Heroku, etc.)
1. Set environment variables
2. Deploy FastAPI app
3. Update CORS origins for production

### Frontend (Firebase Hosting, Vercel, etc.)
1. Build for web: `flutter build web`
2. Deploy build/web contents
3. Update API base URL for production

### Supabase
- Configure production database
- Set up proper RLS policies
- Enable production auth settings

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with proper testing
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
- Check the Supabase documentation
- Review FastAPI/FastAPI documentation
- Check Flutter documentation
- Open an issue on GitHub

---

**Built with ❤️ using Flutter, FastAPI, and Supabase**