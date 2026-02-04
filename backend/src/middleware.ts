import { Request, Response, NextFunction } from 'express'

// Rate limiting configuration
export interface RateLimitConfig {
  windowMs: number // Time window in milliseconds
  maxRequests: number // Maximum requests per window
  perEndpoint?: boolean // Apply per endpoint instead of global
}

// Default configuration
const DEFAULT_CONFIG: RateLimitConfig = {
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 100,
  perEndpoint: false,
}

// Store for tracking request counts
interface RateLimitStore {
  [key: string]: Array<number>
}

const store: RateLimitStore = {}

/**
 * Rate limiting middleware
 */
export function rateLimitMiddleware(config: Partial<RateLimitConfig> = {}) {
  const finalConfig = { ...DEFAULT_CONFIG, ...config }

  return (req: Request, res: Response, next: NextFunction) => {
    // Get identifier: IP address or user ID if authenticated
    let identifier = req.ip || 'unknown'
    if (finalConfig.perEndpoint) {
      identifier = `${req.ip}:${req.path}`
    }

    const now = Date.now()
    const windowStart = now - finalConfig.windowMs

    // Initialize store for this identifier if needed
    if (!store[identifier]) {
      store[identifier] = []
    }

    // Remove requests outside the window
    store[identifier] = store[identifier].filter((time) => time > windowStart)

    // Check if limit exceeded
    if (store[identifier].length >= finalConfig.maxRequests) {
      return res.status(429).json({
        error: 'Too Many Requests',
        message: `Rate limit exceeded. Maximum ${finalConfig.maxRequests} requests per ${finalConfig.windowMs / 1000 / 60} minutes.`,
        retryAfter: Math.ceil((store[identifier][0] + finalConfig.windowMs - now) / 1000),
      })
    }

    // Record this request
    store[identifier].push(now)

    // Add rate limit info to response headers
    res.setHeader('X-RateLimit-Limit', finalConfig.maxRequests)
    res.setHeader('X-RateLimit-Remaining', finalConfig.maxRequests - store[identifier].length)
    res.setHeader('X-RateLimit-Reset', new Date(store[identifier][0] + finalConfig.windowMs).toISOString())

    next()
  }
}

// Request validation schemas
export interface ValidationRule {
  type: 'string' | 'number' | 'boolean' | 'array' | 'object'
  required?: boolean
  min?: number // For strings: min length, for numbers: min value
  max?: number // For strings: max length, for numbers: max value
  pattern?: RegExp // For strings: regex pattern
  enum?: any[] // Allowed values
  items?: ValidationRule // For arrays: schema for items
}

export interface ValidationSchema {
  [key: string]: ValidationRule
}

/**
 * Validate request body against a schema
 */
export function validateBody(schema: ValidationSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const errors: { [key: string]: string } = {}
    const body = req.body || {}

    for (const [fieldName, rule] of Object.entries(schema)) {
      const value = body[fieldName]

      // Check required
      if (rule.required && (value === undefined || value === null || value === '')) {
        errors[fieldName] = `${fieldName} is required`
        continue
      }

      // Skip validation if not required and not provided
      if (!rule.required && (value === undefined || value === null)) {
        continue
      }

      // Type validation
      if (typeof value !== rule.type) {
        errors[fieldName] = `${fieldName} must be of type ${rule.type}, got ${typeof value}`
        continue
      }

      // String validations
      if (rule.type === 'string') {
        if (rule.min !== undefined && value.length < rule.min) {
          errors[fieldName] = `${fieldName} must be at least ${rule.min} characters long`
        }
        if (rule.max !== undefined && value.length > rule.max) {
          errors[fieldName] = `${fieldName} must be at most ${rule.max} characters long`
        }
        if (rule.pattern && !rule.pattern.test(value)) {
          errors[fieldName] = `${fieldName} does not match required pattern`
        }
      }

      // Number validations
      if (rule.type === 'number') {
        if (rule.min !== undefined && value < rule.min) {
          errors[fieldName] = `${fieldName} must be at least ${rule.min}`
        }
        if (rule.max !== undefined && value > rule.max) {
          errors[fieldName] = `${fieldName} must be at most ${rule.max}`
        }
      }

      // Enum validation
      if (rule.enum && !rule.enum.includes(value)) {
        errors[fieldName] = `${fieldName} must be one of: ${rule.enum.join(', ')}`
      }

      // Array validation
      if (rule.type === 'array' && !Array.isArray(value)) {
        errors[fieldName] = `${fieldName} must be an array`
      }
    }

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Request body validation failed',
        details: errors,
      })
    }

    next()
  }
}

/**
 * Sanitize request body to remove unexpected fields
 */
export function sanitizeBody(allowedFields: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const body = req.body || {}
    const sanitized: { [key: string]: any } = {}

    for (const field of allowedFields) {
      if (field in body) {
        sanitized[field] = body[field]
      }
    }

    req.body = sanitized
    next()
  }
}

/**
 * Validate query parameters
 */
export function validateQuery(schema: ValidationSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    const errors: { [key: string]: string } = {}
    const query = req.query

    for (const [fieldName, rule] of Object.entries(schema)) {
      const value = query[fieldName]

      // Check required
      if (rule.required && (value === undefined || value === null || value === '')) {
        errors[fieldName] = `${fieldName} is required`
        continue
      }

      // Skip validation if not required and not provided
      if (!rule.required && (value === undefined || value === null)) {
        continue
      }

      // Convert string to appropriate type
      let convertedValue: any = value

      if (rule.type === 'number') {
        convertedValue = Number(value)
        if (isNaN(convertedValue)) {
          errors[fieldName] = `${fieldName} must be a number`
          continue
        }
      } else if (rule.type === 'boolean') {
        convertedValue = value === 'true' || value === '1'
      }

      // Validate converted value
      if (rule.type === 'number') {
        if (rule.min !== undefined && convertedValue < rule.min) {
          errors[fieldName] = `${fieldName} must be at least ${rule.min}`
        }
        if (rule.max !== undefined && convertedValue > rule.max) {
          errors[fieldName] = `${fieldName} must be at most ${rule.max}`
        }
      }

      if (rule.enum && !rule.enum.includes(convertedValue)) {
        errors[fieldName] = `${fieldName} must be one of: ${rule.enum.join(', ')}`
      }
    }

    if (Object.keys(errors).length > 0) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Query parameters validation failed',
        details: errors,
      })
    }

    next()
  }
}

/**
 * Content-Type validation middleware
 */
export function requireContentType(types: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const contentType = req.get('content-type')?.split(';')[0].trim() || ''

    if (!types.includes(contentType)) {
      return res.status(415).json({
        error: 'Unsupported Media Type',
        message: `Content-Type must be one of: ${types.join(', ')}`,
      })
    }

    next()
  }
}

/**
 * Request size limit validation
 */
export function validateRequestSize(maxSizeBytes: number) {
  return (req: Request, res: Response, next: NextFunction) => {
    const contentLength = parseInt(req.get('content-length') || '0', 10)

    if (contentLength > maxSizeBytes) {
      return res.status(413).json({
        error: 'Payload Too Large',
        message: `Request body exceeds maximum size of ${maxSizeBytes} bytes`,
      })
    }

    next()
  }
}
