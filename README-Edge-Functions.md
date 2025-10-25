# Supabase Edge Functions Setup

This document provides setup and usage instructions for the Supabase Edge Functions infrastructure.

## 📁 Project Structure

```
supabase/
├── functions/
│   ├── _shared/
│   │   ├── auth.ts          # Authentication helpers
│   │   ├── cors.ts          # CORS headers utility
│   │   ├── database.ts      # Database query helpers
│   │   ├── response.ts      # Response utilities
│   │   └── validation.ts    # Input validation utilities
│   ├── create-match/
│   │   └── index.ts         # Create match endpoint
│   ├── create-team/
│   │   └── index.ts         # Create team endpoint
│   └── get-matches/
│       └── index.ts         # Get matches endpoint
├── config.toml              # Edge Functions configuration
└── ...

deploy-edge-functions.sh     # Deployment script
```

## 🚀 Quick Start

### Prerequisites

1. **Supabase CLI**: Install the Supabase CLI
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link your project** (if not already linked):
   ```bash
   cd supabase
   supabase link --project-ref gydwzgeojqydriamqfsj
   ```

### Deploy Edge Functions

Run the deployment script:

```bash
./deploy-edge-functions.sh
```

Or deploy manually:

```bash
cd supabase
supabase functions deploy create-match
supabase functions deploy create-team
supabase functions deploy get-matches
```

## 🔧 Configuration

### Environment Variables

The `supabase/config.toml` file contains all necessary environment variables:

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Anonymous key for client-side operations
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for server-side operations (keep secret!)

### Database Schema

Ensure your Supabase database has the following tables (defined in `supabase_schema.sql`):

- `users` - User profiles
- `teams` - Team information
- `team_members` - Team membership
- `matches` - Match information
- `match_participants` - Match participation
- `notifications` - User notifications
- `cities` - Location data

## 📚 API Reference

### Authentication

All protected endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <your-jwt-token>
```

### Endpoints

#### POST /functions/v1/create-match

Create a new match between two teams.

**Request Body:**
```json
{
  "team1Id": "uuid",
  "team2Id": "uuid",
  "matchDate": "2024-01-01T10:00:00Z",
  "location": "Stadium Name",
  "title": "Friendly Match",
  "maxPlayers": 22
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "team1_id": "uuid",
    "team2_id": "uuid",
    "match_date": "2024-01-01T10:00:00Z",
    "location": "Stadium Name",
    "title": "Friendly Match",
    "max_players": 22,
    "status": "open",
    "created_at": "2024-01-01T09:00:00Z"
  },
  "message": "Match created successfully"
}
```

#### POST /functions/v1/create-team

Create a new team.

**Request Body:**
```json
{
  "name": "Team Name",
  "location": "City, Country",
  "description": "Team description",
  "maxPlayers": 11
}
```

#### GET /functions/v1/get-matches

Get matches with optional filters.

**Query Parameters:**
- `status`: Filter by status (`open`, `closed`, `completed`, `cancelled`)
- `limit`: Number of results (1-100, default: 50)
- `offset`: Pagination offset (default: 0)

**Example:**
```
GET /functions/v1/get-matches?status=open&limit=10
```

## 🛠️ Development

### Local Development

1. **Start Supabase locally**:
   ```bash
   supabase start
   ```

2. **Serve functions locally**:
   ```bash
   cd supabase
   supabase functions serve
   ```

3. **Test functions**:
   ```bash
   curl -X POST 'http://localhost:54321/functions/v1/create-match' \
     -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
     -H 'Content-Type: application/json' \
     -d '{"team1Id": "uuid", "team2Id": "uuid", "matchDate": "2024-01-01T10:00:00Z", "location": "Stadium"}'
   ```

### Adding New Functions

1. Create a new directory under `supabase/functions/`
2. Add an `index.ts` file with your function logic
3. Use the shared utilities from `_shared/`
4. Update `supabase/config.toml` if needed
5. Update the deployment script

### Shared Utilities

#### Authentication (`_shared/auth.ts`)

```typescript
import { authenticateUser } from '../_shared/auth.ts'

// Authenticate user
const user = await authenticateUser(request)
```

#### Validation (`_shared/validation.ts`)

```typescript
import { validateAndThrow, validateRequired, validateUUID } from '../_shared/validation.ts'

// Validate input
validateAndThrow(data, {
  teamId: (value) => validateRequired(value, 'teamId') || validateUUID(value, 'teamId')
})
```

#### Database Operations (`_shared/database.ts`)

```typescript
import { matchQueries, teamQueries } from '../_shared/database.ts'

// Get match
const match = await matchQueries.getMatchById(matchId)

// Create team
const team = await teamQueries.createTeam(teamData)
```

#### Response Utilities (`_shared/response.ts`)

```typescript
import { successResponse, handleError } from '../_shared/response.ts'

// Success response
return successResponse(data, 'Operation successful')

// Error handling
catch (error) {
  return handleError(error)
}
```

## 🧪 Testing

### Unit Tests

Create test files alongside your functions:

```typescript
// supabase/functions/create-match/index.test.ts
import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts'

Deno.test('create-match validation', () => {
  // Test validation logic
})
```

Run tests:

```bash
cd supabase
supabase functions test
```

### Integration Tests

Test with real Supabase instances:

```bash
# Test against local Supabase
supabase test

# Test against production
supabase test --db-url "postgresql://..."
```

## 🔒 Security

### Row Level Security (RLS)

All database operations respect Supabase's RLS policies. Ensure your database has proper RLS enabled:

```sql
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
```

### Authentication

- JWT tokens are validated on every request
- Service role key is used for server-side operations
- CORS is properly configured

### Input Validation

All inputs are validated using the shared validation utilities to prevent injection attacks.

## 📊 Monitoring

### Logs

View function logs:

```bash
supabase functions logs create-match
```

### Performance

Monitor function execution times and errors in the Supabase dashboard.

## 🚀 Deployment

### Production Deployment

1. Ensure all environment variables are set in Supabase dashboard
2. Run the deployment script:
   ```bash
   ./deploy-edge-functions.sh
   ```
3. Verify functions are working in production

### CI/CD Integration

Add to your CI/CD pipeline:

```yaml
- name: Deploy Edge Functions
  run: |
    supabase link --project-ref $SUPABASE_PROJECT_REF
    supabase functions deploy
```

## 🐛 Troubleshooting

### Common Issues

1. **"Function not found"**: Ensure function is deployed and URL is correct
2. **"Unauthorized"**: Check JWT token is valid and properly formatted
3. **"CORS error"**: Verify CORS headers are properly set
4. **"Database error"**: Check database connection and permissions

### Debug Mode

Enable debug logging:

```bash
cd supabase
SUPABASE_DEBUG=true supabase functions serve
```

## 📝 Contributing

1. Follow the existing code structure
2. Use shared utilities for common operations
3. Add proper error handling
4. Update documentation
5. Test thoroughly before deploying

## 📄 License

This project is part of the FootConnect application.