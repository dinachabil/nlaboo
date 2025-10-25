// Input validation utilities for Edge Functions

export interface ValidationError {
  field: string
  message: string
}

export class ValidationException extends Error {
  public errors: ValidationError[]

  constructor(errors: ValidationError[]) {
    super('Validation failed')
    this.errors = errors
    this.name = 'ValidationException'
  }
}

// UUID validation
export function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

// Email validation
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

// Date validation
export function isValidDate(dateString: string): boolean {
  const date = new Date(dateString)
  return date instanceof Date && !isNaN(date.getTime())
}

// Future date validation
export function isFutureDate(dateString: string): boolean {
  const date = new Date(dateString)
  const now = new Date()
  return date > now
}

// Required field validation
export function validateRequired(value: any, fieldName: string): ValidationError | null {
  if (value === null || value === undefined || value === '') {
    return { field: fieldName, message: `${fieldName} is required` }
  }
  return null
}

// String length validation
export function validateStringLength(
  value: string,
  fieldName: string,
  minLength?: number,
  maxLength?: number
): ValidationError | null {
  if (typeof value !== 'string') {
    return { field: fieldName, message: `${fieldName} must be a string` }
  }

  if (minLength !== undefined && value.length < minLength) {
    return { field: fieldName, message: `${fieldName} must be at least ${minLength} characters` }
  }

  if (maxLength !== undefined && value.length > maxLength) {
    return { field: fieldName, message: `${fieldName} must be no more than ${maxLength} characters` }
  }

  return null
}

// UUID validation
export function validateUUID(value: string, fieldName: string): ValidationError | null {
  if (!isValidUUID(value)) {
    return { field: fieldName, message: `${fieldName} must be a valid UUID` }
  }
  return null
}

// Email validation
export function validateEmail(value: string, fieldName: string): ValidationError | null {
  if (!isValidEmail(value)) {
    return { field: fieldName, message: `${fieldName} must be a valid email address` }
  }
  return null
}

// Enum validation
export function validateEnum(value: string, fieldName: string, allowedValues: string[]): ValidationError | null {
  if (!allowedValues.includes(value)) {
    return { field: fieldName, message: `${fieldName} must be one of: ${allowedValues.join(', ')}` }
  }
  return null
}

// Date validation
export function validateDate(value: string, fieldName: string, mustBeFuture: boolean = false): ValidationError | null {
  if (!isValidDate(value)) {
    return { field: fieldName, message: `${fieldName} must be a valid date` }
  }

  if (mustBeFuture && !isFutureDate(value)) {
    return { field: fieldName, message: `${fieldName} must be in the future` }
  }

  return null
}

// Number validation
export function validateNumber(value: any, fieldName: string, min?: number, max?: number): ValidationError | null {
  const num = Number(value)
  if (isNaN(num)) {
    return { field: fieldName, message: `${fieldName} must be a valid number` }
  }

  if (min !== undefined && num < min) {
    return { field: fieldName, message: `${fieldName} must be at least ${min}` }
  }

  if (max !== undefined && num > max) {
    return { field: fieldName, message: `${fieldName} must be no more than ${max}` }
  }

  return null
}

// Array validation
export function validateArray(value: any, fieldName: string, minLength?: number, maxLength?: number): ValidationError | null {
  if (!Array.isArray(value)) {
    return { field: fieldName, message: `${fieldName} must be an array` }
  }

  if (minLength !== undefined && value.length < minLength) {
    return { field: fieldName, message: `${fieldName} must have at least ${minLength} items` }
  }

  if (maxLength !== undefined && value.length > maxLength) {
    return { field: fieldName, message: `${fieldName} must have no more than ${maxLength} items` }
  }

  return null
}

// Phone number validation
export function isValidPhoneNumber(phoneNumber: string, countryCode: string = 'MA'): boolean {
  try {
    // Basic phone number pattern validation
    // Remove all non-digit characters except + at the beginning
    const cleaned = phoneNumber.replace(/[^\d+]/g, '')

    // Must start with + or digit
    if (!cleaned.match(/^(\+|)\d+$/)) {
      return false
    }

    // For Morocco (MA), validate specific patterns
    if (countryCode === 'MA') {
      // Moroccan numbers should be 9 digits after +212 or 212
      const moroccanPattern = /^(\+212|212)?[567]\d{8}$/
      return moroccanPattern.test(cleaned.replace(/^\+?212/, ''))
    }

    // For other countries, basic length check (7-15 digits is typical)
    const digitsOnly = cleaned.replace(/^\+/, '')
    return digitsOnly.length >= 7 && digitsOnly.length <= 15
  } catch {
    return false
  }
}

// Phone number validation with error details
export function validatePhoneNumber(value: string, fieldName: string, countryCode: string = 'MA'): ValidationError | null {
  if (typeof value !== 'string') {
    return { field: fieldName, message: `${fieldName} must be a string` }
  }

  if (!value.trim()) {
    return { field: fieldName, message: `${fieldName} is required` }
  }

  if (!isValidPhoneNumber(value, countryCode)) {
    if (countryCode === 'MA') {
      return { field: fieldName, message: `${fieldName} must be a valid Moroccan phone number (e.g., +212612345678 or 0612345678)` }
    }
    return { field: fieldName, message: `${fieldName} must be a valid phone number` }
  }

  return null
}

// Comprehensive validation function
export function validateInput(data: Record<string, any>, rules: Record<string, (value: any) => ValidationError | null>): ValidationError[] {
  const errors: ValidationError[] = []

  for (const [field, validator] of Object.entries(rules)) {
    const error = validator(data[field])
    if (error) {
      errors.push(error)
    }
  }

  return errors
}

// Throw validation exception if errors exist
export function validateAndThrow(data: Record<string, any>, rules: Record<string, (value: any) => ValidationError | null>): void {
  const errors = validateInput(data, rules)
  if (errors.length > 0) {
    throw new ValidationException(errors)
  }
}