import React, { useState, useCallback } from 'react'
import {
  validateManifest,
  validateManifestString,
  manifestToJson,
  manifestToYaml,
  createDefaultManifest,
  KUBERNETES_KINDS,
  type KubernetesKind,
  type ValidationResult,
} from '@utils/manifestValidation'

interface ManifestEditorProps {
  onSave?: (manifest: any) => void
  onValidate?: (result: ValidationResult) => void
  initialManifest?: any
  readOnly?: boolean
  showValidation?: boolean
}

export default function ManifestEditor({
  onSave,
  onValidate,
  initialManifest,
  readOnly = false,
  showValidation = true,
}: ManifestEditorProps) {
  const [manifest, setManifest] = useState<any>(initialManifest || {})
  const [manifestJson, setManifestJson] = useState<string>(
    initialManifest ? JSON.stringify(initialManifest, null, 2) : ''
  )
  const [validation, setValidation] = useState<ValidationResult | null>(null)
  const [format, setFormat] = useState<'json' | 'yaml'>('json')
  const [isValidating, setIsValidating] = useState(false)

  // Validate on change
  const handleValidate = useCallback(
    (content: string) => {
      setIsValidating(true)
      try {
        const result = validateManifestString(content)
        setValidation(result)
        onValidate?.(result)
      } finally {
        setIsValidating(false)
      }
    },
    [onValidate]
  )

  // Handle content change
  const handleContentChange = (content: string) => {
    setManifestJson(content)
    if (showValidation) {
      handleValidate(content)
    }

    // Try to parse and update manifest
    try {
      const parsed = JSON.parse(content)
      setManifest(parsed)
    } catch {
      // Invalid JSON, just keep the old manifest
    }
  }

  // Save manifest
  const handleSave = () => {
    try {
      const parsed = JSON.parse(manifestJson)
      const validation = validateManifest(parsed)

      if (!validation.valid) {
        setValidation(validation)
        return
      }

      setManifest(parsed)
      onSave?.(parsed)
    } catch (error) {
      setValidation({
        valid: false,
        errors: ['Invalid JSON format'],
      })
    }
  }

  // Toggle format
  const toggleFormat = () => {
    try {
      const parsed = JSON.parse(manifestJson)
      if (format === 'json') {
        setManifestJson(manifestToYaml(parsed))
        setFormat('yaml')
      } else {
        setManifestJson(JSON.stringify(parsed, null, 2))
        setFormat('json')
      }
    } catch {
      // Can't parse current content
    }
  }

  // Generate new manifest
  const generateManifest = (kind: KubernetesKind) => {
    const name = prompt('Enter resource name:')
    if (!name) return

    const namespace = prompt('Enter namespace (or leave blank for default):', 'default')
    const newManifest = createDefaultManifest(kind, name, namespace || 'default')

    setManifest(newManifest)
    setManifestJson(JSON.stringify(newManifest, null, 2))
    handleValidate(JSON.stringify(newManifest, null, 2))
  }

  return (
    <div className="space-y-4">
      {/* Toolbar */}
      <div className="flex justify-between items-center bg-white rounded-lg shadow p-4">
        <div className="flex space-x-2">
          <button
            onClick={toggleFormat}
            disabled={readOnly}
            className="px-3 py-2 text-sm bg-gray-200 text-gray-900 rounded hover:bg-gray-300 transition disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {format === 'json' ? 'Convert to YAML' : 'Convert to JSON'}
          </button>

          <div className="border-l border-gray-300"></div>

          <select
            onChange={(e) => generateManifest(e.target.value as KubernetesKind)}
            disabled={readOnly}
            defaultValue=""
            className="px-3 py-2 text-sm border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <option value="">Generate Template...</option>
            {Object.keys(KUBERNETES_KINDS).map((kind) => (
              <option key={kind} value={kind}>
                {kind}
              </option>
            ))}
          </select>
        </div>

        <div className="flex space-x-2">
          {showValidation && (
            <button
              onClick={() => handleValidate(manifestJson)}
              disabled={readOnly}
              className="px-3 py-2 text-sm bg-nix-500 text-white rounded hover:bg-nix-600 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isValidating ? 'Validating...' : 'Validate'}
            </button>
          )}

          {!readOnly && onSave && (
            <button
              onClick={handleSave}
              className="px-3 py-2 text-sm bg-green-500 text-white rounded hover:bg-green-600 transition"
            >
              Save
            </button>
          )}
        </div>
      </div>

      {/* Validation Messages */}
      {validation && showValidation && (
        <div
          className={`rounded-lg p-4 ${
            validation.valid
              ? 'bg-green-50 border border-green-200'
              : 'bg-red-50 border border-red-200'
          }`}
        >
          <div className="flex items-start">
            <div
              className={`flex-shrink-0 text-xl mr-3 ${
                validation.valid ? 'text-green-600' : 'text-red-600'
              }`}
            >
              {validation.valid ? '✓' : '✕'}
            </div>
            <div className="flex-1">
              <h3
                className={`font-semibold mb-2 ${
                  validation.valid ? 'text-green-900' : 'text-red-900'
                }`}
              >
                {validation.valid ? 'Valid Manifest' : 'Validation Errors'}
              </h3>

              {validation.errors.length > 0 && (
                <div className="mb-2">
                  <p className={`text-sm font-medium ${validation.valid ? 'text-green-800' : 'text-red-800'}`}>
                    Errors:
                  </p>
                  <ul
                    className={`text-sm list-disc list-inside space-y-1 ${
                      validation.valid ? 'text-green-700' : 'text-red-700'
                    }`}
                  >
                    {validation.errors.map((error, i) => (
                      <li key={i}>{error}</li>
                    ))}
                  </ul>
                </div>
              )}

              {validation.warnings && validation.warnings.length > 0 && (
                <div>
                  <p className="text-sm font-medium text-yellow-800">Warnings:</p>
                  <ul className="text-sm list-disc list-inside space-y-1 text-yellow-700">
                    {validation.warnings.map((warning, i) => (
                      <li key={i}>{warning}</li>
                    ))}
                  </ul>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Editor */}
      <div className="bg-white rounded-lg shadow overflow-hidden border border-gray-200">
        <div className="bg-gray-50 border-b border-gray-200 px-4 py-2 flex justify-between items-center">
          <span className="text-sm font-medium text-gray-700">
            {format === 'json' ? 'JSON' : 'YAML'} Format
          </span>
          <span className="text-xs text-gray-500">
            {manifestJson.split('\n').length} lines
          </span>
        </div>

        <textarea
          value={manifestJson}
          onChange={(e) => handleContentChange(e.target.value)}
          readOnly={readOnly}
          className="w-full h-96 p-4 font-mono text-sm border-none focus:outline-none focus:ring-inset focus:ring-nix-500 resize-none"
          placeholder="Enter manifest content here..."
          spellCheck="false"
        />
      </div>

      {/* Manifest Info */}
      {manifest.kind && (
        <div className="bg-white rounded-lg shadow p-4">
          <h3 className="text-sm font-semibold text-gray-900 mb-3">Manifest Information</h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div>
              <p className="text-gray-600">Kind</p>
              <p className="font-medium text-gray-900">{manifest.kind}</p>
            </div>
            <div>
              <p className="text-gray-600">API Version</p>
              <p className="font-medium text-gray-900">{manifest.apiVersion || '-'}</p>
            </div>
            <div>
              <p className="text-gray-600">Name</p>
              <p className="font-medium text-gray-900 truncate">{manifest.metadata?.name || '-'}</p>
            </div>
            <div>
              <p className="text-gray-600">Namespace</p>
              <p className="font-medium text-gray-900">{manifest.metadata?.namespace || '-'}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
