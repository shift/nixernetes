import express, { Request, Response, NextFunction } from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import { initializeDatabase } from '@db/database'
import { ProjectRepository, ManifestRepository, ConfigurationRepository, ActivityRepository } from '@models/repositories'
import type { Project, Manifest, Configuration, ValidationResult } from '@models/types'
import { v4 as uuidv4 } from 'uuid'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 8080

// Middleware
app.use(cors())
app.use(express.json())

// Request logging
app.use((req: Request, res: Response, next: NextFunction) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`)
  next()
})

// Error handling middleware
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('Error:', err)
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  })
})

// Initialize database
initializeDatabase()

// Cluster API
app.get('/api/cluster/info', (req: Request, res: Response) => {
  try {
    res.json({
      version: '1.27.0',
      nodes: 3,
      namespaces: 8,
      pods: 45,
      services: 12,
    })
  } catch (error) {
    res.status(500).json({ error: 'Failed to get cluster info' })
  }
})

// Projects API
app.get('/api/projects', (req: Request, res: Response) => {
  try {
    const { status } = req.query
    const projects = ProjectRepository.findAll(status as string | undefined)
    res.json(projects)
  } catch (error) {
    res.status(500).json({ error: 'Failed to load projects' })
  }
})

app.post('/api/projects', (req: Request, res: Response) => {
  try {
    const { name, description, owner } = req.body

    if (!name || !owner) {
      return res.status(400).json({ error: 'Name and owner are required' })
    }

    const project = ProjectRepository.create({
      name,
      description,
      owner,
      status: 'active',
    })

    ActivityRepository.create({
      type: 'create',
      resourceType: 'manifest',
      resourceId: project.id,
      description: `Project '${name}' created`,
    })

    res.status(201).json(project)
  } catch (error) {
    res.status(500).json({ error: 'Failed to create project' })
  }
})

app.get('/api/projects/:id', (req: Request, res: Response) => {
  try {
    const { id } = req.params
    const project = ProjectRepository.findById(id)

    if (!project) {
      return res.status(404).json({ error: 'Project not found' })
    }

    const manifests = ManifestRepository.findByProjectId(id)
    const validCount = manifests.filter((m) => m.valid).length

    res.json({
      ...project,
      manifests: manifests.map((m) => ({
        id: m.id,
        name: m.name,
        kind: m.kind,
        valid: m.valid,
      })),
      resourceCount: manifests.length,
      manifestCount: manifests.length,
      config: {},
    })
  } catch (error) {
    res.status(500).json({ error: 'Failed to load project' })
  }
})

app.put('/api/projects/:id', (req: Request, res: Response) => {
  try {
    const { id } = req.params
    const { name, description, status } = req.body

    const project = ProjectRepository.update(id, {
      name,
      description,
      status: status || undefined,
    })

    if (!project) {
      return res.status(404).json({ error: 'Project not found' })
    }

    ActivityRepository.create({
      type: 'update',
      resourceType: 'manifest',
      resourceId: id,
      description: `Project updated`,
    })

    res.json(project)
  } catch (error) {
    res.status(500).json({ error: 'Failed to update project' })
  }
})

app.delete('/api/projects/:id', (req: Request, res: Response) => {
  try {
    const { id } = req.params
    const deleted = ProjectRepository.delete(id)

    if (!deleted) {
      return res.status(404).json({ error: 'Project not found' })
    }

    ActivityRepository.create({
      type: 'delete',
      resourceType: 'manifest',
      resourceId: id,
      description: `Project deleted`,
    })

    res.json({ message: 'Project deleted' })
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete project' })
  }
})

// Manifests API
app.get('/api/manifests', (req: Request, res: Response) => {
  try {
    const { projectId } = req.query

    if (!projectId) {
      return res.status(400).json({ error: 'projectId is required' })
    }

    const manifests = ManifestRepository.findByProjectId(projectId as string)
    res.json(manifests)
  } catch (error) {
    res.status(500).json({ error: 'Failed to load manifests' })
  }
})

app.post('/api/manifests', (req: Request, res: Response) => {
  try {
    const { projectId, name, kind, apiVersion, namespace, data, valid } = req.body

    if (!projectId || !name || !kind) {
      return res.status(400).json({ error: 'projectId, name, and kind are required' })
    }

    const manifest = ManifestRepository.create({
      projectId,
      name,
      kind,
      apiVersion: apiVersion || 'v1',
      namespace: namespace || 'default',
      data: data || {},
      valid: valid || false,
    })

    ActivityRepository.create({
      type: 'create',
      resourceType: 'manifest',
      resourceId: manifest.id,
      description: `Manifest '${name}' created in project '${projectId}'`,
    })

    res.status(201).json(manifest)
  } catch (error) {
    res.status(500).json({ error: 'Failed to create manifest' })
  }
})

app.get('/api/manifests/:id', (req: Request, res: Response) => {
  try {
    const { id } = req.params
    const manifest = ManifestRepository.findById(id)

    if (!manifest) {
      return res.status(404).json({ error: 'Manifest not found' })
    }

    res.json(manifest)
  } catch (error) {
    res.status(500).json({ error: 'Failed to load manifest' })
  }
})

app.put('/api/manifests/:id', (req: Request, res: Response) => {
  try {
    const { id } = req.params
    const { name, kind, apiVersion, namespace, data, valid } = req.body

    const manifest = ManifestRepository.update(id, {
      name,
      kind,
      apiVersion,
      namespace,
      data,
      valid,
    })

    if (!manifest) {
      return res.status(404).json({ error: 'Manifest not found' })
    }

    ActivityRepository.create({
      type: 'update',
      resourceType: 'manifest',
      resourceId: id,
      description: `Manifest updated`,
    })

    res.json(manifest)
  } catch (error) {
    res.status(500).json({ error: 'Failed to update manifest' })
  }
})

app.delete('/api/manifests/:id', (req: Request, res: Response) => {
  try {
    const { id } = req.params
    const deleted = ManifestRepository.delete(id)

    if (!deleted) {
      return res.status(404).json({ error: 'Manifest not found' })
    }

    ActivityRepository.create({
      type: 'delete',
      resourceType: 'manifest',
      resourceId: id,
      description: `Manifest deleted`,
    })

    res.json({ message: 'Manifest deleted' })
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete manifest' })
  }
})

// Manifest Validation API
app.post('/api/manifests/:id/validate', (req: Request, res: Response) => {
  try {
    const { id } = req.params
    const manifest = ManifestRepository.findById(id)

    if (!manifest) {
      return res.status(404).json({ error: 'Manifest not found' })
    }

    // Basic validation
    const errors: Array<{ field: string; message: string }> = []
    const warnings: Array<{ field: string; message: string }> = []

    if (!manifest.kind) {
      errors.push({ field: 'kind', message: 'kind is required' })
    }

    if (!manifest.metadata?.name) {
      errors.push({ field: 'metadata.name', message: 'metadata.name is required' })
    }

    if (!manifest.apiVersion) {
      warnings.push({ field: 'apiVersion', message: 'apiVersion should be specified' })
    }

    const valid = errors.length === 0

    const result: ValidationResult = {
      valid,
      errors,
      warnings,
    }

    // Update manifest validity
    ManifestRepository.update(id, { valid })

    ActivityRepository.create({
      type: 'validate',
      resourceType: 'manifest',
      resourceId: id,
      description: `Manifest ${valid ? 'passed' : 'failed'} validation`,
      metadata: result,
    })

    res.json(result)
  } catch (error) {
    res.status(500).json({ error: 'Failed to validate manifest' })
  }
})

// Configurations API
app.get('/api/configs', (req: Request, res: Response) => {
  try {
    const { namespace, kind } = req.query

    const configs = ConfigurationRepository.findAll({
      namespace: namespace as string | undefined,
      kind: kind as string | undefined,
    })

    const result = configs.map((c) => ({
      id: c.id,
      name: c.name,
      kind: c.kind,
      namespace: c.namespace,
      created: c.createdAt,
      updated: c.updatedAt,
      size: JSON.stringify(c.data).length,
    }))

    res.json(result)
  } catch (error) {
    res.status(500).json({ error: 'Failed to load configs' })
  }
})

app.post('/api/configs', (req: Request, res: Response) => {
  try {
    const { name, kind, namespace, data } = req.body

    if (!name || !kind) {
      return res.status(400).json({ error: 'name and kind are required' })
    }

    const config = ConfigurationRepository.create({
      name,
      kind,
      namespace: namespace || 'default',
      data: data || {},
    })

    res.status(201).json(config)
  } catch (error) {
    res.status(500).json({ error: 'Failed to create config' })
  }
})

app.delete('/api/configs/:id', (req: Request, res: Response) => {
  try {
    const { id } = req.params
    const deleted = ConfigurationRepository.delete(id)

    if (!deleted) {
      return res.status(404).json({ error: 'Config not found' })
    }

    res.json({ message: 'Config deleted' })
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete config' })
  }
})

// Activity API
app.get('/api/activity', (req: Request, res: Response) => {
  try {
    const { limit = 50 } = req.query
    const activity = ActivityRepository.findRecent(parseInt(limit as string))
    res.json(activity)
  } catch (error) {
    res.status(500).json({ error: 'Failed to load activity' })
  }
})

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok' })
})

// Start server
app.listen(PORT, () => {
  console.log(`Nixernetes backend server running on http://localhost:${PORT}`)
  console.log(`Database: ${process.env.DB_PATH || 'nixernetes.db'}`)
})
