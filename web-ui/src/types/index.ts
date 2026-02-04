// Configuration model
export interface Config {
  id: string
  name: string
  configuration: string
  environment: 'development' | 'staging' | 'production'
  created_at: string
  updated_at: string
}

// Module model
export interface Module {
  id: string
  name: string
  image: string
  replicas: number
  namespace: string
  created_at: string
}

// Project model
export interface Project {
  id: string
  name: string
  description: string
  status: string
  created_at: string
  updated_at: string
}

// API Response types
export interface ApiResponse<T> {
  data: T
  error?: string
  message?: string
}

export interface ListResponse<T> {
  items: T[]
  total: number
}

// Form types
export interface ConfigForm {
  name: string
  configuration: string
  environment: 'development' | 'staging' | 'production'
}

export interface ModuleForm {
  name: string
  image: string
  replicas: number
  namespace: string
}

export interface ProjectForm {
  name: string
  description: string
}

// Provider configuration
export interface ProviderConfig {
  endpoint: string
  username: string
  password: string
}

// UI State types
export type ViewMode = 'list' | 'detail' | 'create' | 'edit'

export interface UIState {
  configView: ViewMode
  moduleView: ViewMode
  projectView: ViewMode
  selectedConfigId?: string
  selectedModuleId?: string
  selectedProjectId?: string
  loading: boolean
  error?: string
}

// Notification types
export interface Notification {
  id: string
  type: 'success' | 'error' | 'info' | 'warning'
  message: string
  duration?: number
}
