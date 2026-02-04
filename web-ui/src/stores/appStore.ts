import { create } from 'zustand'
import { Config, Module, Project, Notification } from '@types'

interface AppStore {
  // Configs
  configs: Config[]
  selectedConfigId: string | null
  setConfigs: (configs: Config[]) => void
  selectConfig: (id: string | null) => void
  addConfig: (config: Config) => void
  updateConfig: (config: Config) => void
  removeConfig: (id: string) => void

  // Modules
  modules: Module[]
  selectedModuleId: string | null
  setModules: (modules: Module[]) => void
  selectModule: (id: string | null) => void
  addModule: (module: Module) => void
  updateModule: (module: Module) => void
  removeModule: (id: string) => void

  // Projects
  projects: Project[]
  selectedProjectId: string | null
  setProjects: (projects: Project[]) => void
  selectProject: (id: string | null) => void
  addProject: (project: Project) => void
  updateProject: (project: Project) => void
  removeProject: (id: string) => void

  // Notifications
  notifications: Notification[]
  addNotification: (notification: Omit<Notification, 'id'>) => void
  removeNotification: (id: string) => void

  // UI State
  loading: boolean
  setLoading: (loading: boolean) => void
  error: string | null
  setError: (error: string | null) => void
}

export const useAppStore = create<AppStore>((set) => ({
  // Configs
  configs: [],
  selectedConfigId: null,
  setConfigs: (configs) => set({ configs }),
  selectConfig: (id) => set({ selectedConfigId: id }),
  addConfig: (config) =>
    set((state) => ({ configs: [...state.configs, config] })),
  updateConfig: (config) =>
    set((state) => ({
      configs: state.configs.map((c) => (c.id === config.id ? config : c)),
    })),
  removeConfig: (id) =>
    set((state) => ({
      configs: state.configs.filter((c) => c.id !== id),
    })),

  // Modules
  modules: [],
  selectedModuleId: null,
  setModules: (modules) => set({ modules }),
  selectModule: (id) => set({ selectedModuleId: id }),
  addModule: (module) =>
    set((state) => ({ modules: [...state.modules, module] })),
  updateModule: (module) =>
    set((state) => ({
      modules: state.modules.map((m) => (m.id === module.id ? module : m)),
    })),
  removeModule: (id) =>
    set((state) => ({
      modules: state.modules.filter((m) => m.id !== id),
    })),

  // Projects
  projects: [],
  selectedProjectId: null,
  setProjects: (projects) => set({ projects }),
  selectProject: (id) => set({ selectedProjectId: id }),
  addProject: (project) =>
    set((state) => ({ projects: [...state.projects, project] })),
  updateProject: (project) =>
    set((state) => ({
      projects: state.projects.map((p) => (p.id === project.id ? project : p)),
    })),
  removeProject: (id) =>
    set((state) => ({
      projects: state.projects.filter((p) => p.id !== id),
    })),

  // Notifications
  notifications: [],
  addNotification: (notification) =>
    set((state) => ({
      notifications: [
        ...state.notifications,
        {
          ...notification,
          id: Math.random().toString(36).substr(2, 9),
        },
      ],
    })),
  removeNotification: (id) =>
    set((state) => ({
      notifications: state.notifications.filter((n) => n.id !== id),
    })),

  // UI State
  loading: false,
  setLoading: (loading) => set({ loading }),
  error: null,
  setError: (error) => set({ error }),
}))
