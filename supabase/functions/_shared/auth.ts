import { createClient } from 'jsr:@supabase/supabase-js@2'
import { corsHeaders, handleCors } from './cors.ts'

// Types for authentication
export interface AuthenticatedUser {
  id: string
  email: string
  role?: string
  name?: string
}

export class AuthError extends Error {
  public status: number

  constructor(message: string, status: number = 401) {
    super(message)
    this.status = status
    this.name = 'AuthError'
  }
}

// Create Supabase client with service role key for server-side operations
export function createServiceClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error('Missing Supabase environment variables')
  }

  return createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  })
}

// Create Supabase client with anon key for client-side operations
export function createAnonClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error('Missing Supabase environment variables')
  }

  return createClient(supabaseUrl, supabaseAnonKey)
}

// Authenticate user from JWT token in Authorization header
export async function authenticateUser(request: Request): Promise<AuthenticatedUser> {
  const authHeader = request.headers.get('Authorization')

  if (!authHeader) {
    throw new AuthError('No authorization header provided', 401)
  }

  if (!authHeader.startsWith('Bearer ')) {
    throw new AuthError('Invalid authorization header format', 401)
  }

  const token = authHeader.replace('Bearer ', '')

  try {
    const supabase = createServiceClient()
    const { data: { user }, error } = await supabase.auth.getUser(token)

    if (error || !user) {
      throw new AuthError('Invalid or expired token', 401)
    }

    // Get additional user profile data
    const { data: profile, error: profileError } = await supabase
      .from('users')
      .select('name, role')
      .eq('id', user.id)
      .single()

    if (profileError) {
      console.warn('Could not fetch user profile:', profileError)
    }

    return {
      id: user.id,
      email: user.email!,
      role: profile?.role || 'player',
      name: profile?.name
    }
  } catch (error) {
    if (error instanceof AuthError) {
      throw error
    }
    throw new AuthError('Authentication failed', 401)
  }
}

// Check if user has required role
export function hasRole(user: AuthenticatedUser, requiredRoles: string[]): boolean {
  return requiredRoles.includes(user.role || 'player')
}

// Require authentication wrapper for Edge Functions
export function requireAuth(handler: (request: Request, user: AuthenticatedUser) => Promise<Response>) {
  return async (request: Request): Promise<Response> => {
    try {
      // Handle CORS
      const corsResponse = handleCors(request)
      if (corsResponse) return corsResponse

      // Authenticate user
      const user = await authenticateUser(request)

      // Call the actual handler
      return await handler(request, user)
    } catch (error) {
      if (error instanceof AuthError) {
        return new Response(
          JSON.stringify({ error: error.message }),
          {
            status: error.status,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }

      console.error('Unexpected auth error:', error)
      return new Response(
        JSON.stringify({ error: 'Internal server error' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }
  }
}

// Require specific roles wrapper
export function requireRoles(requiredRoles: string[], handler: (request: Request, user: AuthenticatedUser) => Promise<Response>) {
  return requireAuth(async (request: Request, user: AuthenticatedUser) => {
    if (!hasRole(user, requiredRoles)) {
      return new Response(
        JSON.stringify({ error: 'Insufficient permissions' }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    return await handler(request, user)
  })
}