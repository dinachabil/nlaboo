import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { authenticateUser } from '../_shared/auth.ts'
import { validateNumber } from '../_shared/validation.ts'
import { matchQueries } from '../_shared/database.ts'
import { successResponse, handleError } from '../_shared/response.ts'

interface GetMatchesRequest {
  status?: string
  limit?: number
  offset?: number
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: { 'Access-Control-Allow-Origin': '*' } })
  }

  if (req.method !== 'GET') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' }
    })
  }

  try {
    // Authenticate user (optional for viewing matches)
    let user
    try {
      user = await authenticateUser(req)
    } catch {
      // Allow unauthenticated access for viewing public matches
      user = null
    }

    // Parse query parameters
    const url = new URL(req.url)
    const status = url.searchParams.get('status')
    const limit = url.searchParams.get('limit')
    const offset = url.searchParams.get('offset')

    const filters: GetMatchesRequest = {}

    if (status) {
      // Validate status enum
      if (!['open', 'closed', 'completed', 'cancelled'].includes(status)) {
        throw new Error('Invalid status parameter')
      }
      filters.status = status
    }

    if (limit) {
      const limitNum = parseInt(limit)
      if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
        throw new Error('Limit must be between 1 and 100')
      }
      filters.limit = limitNum
    }

    if (offset) {
      const offsetNum = parseInt(offset)
      if (isNaN(offsetNum) || offsetNum < 0) {
        throw new Error('Offset must be non-negative')
      }
      filters.offset = offsetNum
    }

    // Get matches
    const matches = await matchQueries.getMatches(filters)

    return successResponse(matches, 'Matches retrieved successfully')

  } catch (error) {
    return handleError(error)
  }
})