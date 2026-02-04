export interface Project {
  id: string
  name: string
  description?: string
  status: 'active' | 'archived' | 'error'
  owner: string
  createdAt: string
  updatedAt: string
}

export interface Manifest {
  id: string
  projectId: string
  name: string
  kind: string
  apiVersion: string
  namespace: string
  data: Record<string, any>
  valid: boolean
  createdAt: string
  updatedAt: string
}

export interface Configuration {
  id: string
  name: string
  kind: string
  namespace: string
  data: Record<string, string>
  owner?: string
  createdAt: string
  updatedAt: string
}

export interface Module {
  id: string
  name: string
  version: string
  description?: string
  status: 'active' | 'inactive' | 'error'
  dependencies?: string[]
  config?: Record<string, any>
  createdAt: string
  updatedAt: string
}

export interface Activity {
  id: string
  type: 'create' | 'update' | 'delete' | 'validate'
  resourceType: 'manifest' | 'project' | 'configuration' | 'module'
  resourceId: string
  user?: string
  description?: string
  metadata?: Record<string, any>
  createdAt: string
}

export interface ValidationError {
  field: string
  message: string
}

export interface ValidationWarning {
  field: string
  message: string
}

export interface ValidationResult {
  valid: boolean
  errors: ValidationError[]
  warnings: ValidationWarning[]
}

export interface ClusterInfo {
  version: string
  nodes: number
  namespaces: number
  pods: number
  services: number
}
