import React, { useEffect, useState } from 'react'
import { Routes, Route, useNavigate } from 'react-router-dom'
import { useAppStore } from '@stores/appStore'
import { getApi } from '@services/api'

interface Config {
  id: string
  name: string
  kind: string
  namespace: string
  created: string
  updated: string
  size: number
}

interface ConfigDetail {
  id: string
  name: string
  kind: string
  namespace: string
  data: Record<string, string>
  created: string
  updated: string
  owner?: string
}

export default function ConfigsPage() {
  return (
    <Routes>
      <Route path="/" element={<ConfigsList />} />
      <Route path="/:id" element={<ConfigDetail />} />
      <Route path="/create/:kind" element={<ConfigForm />} />
    </Routes>
  )
}

function ConfigsList() {
  const [configs, setConfigs] = useState<Config[]>([])
  const [loading, setLoading] = useState(true)
  const [filterNamespace, setFilterNamespace] = useState<string>('all')
  const [filterKind, setFilterKind] = useState<string>('all')
  const navigate = useNavigate()
  const setError = useAppStore((state) => state.setError)

  const configKinds = ['ConfigMap', 'Secret', 'Ingress', 'Network Policy']

  useEffect(() => {
    loadConfigs()
  }, [filterNamespace, filterKind])

  async function loadConfigs() {
    try {
      setLoading(true)
      const api = getApi()
      let url = '/api/configs'
      const params = new URLSearchParams()

      if (filterNamespace !== 'all') {
        params.append('namespace', filterNamespace)
      }
      if (filterKind !== 'all') {
        params.append('kind', filterKind)
      }

      if (params.toString()) {
        url += '?' + params.toString()
      }

      const res = await api.get(url)
      setConfigs(res.data || [])
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to load configs')
    } finally {
      setLoading(false)
    }
  }

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
        <h1 className="text-3xl font-bold text-gray-900">Configurations</h1>
        <div className="space-x-2">
          {configKinds.map((kind) => (
            <button
              key={kind}
              onClick={() => navigate(`/configs/create/${kind.toLowerCase()}`)}
              className="px-4 py-2 bg-nix-500 text-white rounded-lg hover:bg-nix-600 transition"
            >
              New {kind}
            </button>
          ))}
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4 flex space-x-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Namespace
          </label>
          <select
            value={filterNamespace}
            onChange={(e) => setFilterNamespace(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-nix-500 focus:border-nix-500"
          >
            <option value="all">All Namespaces</option>
            <option value="default">default</option>
            <option value="kube-system">kube-system</option>
            <option value="kube-public">kube-public</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Kind
          </label>
          <select
            value={filterKind}
            onChange={(e) => setFilterKind(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-nix-500 focus:border-nix-500"
          >
            <option value="all">All Types</option>
            {configKinds.map((kind) => (
              <option key={kind} value={kind.toLowerCase()}>
                {kind}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Configs Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        {configs.length === 0 ? (
          <div className="p-6 text-center text-gray-500">No configurations found</div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Name</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Kind</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Namespace</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Size</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Updated</th>
                <th className="px-6 py-3 text-right text-sm font-medium text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {configs.map((config) => (
                <tr key={config.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4">
                    <button
                      onClick={() => navigate(`/configs/${config.id}`)}
                      className="font-medium text-nix-500 hover:text-nix-600"
                    >
                      {config.name}
                    </button>
                  </td>
                  <td className="px-6 py-4 text-gray-900">{config.kind}</td>
                  <td className="px-6 py-4 text-gray-600">{config.namespace}</td>
                  <td className="px-6 py-4 text-gray-600">{(config.size / 1024).toFixed(1)} KB</td>
                  <td className="px-6 py-4 text-gray-600 text-sm">
                    {new Date(config.updated).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 text-right space-x-2">
                    <button className="text-nix-500 hover:text-nix-600 text-sm">Edit</button>
                    <button className="text-red-500 hover:text-red-600 text-sm">Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}

function ConfigDetail() {
  const [config, setConfig] = useState<ConfigDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [isEditing, setIsEditing] = useState(false)
  const [editData, setEditData] = useState<Record<string, string>>({})
  const setError = useAppStore((state) => state.setError)

  useEffect(() => {
    loadConfig()
  }, [])

  async function loadConfig() {
    try {
      setLoading(true)
      const api = getApi()
      const res = await api.get('/api/configs/default/my-config')
      setConfig(res.data)
      setEditData(res.data?.data || {})
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to load config')
    } finally {
      setLoading(false)
    }
  }

  if (loading || !config) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-nix-500"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{config.name}</h1>
          <p className="text-gray-600">
            {config.namespace}/{config.kind}
          </p>
        </div>
        <button
          onClick={() => setIsEditing(!isEditing)}
          className="px-4 py-2 bg-nix-500 text-white rounded-lg hover:bg-nix-600 transition"
        >
          {isEditing ? 'Cancel' : 'Edit'}
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Data</h2>
            {isEditing ? (
              <div className="space-y-3">
                {Object.entries(editData).map(([key, value]) => (
                  <div key={key}>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      {key}
                    </label>
                    <textarea
                      value={value}
                      onChange={(e) =>
                        setEditData({ ...editData, [key]: e.target.value })
                      }
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-nix-500 focus:border-nix-500"
                      rows={3}
                    />
                  </div>
                ))}
              </div>
            ) : (
              <div className="space-y-3">
                {Object.entries(config.data).map(([key, value]) => (
                  <div key={key} className="border-b border-gray-200 pb-3 last:border-b-0">
                    <p className="text-sm font-medium text-gray-700">{key}</p>
                    <pre className="text-sm text-gray-600 bg-gray-50 p-2 rounded mt-1 overflow-x-auto">
                      {value}
                    </pre>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-white rounded-lg shadow p-6">
            <h3 className="text-sm font-semibold text-gray-900 mb-3">Information</h3>
            <div className="space-y-2 text-sm">
              <div>
                <p className="text-gray-600">Kind</p>
                <p className="font-medium text-gray-900">{config.kind}</p>
              </div>
              <div>
                <p className="text-gray-600">Namespace</p>
                <p className="font-medium text-gray-900">{config.namespace}</p>
              </div>
              <div>
                <p className="text-gray-600">Created</p>
                <p className="font-medium text-gray-900">
                  {new Date(config.created).toLocaleDateString()}
                </p>
              </div>
              <div>
                <p className="text-gray-600">Updated</p>
                <p className="font-medium text-gray-900">
                  {new Date(config.updated).toLocaleDateString()}
                </p>
              </div>
              {config.owner && (
                <div>
                  <p className="text-gray-600">Owner</p>
                  <p className="font-medium text-gray-900">{config.owner}</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

function ConfigForm() {
  const [formData, setFormData] = useState<Record<string, string>>({
    name: '',
    namespace: 'default',
    data: '',
  })
  const navigate = useNavigate()
  const setError = useAppStore((state) => state.setError)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    try {
      const api = getApi()
      await api.post('/api/configs', formData)
      navigate('/configs')
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to create config')
    }
  }

  return (
    <div className="max-w-2xl">
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Create Configuration</h1>

      <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow p-6 space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Name</label>
          <input
            type="text"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            required
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-nix-500 focus:border-nix-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Namespace</label>
          <select
            value={formData.namespace}
            onChange={(e) => setFormData({ ...formData, namespace: e.target.value })}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-nix-500 focus:border-nix-500"
          >
            <option value="default">default</option>
            <option value="kube-system">kube-system</option>
            <option value="kube-public">kube-public</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">Data</label>
          <textarea
            value={formData.data}
            onChange={(e) => setFormData({ ...formData, data: e.target.value })}
            placeholder="YAML or JSON format"
            rows={10}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg font-mono text-sm focus:outline-none focus:ring-nix-500 focus:border-nix-500"
          />
        </div>

        <div className="flex space-x-3">
          <button
            type="submit"
            className="px-4 py-2 bg-nix-500 text-white rounded-lg hover:bg-nix-600 transition"
          >
            Create
          </button>
          <button
            type="button"
            onClick={() => navigate('/configs')}
            className="px-4 py-2 bg-gray-200 text-gray-900 rounded-lg hover:bg-gray-300 transition"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  )
}
