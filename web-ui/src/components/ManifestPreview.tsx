import React from 'react'
import { validateManifest, type ValidationResult } from '@utils/manifestValidation'

interface ManifestPreviewProps {
  manifest: any
  onValidationChange?: (result: ValidationResult) => void
}

export default function ManifestPreview({ manifest, onValidationChange }: ManifestPreviewProps) {
  const [validation, setValidation] = React.useState<ValidationResult | null>(null)

  React.useEffect(() => {
    if (manifest && Object.keys(manifest).length > 0) {
      const result = validateManifest(manifest)
      setValidation(result)
      onValidationChange?.(result)
    }
  }, [manifest, onValidationChange])

  if (!validation) {
    return (
      <div className="bg-gray-50 rounded-lg p-4 text-center text-gray-500">
        No manifest data
      </div>
    )
  }

  const errorCount = validation.errors.length
  const warningCount = validation.warnings.length
  const isValid = validation.valid

  return (
    <div className="space-y-4">
      {/* Validation Summary */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Validation Summary</h3>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Status */}
          <div className="flex items-center space-x-4">
            <div
              className={`w-12 h-12 rounded-full flex items-center justify-center text-white font-bold text-lg ${
                isValid ? 'bg-green-500' : 'bg-red-500'
              }`}
            >
              {isValid ? '✓' : '✕'}
            </div>
            <div>
              <p className="text-gray-600 text-sm">Status</p>
              <p className={`text-lg font-semibold ${isValid ? 'text-green-600' : 'text-red-600'}`}>
                {isValid ? 'Valid' : 'Invalid'}
              </p>
            </div>
          </div>

          {/* Errors */}
          <div className="flex items-center space-x-4">
            <div className="w-12 h-12 rounded-full flex items-center justify-center bg-red-100 text-red-600 font-bold text-lg">
              {errorCount}
            </div>
            <div>
              <p className="text-gray-600 text-sm">Errors</p>
              <p className="text-lg font-semibold text-gray-900">{errorCount}</p>
            </div>
          </div>

          {/* Warnings */}
          <div className="flex items-center space-x-4">
            <div className="w-12 h-12 rounded-full flex items-center justify-center bg-yellow-100 text-yellow-600 font-bold text-lg">
              {warningCount}
            </div>
            <div>
              <p className="text-gray-600 text-sm">Warnings</p>
              <p className="text-lg font-semibold text-gray-900">{warningCount}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Manifest Metadata */}
      {(manifest.kind || manifest.apiVersion || manifest.metadata?.name) && (
        <div className="bg-white rounded-lg shadow p-6">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Manifest Information</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {manifest.kind && (
              <div>
                <p className="text-sm font-medium text-gray-700">Kind</p>
                <p className="text-gray-900 font-mono text-sm mt-1">{manifest.kind}</p>
              </div>
            )}
            {manifest.apiVersion && (
              <div>
                <p className="text-sm font-medium text-gray-700">API Version</p>
                <p className="text-gray-900 font-mono text-sm mt-1">{manifest.apiVersion}</p>
              </div>
            )}
            {manifest.metadata?.name && (
              <div>
                <p className="text-sm font-medium text-gray-700">Name</p>
                <p className="text-gray-900 font-mono text-sm mt-1">{manifest.metadata.name}</p>
              </div>
            )}
            {manifest.metadata?.namespace && (
              <div>
                <p className="text-sm font-medium text-gray-700">Namespace</p>
                <p className="text-gray-900 font-mono text-sm mt-1">{manifest.metadata.namespace}</p>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Errors */}
      {errorCount > 0 && (
        <div className="bg-white rounded-lg shadow p-6 border-l-4 border-red-500">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Errors</h3>
          <div className="space-y-3">
            {validation.errors.map((error, index) => (
              <div key={index} className="flex items-start space-x-3">
                <div className="flex-shrink-0 mt-0.5">
                  <div className="flex items-center justify-center h-5 w-5 rounded-full bg-red-100 text-red-600 text-xs font-bold">
                    !
                  </div>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900">{error.field}</p>
                  <p className="text-sm text-gray-600 mt-0.5">{error.message}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Warnings */}
      {warningCount > 0 && (
        <div className="bg-white rounded-lg shadow p-6 border-l-4 border-yellow-500">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Warnings</h3>
          <div className="space-y-3">
            {validation.warnings.map((warning, index) => (
              <div key={index} className="flex items-start space-x-3">
                <div className="flex-shrink-0 mt-0.5">
                  <div className="flex items-center justify-center h-5 w-5 rounded-full bg-yellow-100 text-yellow-600 text-xs font-bold">
                    ⚠
                  </div>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-900">{warning.field}</p>
                  <p className="text-sm text-gray-600 mt-0.5">{warning.message}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Success Message */}
      {isValid && validation.errors.length === 0 && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-6">
          <div className="flex items-center space-x-3">
            <div className="text-green-600 text-2xl">✓</div>
            <div>
              <h4 className="font-semibold text-green-900">Valid Manifest</h4>
              <p className="text-sm text-green-700 mt-1">
                This manifest passes all validation checks and is ready to be deployed.
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
