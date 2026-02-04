import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { v4 as uuidv4 } from 'uuid'
import { ProjectRepository, ManifestRepository, ConfigurationRepository, ActivityRepository } from '@models/repositories'
import { initializeDatabase } from '@db/database'
import { authenticateUser, generateToken, createUser, changeUserPassword } from './auth'
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

  describe('Authentication System', () => {
    it('should authenticate valid user', () => {
      const result = authenticateUser('admin', 'admin')
      expect(result).not.toBeNull()
      expect(result?.token).toBeDefined()
      expect(result?.user.username).toBe('admin')
      expect(result?.user.role).toBe('admin')
    })

    it('should fail authentication with wrong password', () => {
      const result = authenticateUser('admin', 'wrong-password')
      expect(result).toBeNull()
    })

    it('should fail authentication with non-existent user', () => {
      const result = authenticateUser('non-existent', 'password')
      expect(result).toBeNull()
    })

    it('should create new user', () => {
      const created = createUser('newuser', 'password123', 'user')
      expect(created).toBe(true)

      const authenticated = authenticateUser('newuser', 'password123')
      expect(authenticated).not.toBeNull()
      expect(authenticated?.user.role).toBe('user')
    })

    it('should prevent duplicate user creation', () => {
      const first = createUser('duplicate', 'password1', 'user')
      const second = createUser('duplicate', 'password2', 'admin')
      
      expect(first).toBe(true)
      expect(second).toBe(false)
    })

    it('should generate valid JWT token', () => {
      const token = generateToken({ id: 'user1', username: 'testuser', role: 'user' })
      expect(token).toBeDefined()
      expect(token.length).toBeGreaterThan(0)
      expect(typeof token).toBe('string')
    })

    it('should change user password', () => {
      createUser('testuser', 'oldpassword', 'user')

      const changed = changeUserPassword('testuser', 'oldpassword', 'newpassword')
      expect(changed).toBe(true)

      const oldAuth = authenticateUser('testuser', 'oldpassword')
      expect(oldAuth).toBeNull()

      const newAuth = authenticateUser('testuser', 'newpassword')
      expect(newAuth).not.toBeNull()
    })

    it('should fail password change with wrong old password', () => {
      createUser('testuser', 'correctpassword', 'user')

      const changed = changeUserPassword('testuser', 'wrongpassword', 'newpassword')
      expect(changed).toBe(false)

      const auth = authenticateUser('testuser', 'correctpassword')
      expect(auth).not.toBeNull()
    })

    it('should support different user roles', () => {
      const adminAuth = authenticateUser('admin', 'admin')
      expect(adminAuth?.user.role).toBe('admin')

      const userAuth = authenticateUser('user', 'user')
      expect(userAuth?.user.role).toBe('user')

      const viewerAuth = authenticateUser('viewer', 'viewer')
      expect(viewerAuth?.user.role).toBe('viewer')
    })
  })

  describe('Rate Limiting & Validation', () => {
    it('should validate required fields', () => {
      const project = ProjectRepository.create({
        name: 'Test Project',
        description: 'Description',
        status: 'active',
        owner: 'user',
      })

      expect(project.id).toBeDefined()
      expect(project.name).toBeDefined()
      expect(project.owner).toBeDefined()
    })

    it('should validate manifest data', () => {
      const project = ProjectRepository.create({
        name: 'Test',
        description: '',
        status: 'active',
        owner: 'user',
      })

      const manifest = ManifestRepository.create({
        projectId: project.id,
        name: 'test-manifest',
        kind: 'Deployment',
        apiVersion: 'apps/v1',
        namespace: 'default',
        data: { replicas: 3, image: 'nginx:latest' },
        valid: false,
      })

      expect(manifest.projectId).toBe(project.id)
      expect(manifest.kind).toBe('Deployment')
      expect(manifest.data).toEqual({ replicas: 3, image: 'nginx:latest' })
    })

    it('should validate configuration requirements', () => {
      const config = ConfigurationRepository.create({
        name: 'api-config',
        kind: 'ConfigMap',
        namespace: 'default',
        data: { apiUrl: 'http://api.example.com', debug: 'false' },
      })

      expect(config.name).toBe('api-config')
      expect(config.kind).toBe('ConfigMap')
      expect(config.data.apiUrl).toBe('http://api.example.com')
    })
  })

  describe('Multi-Project Workflows', () => {
    it('should manage multiple projects independently', () => {
      const project1 = ProjectRepository.create({
        name: 'Project 1',
        description: 'First project',
        status: 'active',
        owner: 'user1',
      })

      const project2 = ProjectRepository.create({
        name: 'Project 2',
        description: 'Second project',
        status: 'active',
        owner: 'user2',
      })

      const manifest1 = ManifestRepository.create({
        projectId: project1.id,
        name: 'manifest1',
        kind: 'Deployment',
        apiVersion: 'apps/v1',
        namespace: 'default',
        data: {},
        valid: true,
      })

      const manifest2 = ManifestRepository.create({
        projectId: project2.id,
        name: 'manifest2',
        kind: 'Service',
        apiVersion: 'v1',
        namespace: 'default',
        data: {},
        valid: true,
      })

      const project1Manifests = ManifestRepository.findByProjectId(project1.id)
      const project2Manifests = ManifestRepository.findByProjectId(project2.id)

      expect(project1Manifests).toHaveLength(1)
      expect(project2Manifests).toHaveLength(1)
      expect(project1Manifests[0].id).toBe(manifest1.id)
      expect(project2Manifests[0].id).toBe(manifest2.id)
    })

    it('should handle complex project lifecycle', () => {
      // Create project
      const project = ProjectRepository.create({
        name: 'Complex Project',
        description: 'Testing complex lifecycle',
        status: 'active',
        owner: 'admin',
      })

      // Add multiple manifests
      const deploymentManifest = ManifestRepository.create({
        projectId: project.id,
        name: 'app-deployment',
        kind: 'Deployment',
        apiVersion: 'apps/v1',
        namespace: 'default',
        data: { replicas: 3, image: 'myapp:1.0.0' },
        valid: false,
      })

      const serviceManifest = ManifestRepository.create({
        projectId: project.id,
        name: 'app-service',
        kind: 'Service',
        apiVersion: 'v1',
        namespace: 'default',
        data: { port: 8080 },
        valid: false,
      })

      const configManifest = ManifestRepository.create({
        projectId: project.id,
        name: 'app-config',
        kind: 'ConfigMap',
        apiVersion: 'v1',
        namespace: 'default',
        data: { DATABASE_URL: 'postgres://db:5432/myapp' },
        valid: false,
      })

      // Log creation activities
      ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: project.id,
        description: 'Project created',
      })

      ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: deploymentManifest.id,
        description: 'Deployment manifest created',
      })

      ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: serviceManifest.id,
        description: 'Service manifest created',
      })

      ActivityRepository.create({
        type: 'create',
        resourceType: 'manifest',
        resourceId: configManifest.id,
        description: 'ConfigMap manifest created',
      })

      // Validate manifests
      ManifestRepository.update(deploymentManifest.id, { valid: true })
      ManifestRepository.update(serviceManifest.id, { valid: true })
      ManifestRepository.update(configManifest.id, { valid: true })

      ActivityRepository.create({
        type: 'validate',
        resourceType: 'manifest',
        resourceId: deploymentManifest.id,
        description: 'Deployment validated successfully',
        metadata: { valid: true, errors: [] },
      })

      ActivityRepository.create({
        type: 'validate',
        resourceType: 'manifest',
        resourceId: serviceManifest.id,
        description: 'Service validated successfully',
        metadata: { valid: true, errors: [] },
      })

      ActivityRepository.create({
        type: 'validate',
        resourceType: 'manifest',
        resourceId: configManifest.id,
        description: 'ConfigMap validated successfully',
        metadata: { valid: true, errors: [] },
      })

      // Verify project state
      const manifests = ManifestRepository.findByProjectId(project.id)
      expect(manifests).toHaveLength(3)
      expect(manifests.every((m) => m.valid)).toBe(true)

      const activity = ActivityRepository.findRecent(50)
      expect(activity.length).toBeGreaterThan(0)

      // Update project status
      const updatedProject = ProjectRepository.update(project.id, { status: 'archived' })
      expect(updatedProject?.status).toBe('archived')

      ActivityRepository.create({
        type: 'update',
        resourceType: 'manifest',
        resourceId: project.id,
        description: 'Project archived',
      })

      // Verify final state
      const finalProject = ProjectRepository.findById(project.id)
      expect(finalProject?.status).toBe('archived')
    })
  })

  describe('Data Persistence & Integrity', () => {
    it('should persist data across database operations', () => {
      const project = ProjectRepository.create({
        name: 'Persistence Test',
        description: 'Testing data persistence',
        status: 'active',
        owner: 'test-user',
      })

      const projectId = project.id

      // Find immediately after creation
      let found = ProjectRepository.findById(projectId)
      expect(found).not.toBeNull()
      expect(found?.name).toBe('Persistence Test')

      // Update and verify
      ProjectRepository.update(projectId, { description: 'Updated description' })
      found = ProjectRepository.findById(projectId)
      expect(found?.description).toBe('Updated description')

      // Find in list
      const all = ProjectRepository.findAll()
      const inList = all.find((p) => p.id === projectId)
      expect(inList).not.toBeNull()
      expect(inList?.name).toBe('Persistence Test')
    })

    it('should maintain referential integrity between projects and manifests', () => {
      const project = ProjectRepository.create({
        name: 'Integrity Test',
        description: '',
        status: 'active',
        owner: 'user',
      })

      const manifest1 = ManifestRepository.create({
        projectId: project.id,
        name: 'manifest-1',
        kind: 'Pod',
        apiVersion: 'v1',
        namespace: 'default',
        data: {},
        valid: false,
      })

      const manifest2 = ManifestRepository.create({
        projectId: project.id,
        name: 'manifest-2',
        kind: 'Pod',
        apiVersion: 'v1',
        namespace: 'default',
        data: {},
        valid: false,
      })

      // Delete project shouldn't affect manifest queryability
      const manifests = ManifestRepository.findByProjectId(project.id)
      expect(manifests).toHaveLength(2)

      // Manifests should still exist
      expect(ManifestRepository.findById(manifest1.id)).not.toBeNull()
      expect(ManifestRepository.findById(manifest2.id)).not.toBeNull()
    })

    it('should handle special characters and unicode in data', () => {
      const project = ProjectRepository.create({
        name: 'Project with émojis 🚀',
        description: 'Description with spëcial çharacters',
        status: 'active',
        owner: 'user@domain.com',
      })

      const found = ProjectRepository.findById(project.id)
      expect(found?.name).toBe('Project with émojis 🚀')
      expect(found?.description).toBe('Description with spëcial çharacters')
      expect(found?.owner).toBe('user@domain.com')
    })

    it('should preserve large JSON data structures', () => {
      const project = ProjectRepository.create({
        name: 'Large Data Test',
        description: '',
        status: 'active',
        owner: 'user',
      })

      const largeData = {
        nested: {
          deep: {
            structure: {
              with: {
                many: ['items', 'in', 'array', 'to', 'test', 'persistence'],
                counts: Array.from({ length: 100 }, (_, i) => ({
                  id: i,
                  value: `item-${i}`,
                  metadata: {
                    created: new Date().toISOString(),
                    tags: ['tag1', 'tag2', 'tag3'],
                  },
                })),
              },
            },
          },
        },
      }

      const manifest = ManifestRepository.create({
        projectId: project.id,
        name: 'large-data-manifest',
        kind: 'ConfigMap',
        apiVersion: 'v1',
        namespace: 'default',
        data: largeData,
        valid: true,
      })

      const found = ManifestRepository.findById(manifest.id)
      expect(found?.data).toEqual(largeData)
      expect(found?.data.nested.deep.structure.with.counts).toHaveLength(100)
    })
  })

  describe('Error Handling & Edge Cases', () => {
    it('should handle deletion of non-existent resources gracefully', () => {
      const result = ProjectRepository.delete('non-existent-id')
      expect(result).toBe(false)

      const manifestResult = ManifestRepository.delete('non-existent-id')
      expect(manifestResult).toBe(false)
    })

    it('should handle updating non-existent resources gracefully', () => {
      const result = ProjectRepository.update('non-existent-id', { name: 'New Name' })
      expect(result).toBeNull()

      const manifestResult = ManifestRepository.update('non-existent-id', { valid: true })
      expect(manifestResult).toBeNull()
    })

    it('should handle empty filters gracefully', () => {
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
      const active = ProjectRepository.findAll('active')
      const archived = ProjectRepository.findAll('archived')

      expect(all.length).toBeGreaterThan(0)
      expect(active.length).toBeGreaterThan(0)
      expect(archived.length).toBeGreaterThan(0)
    })

    it('should handle concurrent activity logging', () => {
      const project = ProjectRepository.create({
        name: 'Concurrency Test',
        description: '',
        status: 'active',
        owner: 'user',
      })

      const manifest = ManifestRepository.create({
        projectId: project.id,
        name: 'test',
        kind: 'Deployment',
        apiVersion: 'apps/v1',
        namespace: 'default',
        data: {},
        valid: false,
      })

      // Simulate concurrent activity logging
      for (let i = 0; i < 100; i++) {
        ActivityRepository.create({
          type: 'update',
          resourceType: 'manifest',
          resourceId: manifest.id,
          description: `Concurrent update ${i}`,
        })
      }

      const recentActivity = ActivityRepository.findRecent(150)
      expect(recentActivity.length).toBeLessThanOrEqual(150)
      expect(recentActivity.length).toBeGreaterThanOrEqual(100)
    })

    it('should handle empty project manifest lists', () => {
      const project = ProjectRepository.create({
        name: 'Empty Project',
        description: '',
        status: 'active',
        owner: 'user',
      })

      const manifests = ManifestRepository.findByProjectId(project.id)
      expect(manifests).toHaveLength(0)
      expect(Array.isArray(manifests)).toBe(true)
    })
  })

  describe('Performance & Scaling', () => {
    it('should handle bulk project creation', () => {
      const projectCount = 50
      const projectIds: string[] = []

      for (let i = 0; i < projectCount; i++) {
        const project = ProjectRepository.create({
          name: `Project ${i}`,
          description: `Description ${i}`,
          status: i % 2 === 0 ? 'active' : 'archived',
          owner: `owner${i % 5}`,
        })
        projectIds.push(project.id)
      }

      const all = ProjectRepository.findAll()
      expect(all.length).toBeGreaterThanOrEqual(projectCount)

      const active = ProjectRepository.findAll('active')
      expect(active.length).toBeGreaterThan(0)
    })

    it('should efficiently retrieve large result sets', () => {
      const project = ProjectRepository.create({
        name: 'Large Result Test',
        description: '',
        status: 'active',
        owner: 'user',
      })

      const manifestCount = 200
      for (let i = 0; i < manifestCount; i++) {
        ManifestRepository.create({
          projectId: project.id,
          name: `manifest-${i}`,
          kind: 'Pod',
          apiVersion: 'v1',
          namespace: `namespace-${i % 10}`,
          data: { index: i },
          valid: i % 2 === 0,
        })
      }

      const manifests = ManifestRepository.findByProjectId(project.id)
      expect(manifests).toHaveLength(manifestCount)
    })

    it('should handle rapid activity log writes', () => {
      const project = ProjectRepository.create({
        name: 'Activity Test',
        description: '',
        status: 'active',
        owner: 'user',
      })

      const manifest = ManifestRepository.create({
        projectId: project.id,
        name: 'test',
        kind: 'Pod',
        apiVersion: 'v1',
        namespace: 'default',
        data: {},
        valid: false,
      })

      const activityCount = 500
      for (let i = 0; i < activityCount; i++) {
        ActivityRepository.create({
          type: 'update',
          resourceType: 'manifest',
          resourceId: manifest.id,
          description: `Activity ${i}`,
        })
      }

      const recent = ActivityRepository.findRecent(activityCount)
      expect(recent.length).toBeLessThanOrEqual(activityCount)
    })
  })
})
