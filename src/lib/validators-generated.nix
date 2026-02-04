# Auto-generated manifest validators
# Generated from upstream Kubernetes OpenAPI specifications
# Validates that manifests conform to Kubernetes API schemas

{ lib }:

let
  # Helper to validate manifest structure
  validateManifest = manifest:
    let
      kind = manifest.kind or null;
      apiVersion = manifest.apiVersion or null;
      metadata = manifest.metadata or null;
    in
    if kind == null then { valid = false; errors = ["Missing kind field"]; }
    else if apiVersion == null then { valid = false; errors = ["Missing apiVersion field"]; }
    else if metadata == null then { valid = false; errors = ["Missing metadata field"]; }
    else if (metadata.name or null) == null then { valid = false; errors = ["metadata.name is required"]; }
    else { valid = true; errors = []; };


  Certificate_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [ "spec" ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Certificate";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Certificate, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Certificate"];
      };


  ClusterRole_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "ClusterRole";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "rbac.authorization.k8s.io/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected ClusterRole, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for ClusterRole"];
      };


  ClusterRoleBinding_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [ "roleRef" ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "ClusterRoleBinding";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "rbac.authorization.k8s.io/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected ClusterRoleBinding, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for ClusterRoleBinding"];
      };


  ConfigMap_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "ConfigMap";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected ConfigMap, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for ConfigMap"];
      };


  CronJob_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "CronJob";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "batch/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected CronJob, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for CronJob"];
      };


  DaemonSet_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "DaemonSet";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "apps/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected DaemonSet, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for DaemonSet"];
      };


  Deployment_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Deployment";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "apps/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Deployment, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Deployment"];
      };


  Ingress_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Ingress";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "networking.k8s.io/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Ingress, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Ingress"];
      };


  IngressClass_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "IngressClass";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "networking.k8s.io/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected IngressClass, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for IngressClass"];
      };


  Job_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Job";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "batch/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Job, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Job"];
      };


  Namespace_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Namespace";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Namespace, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Namespace"];
      };


  NetworkPolicy_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "NetworkPolicy";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "networking.k8s.io/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected NetworkPolicy, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for NetworkPolicy"];
      };


  PersistentVolume_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "PersistentVolume";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected PersistentVolume, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for PersistentVolume"];
      };


  PersistentVolumeClaim_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "PersistentVolumeClaim";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected PersistentVolumeClaim, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for PersistentVolumeClaim"];
      };


  Pod_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Pod";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Pod, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Pod"];
      };


  Policy_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Policy";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Policy, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Policy"];
      };


  ReplicaSet_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "ReplicaSet";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "apps/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected ReplicaSet, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for ReplicaSet"];
      };


  Role_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Role";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "rbac.authorization.k8s.io/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Role, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Role"];
      };


  RoleBinding_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [ "roleRef" ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "RoleBinding";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "rbac.authorization.k8s.io/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected RoleBinding, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for RoleBinding"];
      };


  Secret_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Secret";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Secret, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Secret"];
      };


  Service_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [ "namespace" "name" ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "Service";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected Service, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for Service"];
      };


  ServiceAccount_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "ServiceAccount";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected ServiceAccount, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for ServiceAccount"];
      };


  StatefulSet_validator = manifest: 
    let
      kind = manifest.kind or "";
      apiVersion = manifest.apiVersion or "";
      metadata = manifest.metadata or {};
      spec = manifest.spec or {};
      
      # Required fields at top level
      requiredFields = [  ];
      
      # Validate required fields exist
      validateRequired = builtins.all (field:
        builtins.hasAttr field manifest
      ) requiredFields;
      
      # Validate metadata
      metadataValid = (metadata.name or null) != null && 
                      (builtins.typeOf metadata.name == "string");
      
      # Validate kind matches
      kindMatches = kind == "StatefulSet";
      
      # Validate apiVersion matches
      apiVersionMatches = apiVersion == "apps/v1" || 
                          apiVersion == "v1";
    in
      {
        valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
        errors = lib.optionals (!validateRequired) ["Missing required fields: ${builtins.toJSON requiredFields}"] ++
                 lib.optionals (!metadataValid) ["Invalid metadata: requires name (string)"] ++
                 lib.optionals (!kindMatches) ["Kind mismatch: expected StatefulSet, got ${kind}"] ++
                 lib.optionals (!apiVersionMatches) ["API version mismatch for StatefulSet"];
      };

  # Look up validator for a kind
  getValidator = kind:
    {
      Certificate = Certificate_validator;
      ClusterRole = ClusterRole_validator;
      ClusterRoleBinding = ClusterRoleBinding_validator;
      ConfigMap = ConfigMap_validator;
      CronJob = CronJob_validator;
      DaemonSet = DaemonSet_validator;
      Deployment = Deployment_validator;
      Ingress = Ingress_validator;
      IngressClass = IngressClass_validator;
      Job = Job_validator;
      Namespace = Namespace_validator;
      NetworkPolicy = NetworkPolicy_validator;
      PersistentVolume = PersistentVolume_validator;
      PersistentVolumeClaim = PersistentVolumeClaim_validator;
      Pod = Pod_validator;
      Policy = Policy_validator;
      ReplicaSet = ReplicaSet_validator;
      Role = Role_validator;
      RoleBinding = RoleBinding_validator;
      Secret = Secret_validator;
      Service = Service_validator;
      ServiceAccount = ServiceAccount_validator;
      StatefulSet = StatefulSet_validator;
    }.${kind} or (throw ("No validator for kind: " + kind));

in
{
  validateManifest = validateManifest;
  getValidator = getValidator;
  validate = kind: manifest:
    let
      validator = getValidator kind;
    in
    validator manifest;
}