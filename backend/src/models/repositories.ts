import { v4 as uuidv4 } from 'uuid'
import { getDatabase } from '@db/database'
import type { Project, Manifest, Configuration, Activity } from './types'

export class ProjectRepository {
  static create(data: Omit<Project, 'id' | 'createdAt' | 'updatedAt'>): Project {
    const db = getDatabase()
    const id = uuidv4()
    const now = new Date().toISOString()

    const stmt = db.prepare(`
      INSERT INTO projects (id, name, description, status, owner, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `)

    stmt.run(id, data.name, data.description || null, data.status, data.owner, now, now)

    return {
      id,
      ...data,
      createdAt: now,
      updatedAt: now,
    }
  }

  static findById(id: string): Project | null {
    const db = getDatabase()
    const stmt = db.prepare('SELECT * FROM projects WHERE id = ?')
    const row = stmt.get(id) as any

    if (!row) return null

    return {
      id: row.id,
      name: row.name,
      description: row.description,
      status: row.status,
      owner: row.owner,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }
  }

  static findAll(status?: string): Project[] {
    const db = getDatabase()
    let query = 'SELECT * FROM projects'
    const params: any[] = []

    if (status) {
      query += ' WHERE status = ?'
      params.push(status)
    }

    const stmt = db.prepare(query)
    const rows = stmt.all(...params) as any[]

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      description: row.description,
      status: row.status,
      owner: row.owner,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }))
  }

  static update(id: string, data: Partial<Omit<Project, 'id' | 'createdAt' | 'updatedAt'>>): Project | null {
    const db = getDatabase()
    const now = new Date().toISOString()

    const fields = Object.keys(data)
      .map((key) => `${key.replace(/([A-Z])/g, '_$1').toLowerCase()} = ?`)
      .join(', ')

    const values = Object.values(data)
    values.push(now, id)

    const stmt = db.prepare(`UPDATE projects SET ${fields}, updated_at = ? WHERE id = ?`)
    stmt.run(...values)

    return this.findById(id)
  }

  static delete(id: string): boolean {
    const db = getDatabase()
    const stmt = db.prepare('DELETE FROM projects WHERE id = ?')
    const result = stmt.run(id)
    return (result.changes || 0) > 0
  }
}

export class ManifestRepository {
  static create(data: Omit<Manifest, 'id' | 'createdAt' | 'updatedAt'>): Manifest {
    const db = getDatabase()
    const id = uuidv4()
    const now = new Date().toISOString()

    const stmt = db.prepare(`
      INSERT INTO manifests (id, project_id, name, kind, api_version, namespace, data, valid, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `)

    stmt.run(
      id,
      data.projectId,
      data.name,
      data.kind,
      data.apiVersion,
      data.namespace,
      JSON.stringify(data.data),
      data.valid ? 1 : 0,
      now,
      now
    )

    return {
      id,
      ...data,
      createdAt: now,
      updatedAt: now,
    }
  }

  static findById(id: string): Manifest | null {
    const db = getDatabase()
    const stmt = db.prepare('SELECT * FROM manifests WHERE id = ?')
    const row = stmt.get(id) as any

    if (!row) return null

    return {
      id: row.id,
      projectId: row.project_id,
      name: row.name,
      kind: row.kind,
      apiVersion: row.api_version,
      namespace: row.namespace,
      data: JSON.parse(row.data),
      valid: Boolean(row.valid),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }
  }

  static findByProjectId(projectId: string): Manifest[] {
    const db = getDatabase()
    const stmt = db.prepare('SELECT * FROM manifests WHERE project_id = ? ORDER BY created_at DESC')
    const rows = stmt.all(projectId) as any[]

    return rows.map((row) => ({
      id: row.id,
      projectId: row.project_id,
      name: row.name,
      kind: row.kind,
      apiVersion: row.api_version,
      namespace: row.namespace,
      data: JSON.parse(row.data),
      valid: Boolean(row.valid),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }))
  }

  static update(id: string, data: Partial<Omit<Manifest, 'id' | 'createdAt' | 'updatedAt'>>): Manifest | null {
    const db = getDatabase()
    const now = new Date().toISOString()

    const updates: string[] = []
    const values: any[] = []

    if ('name' in data) {
      updates.push('name = ?')
      values.push(data.name)
    }
    if ('kind' in data) {
      updates.push('kind = ?')
      values.push(data.kind)
    }
    if ('apiVersion' in data) {
      updates.push('api_version = ?')
      values.push(data.apiVersion)
    }
    if ('namespace' in data) {
      updates.push('namespace = ?')
      values.push(data.namespace)
    }
    if ('data' in data) {
      updates.push('data = ?')
      values.push(JSON.stringify(data.data))
    }
    if ('valid' in data) {
      updates.push('valid = ?')
      values.push(data.valid ? 1 : 0)
    }

    updates.push('updated_at = ?')
    values.push(now)
    values.push(id)

    const stmt = db.prepare(`UPDATE manifests SET ${updates.join(', ')} WHERE id = ?`)
    stmt.run(...values)

    return this.findById(id)
  }

  static delete(id: string): boolean {
    const db = getDatabase()
    const stmt = db.prepare('DELETE FROM manifests WHERE id = ?')
    const result = stmt.run(id)
    return (result.changes || 0) > 0
  }
}

export class ConfigurationRepository {
  static create(data: Omit<Configuration, 'id' | 'createdAt' | 'updatedAt'>): Configuration {
    const db = getDatabase()
    const id = uuidv4()
    const now = new Date().toISOString()

    const stmt = db.prepare(`
      INSERT INTO configurations (id, name, kind, namespace, data, owner, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `)

    stmt.run(id, data.name, data.kind, data.namespace, JSON.stringify(data.data), data.owner || null, now, now)

    return {
      id,
      ...data,
      createdAt: now,
      updatedAt: now,
    }
  }

  static findAll(filters?: { namespace?: string; kind?: string }): Configuration[] {
    const db = getDatabase()
    let query = 'SELECT * FROM configurations'
    const params: any[] = []

    if (filters) {
      const conditions = []
      if (filters.namespace) {
        conditions.push('namespace = ?')
        params.push(filters.namespace)
      }
      if (filters.kind) {
        conditions.push('kind = ?')
        params.push(filters.kind)
      }
      if (conditions.length > 0) {
        query += ' WHERE ' + conditions.join(' AND ')
      }
    }

    const stmt = db.prepare(query)
    const rows = stmt.all(...params) as any[]

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      kind: row.kind,
      namespace: row.namespace,
      data: JSON.parse(row.data),
      owner: row.owner,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    }))
  }

  static delete(id: string): boolean {
    const db = getDatabase()
    const stmt = db.prepare('DELETE FROM configurations WHERE id = ?')
    const result = stmt.run(id)
    return (result.changes || 0) > 0
  }
}

export class ActivityRepository {
  static create(data: Omit<Activity, 'id' | 'createdAt'>): Activity {
    const db = getDatabase()
    const id = uuidv4()
    const now = new Date().toISOString()

    const stmt = db.prepare(`
      INSERT INTO activity (id, type, resource_type, resource_id, user, description, metadata, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `)

    stmt.run(
      id,
      data.type,
      data.resourceType,
      data.resourceId,
      data.user || null,
      data.description || null,
      data.metadata ? JSON.stringify(data.metadata) : null,
      now
    )

    return {
      id,
      ...data,
      createdAt: now,
    }
  }

  static findRecent(limit: number = 50): Activity[] {
    const db = getDatabase()
    const stmt = db.prepare('SELECT * FROM activity ORDER BY created_at DESC LIMIT ?')
    const rows = stmt.all(limit) as any[]

    return rows.map((row) => ({
      id: row.id,
      type: row.type,
      resourceType: row.resource_type,
      resourceId: row.resource_id,
      user: row.user,
      description: row.description,
      metadata: row.metadata ? JSON.parse(row.metadata) : undefined,
      createdAt: row.created_at,
    }))
  }
}
