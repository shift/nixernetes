import React, { useEffect, useState } from 'react'
import { Routes, Route, useNavigate } from 'react-router-dom'
import { useAppStore } from '@stores/appStore'
import { getApi } from '@services/api'

interface Project {
  id: string
  name: string
  description: string
  status: 'active' | 'archived' | 'error'
  owner: string
  created: string
  updated: string
  resourceCount: number
  manifestCount: number
}

interface ProjectDetail extends Project {
  manifests: Array<{
    id: string
    name: string
    kind: string
    valid: boolean
  }>
  config: Record<string, unknown>
}

export default function ProjectsPage() {
  return (
    <Routes>
      <Route path="/" element={<ProjectsList />} />
      <Route path="/:id" element={<ProjectDetail />} />
    </Routes>
  )
}

function ProjectsList() {
  const [projects, setProjects] = useState<Project[]>([])
  const [loading, setLoading] = useState(true)
  const [filterStatus, setFilterStatus] = useState<string>('all')
  const navigate = useNavigate()
  const setError = useAppStore((state) => state.setError)

  useEffect(() => {
    loadProjects()
  }, [filterStatus])

  async function loadProjects() {
    try {
      setLoading(true)
      const api = getApi()
      let url = '/api/projects'
      if (filterStatus !== 'all') {
        url += `?status=${filterStatus}`
      }
      const res = await api.get(url)
      setProjects(res.data || [])
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to load projects')
    } finally {
      setLoading(false)
    }
  }

  async function deleteProject(id: string) {
    if (!confirm('Are you sure you want to delete this project?')) {
      return
    }
    try {
      const api = getApi()
      await api.delete(`/api/projects/${id}`)
      loadProjects()
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to delete project')
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
        <h1 className="text-3xl font-bold text-gray-900">Projects</h1>
        <button
          onClick={() => navigate('/projects/new')}
          className="px-4 py-2 bg-nix-500 text-white rounded-lg hover:bg-nix-600 transition"
        >
          New Project
        </button>
      </div>

      {/* Status Filter */}
      <div className="bg-white rounded-lg shadow p-4 flex space-x-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Status
          </label>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-nix-500 focus:border-nix-500"
          >
            <option value="all">All Status</option>
            <option value="active">Active</option>
            <option value="archived">Archived</option>
            <option value="error">Error</option>
          </select>
        </div>
      </div>

      {/* Projects Grid */}
      {projects.length === 0 ? (
        <div className="bg-white rounded-lg shadow p-6 text-center text-gray-500">
          No projects found. Create one to get started!
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {projects.map((project) => (
            <div
              key={project.id}
              className="bg-white rounded-lg shadow p-6 hover:shadow-lg transition"
            >
              <div className="flex justify-between items-start mb-4">
                <div>
                  <button
                    onClick={() => navigate(`/projects/${project.id}`)}
                    className="text-xl font-semibold text-nix-500 hover:text-nix-600"
                  >
                    {project.name}
                  </button>
                  <p className="text-gray-600 mt-1">{project.description}</p>
                </div>
                <StatusBadge status={project.status} />
              </div>

              <div className="grid grid-cols-3 gap-4 mb-4 pt-4 border-t border-gray-200">
                <div>
                  <p className="text-gray-600 text-sm">Resources</p>
                  <p className="text-lg font-semibold text-gray-900">{project.resourceCount}</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm">Manifests</p>
                  <p className="text-lg font-semibold text-gray-900">{project.manifestCount}</p>
                </div>
                <div>
                  <p className="text-gray-600 text-sm">Owner</p>
                  <p className="text-lg font-semibold text-gray-900 truncate" title={project.owner}>
                    {project.owner}
                  </p>
                </div>
              </div>

              <div className="flex justify-between items-center text-sm text-gray-600 mb-4">
                <span>Created {new Date(project.created).toLocaleDateString()}</span>
                <span>Updated {new Date(project.updated).toLocaleDateString()}</span>
              </div>

              <div className="flex space-x-2">
                <button
                  onClick={() => navigate(`/projects/${project.id}`)}
                  className="flex-1 px-3 py-2 text-sm bg-nix-500 text-white rounded hover:bg-nix-600 transition"
                >
                  View
                </button>
                <button className="flex-1 px-3 py-2 text-sm bg-gray-200 text-gray-900 rounded hover:bg-gray-300 transition">
                  Edit
                </button>
                <button
                  onClick={() => deleteProject(project.id)}
                  className="px-3 py-2 text-sm bg-red-100 text-red-700 rounded hover:bg-red-200 transition"
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

function ProjectDetail() {
  const [project, setProject] = useState<ProjectDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()
  const setError = useAppStore((state) => state.setError)

  useEffect(() => {
    loadProject()
  }, [])

  async function loadProject() {
    try {
      setLoading(true)
      const api = getApi()
      const res = await api.get('/api/projects/example-project')
      setProject(res.data)
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to load project')
    } finally {
      setLoading(false)
    }
  }

  if (loading || !project) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-nix-500"></div>
      </div>
    )
  }

  const validCount = project.manifests.filter((m) => m.valid).length
  const invalidCount = project.manifests.length - validCount

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-start">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{project.name}</h1>
          <p className="text-gray-600 mt-2">{project.description}</p>
        </div>
        <button
          onClick={() => navigate('/projects')}
          className="px-4 py-2 bg-gray-200 text-gray-900 rounded-lg hover:bg-gray-300 transition"
        >
          Back
        </button>
      </div>

      {/* Status Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <InfoCard label="Status" value={project.status} />
        <InfoCard label="Resources" value={project.resourceCount.toString()} />
        <InfoCard label="Manifests" value={project.manifestCount.toString()} />
        <InfoCard label="Owner" value={project.owner} />
      </div>

      {/* Manifest Validation Summary */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Manifest Validation</h2>
        <div className="flex items-center space-x-8">
          <div>
            <p className="text-gray-600 text-sm">Valid Manifests</p>
            <p className="text-3xl font-bold text-green-600">{validCount}</p>
          </div>
          <div>
            <p className="text-gray-600 text-sm">Invalid Manifests</p>
            <p className="text-3xl font-bold text-red-600">{invalidCount}</p>
          </div>
          <div className="flex-1">
            <div className="w-full bg-gray-200 rounded-full h-3">
              <div
                className="bg-green-500 h-3 rounded-full transition-all"
                style={{
                  width: `${(validCount / project.manifestCount) * 100}%`,
                }}
              ></div>
            </div>
            <p className="text-sm text-gray-600 mt-2">
              {((validCount / project.manifestCount) * 100).toFixed(1)}% of manifests are valid
            </p>
          </div>
        </div>
      </div>

      {/* Manifests List */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Manifests</h2>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Name</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Kind</th>
                <th className="px-6 py-3 text-left text-sm font-medium text-gray-700">Status</th>
                <th className="px-6 py-3 text-right text-sm font-medium text-gray-700">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {project.manifests.map((manifest) => (
                <tr key={manifest.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{manifest.name}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">{manifest.kind}</td>
                  <td className="px-6 py-4 text-sm">
                    <span
                      className={`px-2 py-1 rounded-full text-xs font-medium ${
                        manifest.valid
                          ? 'bg-green-100 text-green-800'
                          : 'bg-red-100 text-red-800'
                      }`}
                    >
                      {manifest.valid ? 'Valid' : 'Invalid'}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-right text-sm space-x-2">
                    <button className="text-nix-500 hover:text-nix-600">View</button>
                    <button className="text-blue-500 hover:text-blue-600">Edit</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Project Config */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Configuration</h2>
        <pre className="bg-gray-50 p-4 rounded-lg overflow-x-auto text-sm">
          {JSON.stringify(project.config, null, 2)}
        </pre>
      </div>
    </div>
  )
}

interface InfoCardProps {
  label: string
  value: string
}

function InfoCard({ label, value }: InfoCardProps) {
  return (
    <div className="bg-white rounded-lg shadow p-4">
      <p className="text-gray-600 text-sm">{label}</p>
      <p className="text-lg font-semibold text-gray-900 truncate" title={value}>
        {value}
      </p>
    </div>
  )
}

interface StatusBadgeProps {
  status: 'active' | 'archived' | 'error'
}

function StatusBadge({ status }: StatusBadgeProps) {
  const statusConfig = {
    active: { bg: 'bg-green-100', text: 'text-green-800', label: 'Active' },
    archived: { bg: 'bg-gray-100', text: 'text-gray-800', label: 'Archived' },
    error: { bg: 'bg-red-100', text: 'text-red-800', label: 'Error' },
  }

  const config = statusConfig[status]
  return (
    <span className={`px-3 py-1 rounded-full text-sm font-medium ${config.bg} ${config.text}`}>
      {config.label}
    </span>
  )
}
