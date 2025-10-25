import { createServiceClient } from './auth.ts'

// Database operation types
export class DatabaseError extends Error {
  public code?: string
  public details?: any

  constructor(message: string, code?: string, details?: any) {
    super(message)
    this.code = code
    this.details = details
    this.name = 'DatabaseError'
  }
}

// Generic database query wrapper with error handling
export async function executeQuery<T = any>(
  queryFn: (supabase: any) => Promise<{ data: T | null; error: any }>
): Promise<T | null> {
  try {
    const supabase = createServiceClient()
    const { data, error } = await queryFn(supabase)

    if (error) {
      throw new DatabaseError(error.message, error.code, error.details)
    }

    return data
  } catch (error) {
    if (error instanceof DatabaseError) {
      throw error
    }
    throw new DatabaseError('Database operation failed', 'UNKNOWN_ERROR', error)
  }
}

// User-related database operations
export const userQueries = {
  // Get user profile by ID
  async getUserById(userId: string) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single()
    })
  },

  // Update user profile
  async updateUser(userId: string, updates: Record<string, any>) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('users')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', userId)
        .select()
        .single()
    })
  },

  // Check if user exists
  async userExists(userId: string): Promise<boolean> {
    try {
      await this.getUserById(userId)
      return true
    } catch {
      return false
    }
  }
}

// Team-related database operations
export const teamQueries = {
  // Get team by ID with owner info
  async getTeamById(teamId: string) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('teams')
        .select(`
          *,
          owner:users!teams_owner_id_fkey(name, email)
        `)
        .eq('id', teamId)
        .single()
    })
  },

  // Get teams owned by user
  async getTeamsByOwner(ownerId: string) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('teams')
        .select('*')
        .eq('owner_id', ownerId)
        .order('created_at', { ascending: false })
    })
  },

  // Create new team
  async createTeam(teamData: {
    name: string
    owner_id: string
    location?: string
    description?: string
    max_players?: number
  }) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('teams')
        .insert(teamData)
        .select()
        .single()
    })
  },

  // Update team
  async updateTeam(teamId: string, ownerId: string, updates: Record<string, any>) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('teams')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', teamId)
        .eq('owner_id', ownerId)
        .select()
        .single()
    })
  }
}

// Match-related database operations
export const matchQueries = {
  // Get match by ID with team details
  async getMatchById(matchId: string) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('matches')
        .select(`
          *,
          team1:teams!matches_team1_id_fkey(id, name, owner_id),
          team2:teams!matches_team2_id_fkey(id, name, owner_id)
        `)
        .eq('id', matchId)
        .single()
    })
  },

  // Get matches with filters
  async getMatches(filters: {
    status?: string
    limit?: number
    offset?: number
  } = {}) {
    return executeQuery(async (supabase) => {
      let query = supabase
        .from('matches')
        .select(`
          *,
          team1:teams!matches_team1_id_fkey(id, name, owner_id),
          team2:teams!matches_team2_id_fkey(id, name, owner_id)
        `)
        .order('match_date', { ascending: true })

      if (filters.status) {
        query = query.eq('status', filters.status)
      }

      if (filters.limit) {
        query = query.limit(filters.limit)
      }

      if (filters.offset) {
        query = query.range(filters.offset, filters.offset + (filters.limit || 10) - 1)
      }

      return query
    })
  },

  // Create new match
  async createMatch(matchData: {
    team1_id: string
    team2_id: string
    match_date: string
    location: string
    title?: string
    max_players?: number
  }) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('matches')
        .insert(matchData)
        .select()
        .single()
    })
  },

  // Update match
  async updateMatch(matchId: string, updates: Record<string, any>) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('matches')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', matchId)
        .select()
        .single()
    })
  }
}

// Notification-related database operations
export const notificationQueries = {
  // Get user notifications
  async getUserNotifications(userId: string, limit: number = 50) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(limit)
    })
  },

  // Create notification
  async createNotification(notificationData: {
    user_id: string
    title: string
    message: string
    type: string
    related_id?: string
  }) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('notifications')
        .insert(notificationData)
        .select()
        .single()
    })
  },

  // Mark notification as read
  async markAsRead(notificationId: string, userId: string) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('id', notificationId)
        .eq('user_id', userId)
        .select()
        .single()
    })
  }
}

// Team member operations
export const teamMemberQueries = {
  // Get team members
  async getTeamMembers(teamId: string) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('team_members')
        .select(`
          *,
          user:users!team_members_user_id_fkey(id, name, email, avatar_url)
        `)
        .eq('team_id', teamId)
        .order('joined_at', { ascending: true })
    })
  },

  // Add team member
  async addTeamMember(teamId: string, userId: string, role: string = 'member') {
    return executeQuery(async (supabase) => {
      return supabase
        .from('team_members')
        .insert({
          team_id: teamId,
          user_id: userId,
          role: role
        })
        .select()
        .single()
    })
  },

  // Remove team member
  async removeTeamMember(teamId: string, userId: string) {
    return executeQuery(async (supabase) => {
      return supabase
        .from('team_members')
        .delete()
        .eq('team_id', teamId)
        .eq('user_id', userId)
    })
  }
}