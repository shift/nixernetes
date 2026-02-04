import axios, { AxiosInstance } from 'axios'
import { Config, Module, Project, ConfigForm, ModuleForm, ProjectForm } from '@types'

export class NixernetesApi {
  private client: AxiosInstance

  constructor(endpoint: string, username: string, password: string) {
    const auth = Buffer.from(`${username}:${password}`).toString('base64')
    
    this.client = axios.create({
      baseURL: endpoint,
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/json',
      },
    })

    // Error handling interceptor
    this.client.interceptors.response.use(
      response => response,
      error => {
        if (error.response?.status === 401) {
          console.error('Authentication failed')
        }
        return Promise.reject(error)
      }
    )
  }

  // Config operations
  async createConfig(data: ConfigForm): Promise<Config> {
    const response = await this.client.post('/configs', data)
    return response.data
  }

  async getConfig(id: string): Promise<Config> {
    const response = await this.client.get(`/configs/${id}`)
    return response.data
  }

  async listConfigs(): Promise<Config[]> {
    const response = await this.client.get('/configs')
    return response.data.configs || []
  }

  async updateConfig(id: string, data: Partial<ConfigForm>): Promise<Config> {
    const response = await this.client.put(`/configs/${id}`, data)
    return response.data
  }

  async deleteConfig(id: string): Promise<void> {
    await this.client.delete(`/configs/${id}`)
  }

  // Module operations
  async createModule(data: ModuleForm): Promise<Module> {
    const response = await this.client.post('/modules', data)
    return response.data
  }

  async getModule(id: string): Promise<Module> {
    const response = await this.client.get(`/modules/${id}`)
    return response.data
  }

  async listModules(): Promise<Module[]> {
    const response = await this.client.get('/modules')
    return response.data.modules || []
  }

  async updateModule(id: string, data: Partial<ModuleForm>): Promise<Module> {
    const response = await this.client.put(`/modules/${id}`, data)
    return response.data
  }

  async deleteModule(id: string): Promise<void> {
    await this.client.delete(`/modules/${id}`)
  }

  // Project operations
  async createProject(data: ProjectForm): Promise<Project> {
    const response = await this.client.post('/projects', data)
    return response.data
  }

  async getProject(id: string): Promise<Project> {
    const response = await this.client.get(`/projects/${id}`)
    return response.data
  }

  async listProjects(): Promise<Project[]> {
    const response = await this.client.get('/projects')
    return response.data.projects || []
  }

  async updateProject(id: string, data: Partial<ProjectForm>): Promise<Project> {
    const response = await this.client.put(`/projects/${id}`, data)
    return response.data
  }

  async deleteProject(id: string): Promise<void> {
    await this.client.delete(`/projects/${id}`)
  }

  // Health check
  async healthCheck(): Promise<boolean> {
    try {
      const response = await this.client.get('/health')
      return response.status === 200
    } catch {
      return false
    }
  }
}

// Singleton instance
let apiInstance: NixernetesApi | null = null

export function initializeApi(endpoint: string, username: string, password: string): NixernetesApi {
  apiInstance = new NixernetesApi(endpoint, username, password)
  return apiInstance
}

export function getApi(): NixernetesApi {
  if (!apiInstance) {
    throw new Error('API not initialized. Call initializeApi first.')
  }
  return apiInstance
}
