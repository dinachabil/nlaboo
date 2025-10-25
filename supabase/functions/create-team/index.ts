import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { authenticateUser } from '../_shared/auth.ts'
import { validateAndThrow, validateRequired, validateStringLength, validateNumber } from '../_shared/validation.ts'
import { teamQueries, teamMemberQueries } from '../_shared/database.ts'
import { successResponse, handleError } from '../_shared/response.ts'

interface CreateTeamRequest {
  name: string
  location?: string
  description?: string
  maxPlayers?: number
  minAge?: number
  maxAge?: number
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: { 'Access-Control-Allow-Origin': '*' } })
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  try {
    // Authenticate user
    const user = await authenticateUser(req)

    // Parse request body
    const body: CreateTeamRequest = await req.json()

    // Validate input
    validateAndThrow(body, {
      name: (value) => validateRequired(value, 'name') || validateStringLength(value, 'name', 1, 100),
      location: (value) => value ? validateStringLength(value, 'location', 1, 255) : null,
      description: (value) => value ? validateStringLength(value, 'description', 1, 500) : null,
      maxPlayers: (value) => value ? validateNumber(value, 'maxPlayers', 1, 50) : null,
      minAge: (value) => value ? validateNumber(value, 'minAge', 10, 60) : null,
      maxAge: (value) => value ? validateNumber(value, 'maxAge', 10, 60) : null
    })

    // Additional validation for age range
    if (body.minAge && body.maxAge && body.minAge > body.maxAge) {
      throw new Error('Minimum age cannot be greater than maximum age')
    }

    // Create team
    const teamData = {
      name: body.name,
      owner_id: user.id,
      location: body.location,
      description: body.description,
      max_players: body.maxPlayers || 11,
      min_age: body.minAge || 15,
      max_age: body.maxAge || 40
    }

    const team = await teamQueries.createTeam(teamData)

    // Add creator as team member with captain role
    await teamMemberQueries.addTeamMember(team.id, user.id, 'captain')

    return successResponse(team, 'Team created successfully', 201)

  } catch (error) {
    return handleError(error)
  }
})