/**
 * Manifest validation utilities for the web UI
 * Integrates with the Nix-generated validators via the backend API
 */

export interface ValidationResult {
  valid: boolean
  errors: string[]
  warnings?: string[]
}

export interface ManifestValidationState {
  isValidating: boolean
  result: ValidationResult | null
  lastValidated: Date | null
}

/**
 * Supported Kubernetes kinds with their default apiVersions
 */
export const KUBERNETES_KINDS = {
  Pod: { apiVersion: 'v1', defaultNamespace: true },
  Service: { apiVersion: 'v1', defaultNamespace: true },
  Namespace: { apiVersion: 'v1', defaultNamespace: false },
  ConfigMap: { apiVersion: 'v1', defaultNamespace: true },
  Secret: { apiVersion: 'v1', defaultNamespace: true },
  ServiceAccount: { apiVersion: 'v1', defaultNamespace: true },
  Deployment: { apiVersion: 'apps/v1', defaultNamespace: true },
  StatefulSet: { apiVersion: 'apps/v1', defaultNamespace: true },
  DaemonSet: { apiVersion: 'apps/v1', defaultNamespace: true },
  ReplicaSet: { apiVersion: 'apps/v1', defaultNamespace: true },
  Job: { apiVersion: 'batch/v1', defaultNamespace: true },
  CronJob: { apiVersion: 'batch/v1', defaultNamespace: true },
  Ingress: { apiVersion: 'networking.k8s.io/v1', defaultNamespace: true },
  NetworkPolicy: { apiVersion: 'networking.k8s.io/v1', defaultNamespace: true },
  IngressClass: { apiVersion: 'networking.k8s.io/v1', defaultNamespace: false },
  PersistentVolume: { apiVersion: 'v1', defaultNamespace: false },
  PersistentVolumeClaim: { apiVersion: 'v1', defaultNamespace: true },
  Role: { apiVersion: 'rbac.authorization.k8s.io/v1', defaultNamespace: true },
  RoleBinding: { apiVersion: 'rbac.authorization.k8s.io/v1', defaultNamespace: true },
  ClusterRole: { apiVersion: 'rbac.authorization.k8s.io/v1', defaultNamespace: false },
  ClusterRoleBinding: { apiVersion: 'rbac.authorization.k8s.io/v1', defaultNamespace: false },
}

export type KubernetesKind = keyof typeof KUBERNETES_KINDS

/**
 * Get the required fields for a given Kubernetes kind
 */
export function getRequiredFields(kind: KubernetesKind): string[] {
  const requiredFields: Record<KubernetesKind, string[]> = {
    Pod: ['metadata', 'spec'],
    Service: ['metadata', 'spec'],
    Namespace: ['metadata'],
    ConfigMap: ['metadata'],
    Secret: ['metadata'],
    ServiceAccount: ['metadata'],
    Deployment: ['metadata', 'spec'],
    StatefulSet: ['metadata', 'spec'],
    DaemonSet: ['metadata', 'spec'],
    ReplicaSet: ['metadata', 'spec'],
    Job: ['metadata', 'spec'],
    CronJob: ['metadata', 'spec'],
    Ingress: ['metadata', 'spec'],
    NetworkPolicy: ['metadata', 'spec'],
    IngressClass: ['metadata', 'spec'],
    PersistentVolume: ['metadata', 'spec'],
    PersistentVolumeClaim: ['metadata', 'spec'],
    Role: ['metadata'],
    RoleBinding: ['metadata'],
    ClusterRole: ['metadata'],
    ClusterRoleBinding: ['metadata'],
  }

  return requiredFields[kind] || ['metadata']
}

/**
 * Validate a manifest object
 */
export function validateManifest(manifest: any): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  // Check kind
  if (!manifest.kind) {
    errors.push('kind is required')
  } else if (!(manifest.kind in KUBERNETES_KINDS)) {
    errors.push(`kind "${manifest.kind}" is not supported`)
  }

  // Check apiVersion
  if (!manifest.apiVersion) {
    errors.push('apiVersion is required')
  }

  // Check metadata
  if (!manifest.metadata) {
    errors.push('metadata is required')
  } else {
    if (!manifest.metadata.name) {
      errors.push('metadata.name is required')
    } else if (typeof manifest.metadata.name !== 'string') {
      errors.push('metadata.name must be a string')
    } else if (!/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/.test(manifest.metadata.name)) {
      errors.push(
        'metadata.name must be lowercase alphanumeric with hyphens (and not start/end with hyphen)'
      )
    }

    if (manifest.metadata.namespace && typeof manifest.metadata.namespace !== 'string') {
      errors.push('metadata.namespace must be a string')
    }
  }

  // Check required fields for the kind
  if (manifest.kind in KUBERNETES_KINDS) {
    const kind = manifest.kind as KubernetesKind
    const required = getRequiredFields(kind)
    for (const field of required) {
      if (field !== 'metadata' && !manifest[field]) {
        errors.push(`${field} is required for ${kind}`)
      }
    }

    // Check apiVersion matches kind
    const expectedApiVersion = KUBERNETES_KINDS[kind].apiVersion
    if (manifest.apiVersion && manifest.apiVersion !== expectedApiVersion) {
      warnings.push(
        `apiVersion should be "${expectedApiVersion}" for ${kind} (found "${manifest.apiVersion}")`
      )
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  }
}

/**
 * Validate YAML/JSON string
 */
export function validateManifestString(content: string): ValidationResult {
  try {
    // Try JSON first
    const manifest = JSON.parse(content)
    return validateManifest(manifest)
  } catch {
    // Try YAML (simplified - would need proper YAML parser in production)
    try {
      // Simple YAML-like parsing for basic cases
      const lines = content.split('\n')
      const manifest: any = {}

      // This is a simplified parser. In production, use a proper YAML library
      for (const line of lines) {
        const trimmed = line.trim()
        if (!trimmed || trimmed.startsWith('#')) continue

        const match = trimmed.match(/^(\w+):\s*(.*)$/)
        if (match) {
          const [, key, value] = match
          manifest[key] = value === 'null' ? null : value
        }
      }

      if (Object.keys(manifest).length === 0) {
        return {
          valid: false,
          errors: ['Invalid JSON or YAML format'],
        }
      }

      return validateManifest(manifest)
    } catch {
      return {
        valid: false,
        errors: ['Invalid JSON or YAML format'],
      }
    }
  }
}

/**
 * Create a default manifest for a given kind
 */
export function createDefaultManifest(kind: KubernetesKind, name: string, namespace = 'default'): any {
  const apiVersion = KUBERNETES_KINDS[kind].apiVersion
  const needsNamespace = KUBERNETES_KINDS[kind].defaultNamespace

  const base = {
    apiVersion,
    kind,
    metadata: {
      name,
      ...(needsNamespace && { namespace }),
    },
  }

  // Add default spec for resource types that need it
  if (['Deployment', 'StatefulSet', 'DaemonSet', 'ReplicaSet'].includes(kind)) {
    return {
      ...base,
      spec: {
        selector: {
          matchLabels: {
            app: name,
          },
        },
        template: {
          metadata: {
            labels: {
              app: name,
            },
          },
          spec: {
            containers: [
              {
                name,
                image: 'nginx:latest',
                ports: [
                  {
                    containerPort: 80,
                  },
                ],
              },
            ],
          },
        },
      },
    }
  }

  if (kind === 'Service') {
    return {
      ...base,
      spec: {
        selector: {
          app: name,
        },
        ports: [
          {
            protocol: 'TCP',
            port: 80,
            targetPort: 8080,
          },
        ],
        type: 'ClusterIP',
      },
    }
  }

  if (kind === 'ConfigMap' || kind === 'Secret') {
    return {
      ...base,
      data: {},
    }
  }

  if (kind === 'Ingress') {
    return {
      ...base,
      spec: {
        rules: [
          {
            host: `${name}.example.com`,
            http: {
              paths: [
                {
                  path: '/',
                  pathType: 'Prefix',
                  backend: {
                    service: {
                      name,
                      port: {
                        number: 80,
                      },
                    },
                  },
                },
              ],
            },
          },
        ],
      },
    }
  }

  if (kind === 'Job') {
    return {
      ...base,
      spec: {
        template: {
          metadata: {},
          spec: {
            containers: [
              {
                name,
                image: 'busybox',
                command: ['echo', 'hello world'],
              },
            ],
            restartPolicy: 'Never',
          },
        },
      },
    }
  }

  return base
}

/**
 * Convert manifest object to JSON string
 */
export function manifestToJson(manifest: any): string {
  return JSON.stringify(manifest, null, 2)
}

/**
 * Convert manifest object to YAML string (simplified)
 */
export function manifestToYaml(manifest: any): string {
  const lines: string[] = []

  function addYamlLines(obj: any, indent = 0): void {
    const spaces = '  '.repeat(indent)

    for (const [key, value] of Object.entries(obj)) {
      if (value === null || value === undefined) {
        continue
      } else if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
        lines.push(`${spaces}${key}: ${value}`)
      } else if (Array.isArray(value)) {
        lines.push(`${spaces}${key}:`)
        for (const item of value) {
          if (typeof item === 'object') {
            lines.push(`${spaces}  - `)
            addYamlLines(item, indent + 2)
          } else {
            lines.push(`${spaces}  - ${item}`)
          }
        }
      } else if (typeof value === 'object') {
        lines.push(`${spaces}${key}:`)
        addYamlLines(value, indent + 1)
      }
    }
  }

  addYamlLines(manifest)
  return lines.join('\n')
}

/**
 * Parse manifest from JSON string
 */
export function parseManifestJson(content: string): { manifest: any; error?: string } {
  try {
    const manifest = JSON.parse(content)
    return { manifest }
  } catch (error) {
    return { manifest: null, error: error instanceof Error ? error.message : 'Invalid JSON' }
  }
}

/**
 * Batch validate multiple manifests
 */
export function validateManifests(manifests: any[]): {
  valid: boolean
  totalCount: number
  validCount: number
  invalidCount: number
  results: ValidationResult[]
} {
  const results = manifests.map((m) => validateManifest(m))
  const validCount = results.filter((r) => r.valid).length
  const invalidCount = results.length - validCount

  return {
    valid: invalidCount === 0,
    totalCount: manifests.length,
    validCount,
    invalidCount,
    results,
  }
}
