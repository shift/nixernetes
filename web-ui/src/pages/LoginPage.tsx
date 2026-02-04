import React, { useState } from 'react'

interface LoginFormData {
  endpoint: string
  username: string
  password: string
}

interface LoginPageProps {
  onLogin: (config: LoginFormData) => void
}

export default function LoginPage({ onLogin }: LoginPageProps) {
  const [formData, setFormData] = useState<LoginFormData>({
    endpoint: 'http://localhost:8080',
    username: '',
    password: '',
  })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      // Validate inputs
      if (!formData.endpoint.trim()) {
        setError('Endpoint is required')
        return
      }
      if (!formData.username.trim()) {
        setError('Username is required')
        return
      }
      if (!formData.password.trim()) {
        setError('Password is required')
        return
      }

      // Call the login handler
      onLogin(formData)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-nix-600 to-nix-800 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Logo/Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-white mb-2">Nixernetes</h1>
          <p className="text-nix-200">Declarative Kubernetes Management</p>
        </div>

        {/* Login Form */}
        <div className="bg-white rounded-lg shadow-xl p-8 space-y-6">
          <h2 className="text-2xl font-bold text-gray-900">Welcome Back</h2>

          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4">
              <p className="text-red-800 text-sm">{error}</p>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Endpoint Input */}
            <div>
              <label htmlFor="endpoint" className="block text-sm font-medium text-gray-700 mb-2">
                API Endpoint
              </label>
              <input
                id="endpoint"
                type="url"
                value={formData.endpoint}
                onChange={(e) =>
                  setFormData({ ...formData, endpoint: e.target.value })
                }
                placeholder="http://localhost:8080"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-nix-500 focus:border-transparent transition"
              />
              <p className="text-xs text-gray-500 mt-1">
                The URL of your Nixernetes API server
              </p>
            </div>

            {/* Username Input */}
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-gray-700 mb-2">
                Username
              </label>
              <input
                id="username"
                type="text"
                value={formData.username}
                onChange={(e) =>
                  setFormData({ ...formData, username: e.target.value })
                }
                placeholder="admin"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-nix-500 focus:border-transparent transition"
              />
            </div>

            {/* Password Input */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                Password
              </label>
              <input
                id="password"
                type="password"
                value={formData.password}
                onChange={(e) =>
                  setFormData({ ...formData, password: e.target.value })
                }
                placeholder="••••••••"
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-nix-500 focus:border-transparent transition"
              />
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className={`w-full py-2 px-4 rounded-lg font-medium text-white transition ${
                loading
                  ? 'bg-nix-400 cursor-not-allowed'
                  : 'bg-nix-500 hover:bg-nix-600 active:bg-nix-700'
              }`}
            >
              {loading ? (
                <span className="flex items-center justify-center">
                  <svg
                    className="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <circle
                      className="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      strokeWidth="4"
                    ></circle>
                    <path
                      className="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    ></path>
                  </svg>
                  Signing in...
                </span>
              ) : (
                'Sign In'
              )}
            </button>
          </form>

          {/* Demo Credentials */}
          <div className="bg-nix-50 border border-nix-200 rounded-lg p-4">
            <p className="text-sm text-nix-900 font-medium mb-2">Demo Credentials</p>
            <p className="text-xs text-nix-800">
              Username: <code className="bg-nix-100 px-2 py-1 rounded">admin</code>
            </p>
            <p className="text-xs text-nix-800">
              Password: <code className="bg-nix-100 px-2 py-1 rounded">demo</code>
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="text-center mt-8">
          <p className="text-nix-200 text-sm">
            Nixernetes v1.0.0 • © 2026 Nixernetes Contributors
          </p>
        </div>
      </div>
    </div>
  )
}
