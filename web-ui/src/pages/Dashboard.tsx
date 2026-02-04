import React, { useEffect, useState } from 'react'
import { useAppStore } from '@stores/appStore'
import { getApi } from '@services/api'

interface ClusterInfo {
  version: string
  nodes: number
  pods: number
  namespaces: number
  services: number
}

interface ModuleStatus {
  name: string
  status: 'active' | 'inactive' | 'error'
  version: string
  lastUpdated: string
}

interface RecentActivity {
  id: string
  type: 'deployment' | 'config' | 'module' | 'system'
  action: string
  resource: string
  timestamp: string
  status: 'success' | 'pending' | 'error'
}

export default function Dashboard() {
  const [clusterInfo, setClusterInfo] = useState<ClusterInfo | null>(null)
  const [modules, setModules] = useState<ModuleStatus[]>([])
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([])
  const [loading, setLoading] = useState(true)
  const setError = useAppStore((state) => state.setError)

  useEffect(() => {
    loadDashboardData()
  }, [])

  async function loadDashboardData() {
    try {
      setLoading(true)
      const api = getApi()
      
      // Load cluster info
      const clusterRes = await api.get('/api/cluster/info')
      setClusterInfo(clusterRes.data)

      // Load active modules
      const modulesRes = await api.get('/api/modules')
      setModules(modulesRes.data || [])

      // Load recent activity
      const activityRes = await api.get('/api/activity?limit=10')
      setRecentActivity(activityRes.data || [])
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Failed to load dashboard data')
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
      <h1 className="text-3xl font-bold text-gray-900">Cluster Dashboard</h1>

      {/* Cluster Info Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {clusterInfo && (
          <>
            <InfoCard
              title="Kubernetes Version"
              value={clusterInfo.version}
              icon="📦"
            />
            <InfoCard
              title="Nodes"
              value={clusterInfo.nodes.toString()}
              icon="🖥️"
            />
            <InfoCard
              title="Pods"
              value={clusterInfo.pods.toString()}
              icon="📮"
            />
            <InfoCard
              title="Services"
              value={clusterInfo.services.toString()}
              icon="🔌"
            />
          </>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Modules Section */}
        <div className="lg:col-span-2">
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Active Modules</h2>
            {modules.length === 0 ? (
              <p className="text-gray-500 text-center py-4">No modules loaded</p>
            ) : (
              <div className="space-y-3">
                {modules.map((module) => (
                  <div
                    key={module.name}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
                  >
                    <div>
                      <p className="font-medium text-gray-900">{module.name}</p>
                      <p className="text-sm text-gray-500">v{module.version}</p>
                    </div>
                    <div className="flex items-center space-x-2">
                      <StatusBadge status={module.status} />
                      <time className="text-xs text-gray-400">
                        {new Date(module.lastUpdated).toLocaleDateString()}
                      </time>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Quick Stats */}
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Quick Stats</h2>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-gray-600">CPU Usage</span>
                <span className="font-medium text-gray-900">45%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className="bg-nix-500 h-2 rounded-full"
                  style={{ width: '45%' }}
                ></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-gray-600">Memory Usage</span>
                <span className="font-medium text-gray-900">62%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className="bg-yellow-500 h-2 rounded-full"
                  style={{ width: '62%' }}
                ></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-gray-600">Storage Usage</span>
                <span className="font-medium text-gray-900">38%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div
                  className="bg-green-500 h-2 rounded-full"
                  style={{ width: '38%' }}
                ></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Recent Activity</h2>
        {recentActivity.length === 0 ? (
          <p className="text-gray-500 text-center py-4">No recent activity</p>
        ) : (
          <div className="space-y-2">
            {recentActivity.map((activity) => (
              <div
                key={activity.id}
                className="flex items-center justify-between p-3 border-l-4 border-gray-200 hover:bg-gray-50 transition"
                style={{
                  borderColor:
                    activity.status === 'success'
                      ? '#10b981'
                      : activity.status === 'error'
                      ? '#ef4444'
                      : '#f59e0b',
                }}
              >
                <div className="flex-1">
                  <p className="text-sm font-medium text-gray-900">
                    {activity.action} <span className="text-gray-600">{activity.resource}</span>
                  </p>
                  <p className="text-xs text-gray-500">{activity.type}</p>
                </div>
                <div className="flex items-center space-x-2">
                  <span className="text-xs text-gray-400">
                    {new Date(activity.timestamp).toLocaleTimeString()}
                  </span>
                  <ActivityStatusIcon status={activity.status} />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

interface InfoCardProps {
  title: string
  value: string
  icon: string
}

function InfoCard({ title, value, icon }: InfoCardProps) {
  return (
    <div className="bg-white rounded-lg shadow p-6 hover:shadow-lg transition">
      <div className="flex items-center">
        <span className="text-3xl mr-4">{icon}</span>
        <div>
          <p className="text-gray-600 text-sm">{title}</p>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
        </div>
      </div>
    </div>
  )
}

interface StatusBadgeProps {
  status: 'active' | 'inactive' | 'error'
}

function StatusBadge({ status }: StatusBadgeProps) {
  const statusConfig = {
    active: { bg: 'bg-green-100', text: 'text-green-800', label: 'Active' },
    inactive: { bg: 'bg-gray-100', text: 'text-gray-800', label: 'Inactive' },
    error: { bg: 'bg-red-100', text: 'text-red-800', label: 'Error' },
  }

  const config = statusConfig[status]
  return (
    <span className={`px-2 py-1 rounded-full text-xs font-medium ${config.bg} ${config.text}`}>
      {config.label}
    </span>
  )
}

interface ActivityStatusIconProps {
  status: 'success' | 'pending' | 'error'
}

function ActivityStatusIcon({ status }: ActivityStatusIconProps) {
  if (status === 'success') {
    return <span className="text-green-500">✓</span>
  } else if (status === 'error') {
    return <span className="text-red-500">✕</span>
  } else {
    return <span className="text-yellow-500 animate-spin">⟳</span>
  }
}
