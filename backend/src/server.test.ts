import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { v4 as uuidv4 } from 'uuid'
import { ProjectRepository, ManifestRepository, ConfigurationRepository, ActivityRepository } from '@models/repositories'
import { initializeDatabase } from '@db/database'
import fs from 'fs'
import path from 'path'

describe('Backend API Integration Tests', () => {
  const testDbPath = path.join(__dirname, '..', 'test-db.sqlite')

  beforeEach(() => {
    // Use test database
    process.env.DB_PATH = testDbPath
    initializeDatabase()
  })

  afterEach(() => {
    // Clean up test database
    if (fs.existsSync(testDbPath)) {
      fs.unlinkSync(testDbPath)
    }
  })

  describe('Projects Repository', () => {
    it('should create a project', () => {
      const project = ProjectRepository.create({
        name: 'Test Project',
        description: 'A test project',
        status: 'active',
        owner: 'test-user',
      })

      expect(project.id).toBeDefined()
      expect(project.name).toBe('Test Project')
      expect(project.status).toBe('active')
      expect(project.owner).toBe('test-user')
    })

    it('should find project by id', () => {
      const created = ProjectRepository.create({
        name: 'Find Test',
        description: 'Test finding',
        status: 'active',
        owner: 'test-user',
      })

      const found = ProjectRepository.findById(created.id)

      expect(found).not.toBeNull()
      expect(found?.id).toBe(created.id)
      expect(found?.name).toBe('Find Test')
    })

    it('should return null for non-existent project', () => {
      const found = ProjectRepository.findById('non-existent-id')
      expect(found).toBeNull()
    })

    it('should find all projects', () => {
      ProjectRepository.create({
        name: 'Project 1',
        description: '',
        status: 'active',
        owner: 'user1',
      })

      ProjectRepository.create({
        name: 'Project 2',
        description: '',
        status: 'archived',
        owner: 'user2',
      })

      const all = ProjectRepository.findAll()
      expect(all).toHaveLength(2)
    })

    it('should filter projects by status', () => {
      ProjectRepository.create({
        name: 'Active Project',
        description: '',
        status: 'active',
        owner: 'user1',
      })

      ProjectRepository.create({
        name: 'Archived Project',
        description: '',
        status: 'archived',
        owner: 'user2',
      })

      const active = ProjectRepository.findAll('active')
      expect(active).toHaveLength(1)
      expect(active[0].status).toBe('active')
    })

    it('should update a project', () => {
      const created = ProjectRepository.create({
        name: 'Original Name',
        description: 'Original description',
        status: 'active',
        owner: 'user1',
      })

      const updated = ProjectRepository.update(created.id, {
        name: 'Updated Name',
        status: 'archived',
      })

      expect(updated?.name).toBe('Updated Name')
      expect(updated?.status).toBe('archived')
      expect(updated?.description).toBe('Original description')
    })

    it('should delete a project', () => {
      const created = ProjectRepository.create({
        name: 'To Delete',
        description: '',
        status: 'active',
        owner: 'user1',
      })

      const deleted = ProjectRepository.delete(created.id)
      expect(deleted).toBe(true)

      const found = ProjectRepository.findById(created.id)
      expect(found).toBeNull()
    })
  })

  describe('Manifests Repository', () => {
    let projectId: string

    beforeEach(() => {
      const project = ProjectRepository.create({
        name: 'Test Project',
        description: '',
        status: 'active',
        owner: 'test-user',
      })
      projectId = project.id
    })

    it('should create a manifest', () => {
      const manifest = ManifestRepository.create({
        projectId,
        name: 'test-config',
        kind: 'ConfigMap',
        apiVersion: 'v1',
        namespace: 'default',
        data: { key: 'value' },
        valid: true,
      })

      expect(manifest.id).toBeDefined()
      expect(manifest.name).toBe('test-config')
      expect(manifest.kind).toBe('ConfigMap')
      expect(manifest.valid).toBe(true)
    })

    it('should find manifest by id', () => {
      const created = ManifestRepository.create({
        projectId,
        name: 'test-config',
        kind: 'ConfigMap',
        apiVersion: 'v1',
        namespace: 'default',
        data: { key: 'value' },
        valid: false,
      })

      const found = ManifestRepository.findById(created.id)

      expect(found).not.toBeNull()
      expect(found?.id).toBe(created.id)
      expect(found?.data).toEqual({ key: 'value' })
    })

    it('should find manifests by project id', () => {
      ManifestRepository.create({
        projectId,
        name: 'manifest-1',
        kind: 'Deployment',
        apiVersion: 'apps/v1',
        namespace: 'default',
        data: {},
        valid: true,
      })

      ManifestRepository.create({
        projectId,
        name: 'manifest-2',
        kind: 'Service',
        apiVersion: 'v1',
        namespace: 'default',
        data: {},
        valid: false,
      })

      const manifests = ManifestRepository.findByProjectId(projectId)
      expect(manifests).toHaveLength(2)
    })

    it('should update a manifest', () => {
      const created = ManifestRepository.create({
        projectId,
        name: 'original-name',
        kind: 'ConfigMap',
        apiVersion: 'v1',
        namespace: 'default',
        data: { key: 'value' },
        valid: false,
      })

      const updated = ManifestRepository.update(created.id, {
        name: 'updated-name',
        valid: true,
        data: { key: 'new-value' },
      })

      expect(updated?.name).toBe('updated-name')
      expect(updated?.valid).toBe(true)
      expect(updated?.data).toEqual({ key: 'new-value' })
    })

    it('should delete a manifest', () => {
      const created = ManifestRepository.create({
        projectId,
        name: 'to-delete',
        kind: 'ConfigMap',
        apiVersion: 'v1',
        namespace: 'default',
        data: {},
        valid: false,
      })

      const deleted = ManifestRepository.delete(created.id)
      expect(deleted).toBe(true)

      const found = ManifestRepository.findById(created.id)
      expect(found).toBeNull()
    })
  })

  describe('Configurations Repository', () => {
    it('should create a configuration', () => {
      const config = ConfigurationRepository.create({
        name: 'test-config',
        kind: 'Secret',
        namespace: 'default',
        data: { password: 'secret' },
        owner: 'admin',
      })

      expect(config.id).toBeDefined()
      expect(config.name).toBe('test-config')
      expect(config.kind).toBe('Secret')
    })

    it('should find all configurations', () => {
      ConfigurationRepository.create({
        name: 'config-1',
        kind: 'ConfigMap',
        namespace: 'default',
        data: {},
      })

      ConfigurationRepository.create({
        name: 'config-2',
        kind: 'Secret',
        namespace: 'kube-system',
        data: {},
      })

      const all = ConfigurationRepository.findAll()
      expect(all).toHaveLength(2)
    })

    it('should filter configurations by namespace', () => {
      ConfigurationRepository.create({
        name: 'default-config',
        kind: 'ConfigMap',
        namespace: 'default',
        data: {},
      })

      ConfigurationRepository.create({
        name: 'system-config',
        kind: 'ConfigMap',
        namespace: 'kube-system',
        data: {},
      })

      const defaultConfigs = ConfigurationRepository.findAll({ namespace: 'default' })
      expect(defaultConfigs).toHaveLength(1)
      expect(defaultConfigs[0].namespace).toBe('default')
    })

    it('should delete a configuration', () => {
      const created = ConfigurationRepository.create({
        name: 'to-delete',
        kind: 'ConfigMap',
        namespace: 'default',
        data: {},
      })

      const deleted = ConfigurationRepository.delete(created.id)
      expect(deleted).toBe(true)
    })
  })

  describe('Activity Repository', () => {
    let manifestId: string

    beforeEach(() => {
      const project = ProjectRepository.create({
        name: 'Test',
        description: '',
        status: 'active',
        owner: 'user',
      })

      const manifest = ManifestRepository.create({
        projectId: project.id,
        name: 'test',
        kind: 'ConfigMap',
        apiVersion: 'v1',
        namespace: 'default',
        data: {},
        valid: false,
      })

      manifestId = manifest.id
    })

    it('should create activity record', () => {
      const activity = ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: manifestId,
        user: 'admin',
        description: 'Manifest created',
      })

      expect(activity.id).toBeDefined()
      expect(activity.type).toBe('create')
      expect(activity.resourceId).toBe(manifestId)
    })

    it('should find recent activity', () => {
      ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: manifestId,
        description: 'First activity',
      })

      ActivityRepository.create({
        type: 'update',
        resourceType: 'manifest',
        resourceId: manifestId,
        description: 'Second activity',
      })

      const recent = ActivityRepository.findRecent(10)
      expect(recent).toHaveLength(2)
      expect(recent[0].type).toBe('update')
      expect(recent[1].type).toBe('create')
    })

    it('should limit recent activity', () => {
      for (let i = 0; i < 60; i++) {
        ActivityRepository.create({
          type: 'update',
          resourceType: 'manifest',
          resourceId: manifestId,
          description: `Activity ${i}`,
        })
      }

      const recent = ActivityRepository.findRecent(20)
      expect(recent).toHaveLength(20)
    })
  })

  describe('Integration Workflows', () => {
    it('should create project with manifests', () => {
      const project = ProjectRepository.create({
        name: 'Production',
        description: 'Production cluster',
        status: 'active',
        owner: 'ops-team',
      })

      ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: project.id,
        description: 'Project created',
      })

      const manifest1 = ManifestRepository.create({
        projectId: project.id,
        name: 'nginx-deployment',
        kind: 'Deployment',
        apiVersion: 'apps/v1',
        namespace: 'default',
        data: { replicas: 3 },
        valid: true,
      })

      const manifest2 = ManifestRepository.create({
        projectId: project.id,
        name: 'nginx-service',
        kind: 'Service',
        apiVersion: 'v1',
        namespace: 'default',
        data: { port: 80 },
        valid: true,
      })

      ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: manifest1.id,
        description: 'Deployment manifest created',
      })

      ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: manifest2.id,
        description: 'Service manifest created',
      })

      const manifests = ManifestRepository.findByProjectId(project.id)
      expect(manifests).toHaveLength(2)

      const activity = ActivityRepository.findRecent(10)
      expect(activity).toHaveLength(3)
    })

    it('should track manifest lifecycle', () => {
      const project = ProjectRepository.create({
        name: 'Staging',
        description: '',
        status: 'active',
        owner: 'dev-team',
      })

      const manifest = ManifestRepository.create({
        projectId: project.id,
        name: 'app-config',
        kind: 'ConfigMap',
        apiVersion: 'v1',
        namespace: 'default',
        data: { env: 'staging' },
        valid: false,
      })

      ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: manifest.id,
        description: 'ConfigMap created',
      })

      ManifestRepository.update(manifest.id, {
        data: { env: 'staging', debug: 'true' },
        valid: true,
      })

      ActivityRepository.create({
        type: 'update',
        resourceType: 'manifest',
        resourceId: manifest.id,
        description: 'ConfigMap updated',
      })

      ActivityRepository.create({
        type: 'validate',
        resourceType: 'manifest',
        resourceId: manifest.id,
        description: 'Validation passed',
        metadata: { valid: true, errors: [] },
      })

      const activity = ActivityRepository.findRecent(10)
      expect(activity).toHaveLength(3)
      expect(activity[0].type).toBe('validate')
      expect(activity[1].type).toBe('update')
      expect(activity[2].type).toBe('create')
    })
  })
})
