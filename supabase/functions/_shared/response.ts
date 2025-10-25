import { corsHeaders } from './cors.ts'

// Standard response utilities for Edge Functions

export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  error?: string
  message?: string
}

// Success response
export function successResponse<T = any>(
  data: T,
  message?: string,
  status: number = 200
): Response {
  const response: ApiResponse<T> = {
    success: true,
    data,
    ...(message && { message })
  }

  return new Response(JSON.stringify(response), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json'
    }
  })
}

// Error response
export function errorResponse(
  error: string,
  status: number = 400,
  details?: any
): Response {
  const response: ApiResponse = {
    success: false,
    error,
    ...(details && { data: details })
  }

  return new Response(JSON.stringify(response), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json'
    }
  })
}

// Validation error response
export function validationErrorResponse(errors: Array<{ field: string; message: string }>): Response {
  return errorResponse('Validation failed', 400, { errors })
}

// Unauthorized response
export function unauthorizedResponse(message: string = 'Unauthorized'): Response {
  return errorResponse(message, 401)
}

// Forbidden response
export function forbiddenResponse(message: string = 'Forbidden'): Response {
  return errorResponse(message, 403)
}

// Not found response
export function notFoundResponse(message: string = 'Not found'): Response {
  return errorResponse(message, 404)
}

// Internal server error response
export function serverErrorResponse(message: string = 'Internal server error'): Response {
  return errorResponse(message, 500)
}

// Handle different types of errors and return appropriate responses
export function handleError(error: any): Response {
  console.error('Edge Function error:', error)

  // Database errors
  if (error.name === 'DatabaseError') {
    return errorResponse(error.message, 500, {
      code: error.code,
      details: error.details
    })
  }

  // Authentication errors
  if (error.name === 'AuthError') {
    return errorResponse(error.message, error.status || 401)
  }

  // Validation errors
  if (error.name === 'ValidationException') {
    return validationErrorResponse(error.errors)
  }

  // Supabase auth errors
  if (error.message?.includes('JWT') || error.message?.includes('token')) {
    return unauthorizedResponse('Invalid or expired token')
  }

  // Default error response
  return serverErrorResponse('An unexpected error occurred')
}