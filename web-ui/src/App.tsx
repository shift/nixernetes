import React, { useEffect, useState } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { initializeApi } from '@services/api'
import { useAppStore } from '@stores/appStore'
import Layout from '@components/Layout'
import LoginPage from '@pages/LoginPage'
import Dashboard from '@pages/Dashboard'
import ConfigsPage from '@pages/ConfigsPage'
import ModulesPage from '@pages/ModulesPage'
import ProjectsPage from '@pages/ProjectsPage'
import NotificationCenter from '@components/NotificationCenter'

interface AuthConfig {
  endpoint: string
  username: string
  password: string
}

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [authLoading, setAuthLoading] = useState(true)
  const setError = useAppStore((state) => state.setError)

  useEffect(() => {
    // Check if auth config is stored in localStorage
    const authConfig = localStorage.getItem('nixernetes_auth')
    if (authConfig) {
      try {
        const config: AuthConfig = JSON.parse(authConfig)
        initializeApi(config.endpoint, config.username, config.password)
        setIsAuthenticated(true)
      } catch (error) {
        console.error('Failed to restore authentication:', error)
        localStorage.removeItem('nixernetes_auth')
      }
    }
    setAuthLoading(false)
  }, [])

  const handleLogin = (config: AuthConfig) => {
    try {
      initializeApi(config.endpoint, config.username, config.password)
      localStorage.setItem('nixernetes_auth', JSON.stringify(config))
      setIsAuthenticated(true)
    } catch (error) {
      setError(error instanceof Error ? error.message : 'Authentication failed')
    }
  }

  const handleLogout = () => {
    localStorage.removeItem('nixernetes_auth')
    setIsAuthenticated(false)
  }

  if (authLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-nix-500"></div>
      </div>
    )
  }

  return (
    <Router>
      <NotificationCenter />
      <Routes>
        <Route
          path="/login"
          element={
            isAuthenticated ? (
              <Navigate to="/dashboard" replace />
            ) : (
              <LoginPage onLogin={handleLogin} />
            )
          }
        />
        <Route
          path="/*"
          element={
            isAuthenticated ? (
              <Layout onLogout={handleLogout}>
                <Routes>
                  <Route path="/dashboard" element={<Dashboard />} />
                  <Route path="/configs/*" element={<ConfigsPage />} />
                  <Route path="/modules/*" element={<ModulesPage />} />
                  <Route path="/projects/*" element={<ProjectsPage />} />
                  <Route path="/" element={<Navigate to="/dashboard" replace />} />
                </Routes>
              </Layout>
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />
      </Routes>
    </Router>
  )
}
