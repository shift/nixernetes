import React, { useEffect, useState } from 'react'
import { Routes, Route, useNavigate } from 'react-router-dom'
import { useAppStore } from '@stores/appStore'
import { getApi } from '@services/api'

interface Module {
  id: string
  name: string
  version: string
  enabled: boolean
  description: string
  dependencies: string[]
  created: string
  updated: string
}

interface ModuleDetail extends Module {
  config: Record<string, unknown>
  resources: string[]
  status: 'active' | 'inactive' | 'error'
  lastError?: string
}

export default function ModulesPage() {
  return (
    <Routes>
      <Route path="/" element={<ModulesList />} />
      <Route path="/:id" element={<ModuleDetail />} />
    </Routes>
  )
}

function ModulesList() {
  const [modules, setModules] = useState<Module[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const navigate = useNavigate()
  const setError = useAppStore((state) => state.setError)

  useEffect(() => {
    loadModules()
  }, [])

  async function loadModules() {
    try {
      setLoading(true)
      const api = getApi()
      const res = await api.get('/api/modules')
      setModules(res.data || [])
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to load modules')
    } finally {
      setLoading(false)
    }
  }

  async function toggleModule(id: string, enabled: boolean) {
    try {
      const api = getApi()
      await api.patch(`/api/modules/${id}`, { enabled: !enabled })
      loadModules()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to update module')
    }
  }

  const filteredModules = modules.filter(
    (m) =>
      m.name.toLowerCase().includes(search.toLowerCase()) ||
      m.description.toLowerCase().includes(search.toLowerCase())
  )

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-nix-500"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold text-gray-900">Modules</h1>
        <button
          onClick={() => navigate('/modules/create')}
          className="px-4 py-2 bg-nix-500 text-white rounded-lg hover:bg-nix-600 transition"
        >
          Install Module
        </button>
      </div>

      {/* Search */}
      <div className="bg-white rounded-lg shadow p-4">
        <input
          type="text"
          placeholder="Search modules..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-nix-500 focus:border-nix-500"
        />
      </div>

      {/* Modules List */}
      <div className="grid grid-cols-1 gap-4">
        {filteredModules.length === 0 ? (
          <div className="bg-white rounded-lg shadow p-6 text-center text-gray-500">
            No modules found
          </div>
        ) : (
          filteredModules.map((module) => (
            <div
              key={module.id}
              className="bg-white rounded-lg shadow p-6 hover:shadow-lg transition"
            >
              <div className="flex justify-between items-start">
                <div className="flex-1">
                  <button
                    onClick={() => navigate(`/modules/${module.id}`)}
                    className="text-lg font-semibold text-nix-500 hover:text-nix-600"
                  >
                    {module.name}
                  </button>
                  <p className="text-gray-600 mt-1">{module.description}</p>

                  <div className="flex items-center space-x-4 mt-3 text-sm text-gray-600">
                    <span>v{module.version}</span>
                    <span>Updated {new Date(module.updated).toLocaleDateString()}</span>
                    {module.dependencies.length > 0 && (
                      <span>{module.dependencies.length} dependencies</span>
                    )}
                  </div>
                </div>

                <div className="flex items-center space-x-3">
                  <button
                    onClick={() => toggleModule(module.id, module.enabled)}
                    className={`px-4 py-2 rounded-lg transition ${
                      module.enabled
                        ? 'bg-green-100 text-green-800 hover:bg-green-200'
                        : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                    }`}
                  >
                    {module.enabled ? 'Enabled' : 'Disabled'}
                  </button>
                </div>
              </div>

              {module.dependencies.length > 0 && (
                <div className="mt-4 pt-4 border-t border-gray-200">
                  <p className="text-sm text-gray-700 mb-2">Dependencies:</p>
                  <div className="flex flex-wrap gap-2">
                    {module.dependencies.map((dep) => (
                      <span
                        key={dep}
                        className="px-2 py-1 bg-gray-100 text-gray-700 rounded text-xs"
                      >
                        {dep}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  )
}

function ModuleDetail() {
  const [module, setModule] = useState<ModuleDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [isEditing, setIsEditing] = useState(false)
  const [config, setConfig] = useState<Record<string, unknown>>({})
  const navigate = useNavigate()
  const setError = useAppStore((state) => state.setError)

  useEffect(() => {
    loadModule()
  }, [])

  async function loadModule() {
    try {
      setLoading(true)
      const api = getApi()
      const res = await api.get('/api/modules/example-module')
      setModule(res.data)
      setConfig(res.data?.config || {})
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to load module')
    } finally {
      setLoading(false)
    }
  }

  async function saveConfig() {
    try {
      const api = getApi()
      await api.patch(`/api/modules/${module?.id}`, { config })
      setIsEditing(false)
      loadModule()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to save config')
    }
  }

  if (loading || !module) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-nix-500"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{module.name}</h1>
          <p className="text-gray-600 mt-1">{module.description}</p>
          <div className="flex items-center space-x-4 mt-3 text-sm text-gray-600">
            <span>v{module.version}</span>
            <span
              className={`px-2 py-1 rounded ${
                module.status === 'active'
                  ? 'bg-green-100 text-green-800'
                  : module.status === 'error'
                  ? 'bg-red-100 text-red-800'
                  : 'bg-gray-100 text-gray-800'
              }`}
            >
              {module.status}
            </span>
          </div>
        </div>
        <button
          onClick={() => navigate('/modules')}
          className="px-4 py-2 bg-gray-200 text-gray-900 rounded-lg hover:bg-gray-300 transition"
        >
          Back
        </button>
      </div>

      {module.lastError && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-800">Error: {module.lastError}</p>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold text-gray-900">Configuration</h2>
              <button
                onClick={() => (isEditing ? saveConfig() : setIsEditing(true))}
                className="px-3 py-1 text-sm bg-nix-500 text-white rounded hover:bg-nix-600 transition"
              >
                {isEditing ? 'Save' : 'Edit'}
              </button>
            </div>

            {isEditing ? (
              <div className="space-y-4">
                <textarea
                  value={JSON.stringify(config, null, 2)}
                  onChange={(e) => {
                    try {
                      setConfig(JSON.parse(e.target.value))
                    } catch {
                      // Invalid JSON
                    }
                  }}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg font-mono text-sm focus:outline-none focus:ring-nix-500 focus:border-nix-500"
                  rows={10}
                />
              </div>
            ) : (
              <pre className="bg-gray-50 p-4 rounded-lg overflow-x-auto text-sm">
                {JSON.stringify(module.config, null, 2)}
              </pre>
            )}
          </div>
        </div>

        <div className="space-y-4">
          {module.dependencies.length > 0 && (
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-sm font-semibold text-gray-900 mb-3">Dependencies</h3>
              <div className="space-y-2">
                {module.dependencies.map((dep) => (
                  <p key={dep} className="text-sm text-gray-700">
                    • {dep}
                  </p>
                ))}
              </div>
            </div>
          )}

          {module.resources.length > 0 && (
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-sm font-semibold text-gray-900 mb-3">Resources</h3>
              <div className="space-y-2">
                {module.resources.map((resource) => (
                  <p key={resource} className="text-sm text-gray-700 truncate" title={resource}>
                    • {resource}
                  </p>
                ))}
              </div>
            </div>
          )}

          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-3">Information</h3>
            <div className="space-y-2 text-sm">
              <div>
                <p className="text-gray-600">Created</p>
                <p className="font-medium text-gray-900">
                  {new Date(module.created).toLocaleDateString()}
                </p>
              </div>
              <div>
                <p className="text-gray-600">Updated</p>
                <p className="font-medium text-gray-900">
                  {new Date(module.updated).toLocaleDateString()}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
