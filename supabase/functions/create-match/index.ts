import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { authenticateUser } from '../_shared/auth.ts'
import { validateAndThrow, validateRequired, validateUUID, validateDate, validateStringLength, validateNumber } from '../_shared/validation.ts'
import { matchQueries, teamQueries, notificationQueries, teamMemberQueries } from '../_shared/database.ts'
import { successResponse, handleError } from '../_shared/response.ts'

interface CreateMatchRequest {
  team1Id: string
  team2Id: string
  matchDate: string
  location: string
  title?: string
  maxPlayers?: number
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
    const body: CreateMatchRequest = await req.json()

    // Validate input
    validateAndThrow(body, {
      team1Id: (value) => validateRequired(value, 'team1Id') || validateUUID(value, 'team1Id'),
      team2Id: (value) => validateRequired(value, 'team2Id') || validateUUID(value, 'team2Id'),
      matchDate: (value) => validateRequired(value, 'matchDate') || validateDate(value, 'matchDate', true),
      location: (value) => validateRequired(value, 'location') || validateStringLength(value, 'location', 1, 255),
      title: (value) => value ? validateStringLength(value, 'title', 1, 100) : null,
      maxPlayers: (value) => value ? validateNumber(value, 'maxPlayers', 2, 50) : null
    })

    // Verify teams exist and user has permission
    const [team1, team2] = await Promise.all([
      teamQueries.getTeamById(body.team1Id),
      teamQueries.getTeamById(body.team2Id)
    ])

    if (!team1 || !team2) {
      throw new Error('One or both teams not found')
    }

    // Check if user owns at least one team
    const userOwnsTeam = [team1.owner_id, team2.owner_id].includes(user.id)
    if (!userOwnsTeam) {
      throw new Error('You must own at least one participating team')
    }

    // Ensure teams are different
    if (body.team1Id === body.team2Id) {
      throw new Error('Team 1 and Team 2 must be different')
    }

    // Create match
    const matchData = {
      team1_id: body.team1Id,
      team2_id: body.team2Id,
      match_date: body.matchDate,
      location: body.location,
      title: body.title,
      max_players: body.maxPlayers || 22
    }

    const match = await matchQueries.createMatch(matchData)

    // Send notifications to team members
    try {
      const [team1Members, team2Members] = await Promise.all([
        teamMemberQueries.getTeamMembers(body.team1Id),
        teamMemberQueries.getTeamMembers(body.team2Id)
      ])

      const allMembers = [...team1Members, ...team2Members]
      const uniqueMembers = allMembers.filter((member, index, self) =>
        index === self.findIndex(m => m.user_id === member.user_id)
      )

      const notifications = uniqueMembers
        .filter(member => member.user_id !== user.id) // Don't notify the creator
        .map(member => ({
          user_id: member.user_id,
          title: 'New Match Created',
          message: `A new match "${match.title || 'Friendly Match'}" has been scheduled between ${team1.name} and ${team2.name}`,
          type: 'match_invite',
          related_id: match.id
        }))

      if (notifications.length > 0) {
        await Promise.all(notifications.map(notificationQueries.createNotification))
      }
    } catch (notificationError) {
      console.warn('Failed to send notifications:', notificationError)
      // Don't fail the match creation if notifications fail
    }

    return successResponse(match, 'Match created successfully', 201)

  } catch (error) {
    return handleError(error)
  }
})