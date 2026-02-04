import { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'
import bcrypt from 'bcryptjs'

// Types
export interface AuthenticatedRequest extends Request {
  user?: {
    id: string
    username: string
    role: 'admin' | 'user' | 'viewer'
  }
  token?: string
}

export interface TokenPayload {
  id: string
  username: string
  role: 'admin' | 'user' | 'viewer'
  iat?: number
  exp?: number
}

// Configuration
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production'
const JWT_EXPIRY = process.env.JWT_EXPIRY || '24h'

// User database (in-memory for demo, replace with actual database)
const users = new Map<string, { password: string; role: 'admin' | 'user' | 'viewer' }>()

// Initialize default users
function initializeDefaultUsers() {
  // Default admin user: admin/admin (should be changed in production)
  const hashedPassword = bcrypt.hashSync('admin', 10)
  users.set('admin', {
    password: hashedPassword,
    role: 'admin',
  })

  // Default user: user/user
  users.set('user', {
    password: bcrypt.hashSync('user', 10),
    role: 'user',
  })

  // Default viewer: viewer/viewer
  users.set('viewer', {
    password: bcrypt.hashSync('viewer', 10),
    role: 'viewer',
  })
}

initializeDefaultUsers()

/**
 * Hash a password using bcrypt
 */
export function hashPassword(password: string): string {
  return bcrypt.hashSync(password, 10)
}

/**
 * Verify a password against a hash
 */
export function verifyPassword(password: string, hash: string): boolean {
  return bcrypt.compareSync(password, hash)
}

/**
 * Generate a JWT token
 */
export function generateToken(user: { id: string; username: string; role: 'admin' | 'user' | 'viewer' }): string {
  const payload: TokenPayload = {
    id: user.id,
    username: user.username,
    role: user.role,
  }
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRY })
}

/**
 * Verify a JWT token
 */
export function verifyToken(token: string): TokenPayload | null {
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as TokenPayload
    return decoded
  } catch (error) {
    return null
  }
}

/**
 * Middleware to authenticate requests using JWT
 */
export function authMiddleware(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization

  if (!authHeader) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'No authorization token provided',
    })
  }

  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader

  const decoded = verifyToken(token)
  if (!decoded) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or expired token',
    })
  }

  req.user = {
    id: decoded.id,
    username: decoded.username,
    role: decoded.role,
  }
  req.token = token

  next()
}

/**
 * Middleware to check user role
 */
export function requireRole(...roles: Array<'admin' | 'user' | 'viewer'>) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'User not authenticated',
      })
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        error: 'Forbidden',
        message: `Access denied. Required roles: ${roles.join(', ')}`,
      })
    }

    next()
  }
}

/**
 * Authenticate user with username and password
 */
export function authenticateUser(username: string, password: string): { token: string; user: any } | null {
  const user = users.get(username)

  if (!user) {
    return null
  }

  if (!verifyPassword(password, user.password)) {
    return null
  }

  const token = generateToken({
    id: username, // In production, use a proper UUID
    username,
    role: user.role,
  })

  return {
    token,
    user: {
      id: username,
      username,
      role: user.role,
    },
  }
}

/**
 * Create a new user
 */
export function createUser(username: string, password: string, role: 'admin' | 'user' | 'viewer' = 'user'): boolean {
  if (users.has(username)) {
    return false // User already exists
  }

  const hashedPassword = hashPassword(password)
  users.set(username, {
    password: hashedPassword,
    role,
  })

  return true
}

/**
 * Change user password
 */
export function changeUserPassword(username: string, oldPassword: string, newPassword: string): boolean {
  const user = users.get(username)

  if (!user) {
    return false
  }

  if (!verifyPassword(oldPassword, user.password)) {
    return false // Old password is incorrect
  }

  user.password = hashPassword(newPassword)
  return true
}

/**
 * Delete a user
 */
export function deleteUser(username: string): boolean {
  return users.delete(username)
}

/**
 * Get all users (admin only)
 */
export function getAllUsers(): Array<{ username: string; role: string }> {
  return Array.from(users.entries()).map(([username, user]) => ({
    username,
    role: user.role,
  }))
}

/**
 * Logout (invalidate token)
 * Note: In a production system, you'd maintain a token blacklist in a database
 */
export function logout(token: string): void {
  // In production, add token to blacklist database
  // For now, this is a no-op since tokens are stateless
}
