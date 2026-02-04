# RBAC Policy Generation
#
# This module provides:
# - Role and RoleBinding generation
# - ClusterRole and ClusterRoleBinding generation
# - ServiceAccount creation with proper permissions
# - RBAC validation

{ lib }:

let
  inherit (lib) concatStringsSep mkOption types;

in
{
  # Create a simple Role
  mkRole = { name, namespace, rules }:
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "Role";
      metadata = { inherit name namespace; };
      inherit rules;
    };

  # Create a simple RoleBinding
  mkRoleBinding = { name, namespace, role, subjects }:
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "RoleBinding";
      metadata = { inherit name namespace; };
      roleRef = {
        apiGroup = "rbac.authorization.k8s.io";
        kind = "Role";
        inherit name role;
      };
      inherit subjects;
    };

  # Create a ClusterRole
  mkClusterRole = { name, rules }:
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "ClusterRole";
      metadata = { inherit name; };
      inherit rules;
    };

  # Create a ClusterRoleBinding
  mkClusterRoleBinding = { name, role, subjects }:
    {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "ClusterRoleBinding";
      metadata = { inherit name; };
      roleRef = {
        apiGroup = "rbac.authorization.k8s.io";
        kind = "ClusterRole";
        inherit name role;
      };
      inherit subjects;
    };

  # Create a ServiceAccount
  mkServiceAccount = { name, namespace ? "default" }:
    {
      apiVersion = "v1";
      kind = "ServiceAccount";
      metadata = { inherit name namespace; };
    };

  # Common permission rule sets

  # Read-only access to pods
  readPodsRule = {
    apiGroups = [ "" ];
    resources = [ "pods" "pods/log" ];
    verbs = [ "get" "list" "watch" ];
  };

  # Read-only access to deployments
  readDeploymentsRule = {
    apiGroups = [ "apps" ];
    resources = [ "deployments" "deployments/status" ];
    verbs = [ "get" "list" "watch" ];
  };

  # Full access to configmaps
  configMapsRule = {
    apiGroups = [ "" ];
    resources = [ "configmaps" ];
    verbs = [ "get" "list" "watch" "create" "update" "patch" "delete" ];
  };

  # Full access to secrets (dangerous, use with caution)
  secretsRule = {
    apiGroups = [ "" ];
    resources = [ "secrets" ];
    verbs = [ "get" "list" "watch" "create" "update" "patch" "delete" ];
  };

  # Admission control
  admissionRule = {
    apiGroups = [ "" ];
    resources = [ "pods" ];
    verbs = [ "create" "update" ];
  };

  # Create standard ServiceAccount with read-only permissions
  mkReadOnlyServiceAccount = { name, namespace ? "default" }:
    let
      sa = mkServiceAccount { inherit name namespace; };
      role = mkRole {
        name = "${name}-reader";
        inherit namespace;
        rules = [
          {
            apiGroups = [ "" ];
            resources = [ "pods" "services" ];
            verbs = [ "get" "list" "watch" ];
          }
          {
            apiGroups = [ "apps" ];
            resources = [ "deployments" "statefulsets" ];
            verbs = [ "get" "list" "watch" ];
          }
        ];
      };
      binding = mkRoleBinding {
        name = "${name}-reader-binding";
        inherit namespace;
        role = "${name}-reader";
        subjects = [
          {
            kind = "ServiceAccount";
            inherit name namespace;
          }
        ];
      };
    in
    { inherit sa role binding; all = [ sa role binding ]; };

  # Create ServiceAccount with edit permissions
  mkEditServiceAccount = { name, namespace ? "default" }:
    let
      sa = mkServiceAccount { inherit name namespace; };
      role = mkRole {
        name = "${name}-editor";
        inherit namespace;
        rules = [
          {
            apiGroups = [ "" ];
            resources = [ "pods" "services" "configmaps" ];
            verbs = [ "get" "list" "watch" "create" "update" "patch" "delete" ];
          }
          {
            apiGroups = [ "apps" ];
            resources = [ "deployments" ];
            verbs = [ "get" "list" "watch" "update" "patch" ];
          }
        ];
      };
      binding = mkRoleBinding {
        name = "${name}-editor-binding";
        inherit namespace;
        role = "${name}-editor";
        subjects = [
          {
            kind = "ServiceAccount";
            inherit name namespace;
          }
        ];
      };
    in
    { inherit sa role binding; all = [ sa role binding ]; };

  # Validate RBAC configuration
  validateRBAC = { roles, roleBindings }:
    let
      roleNames = map (r: r.metadata.name) roles;
      referencedRoles = map (rb: rb.roleRef.name) roleBindings;
      missingRoles = lib.filter (role: !(lib.elem role roleNames)) referencedRoles;
    in
    if missingRoles == [ ] then
      { valid = true; }
    else
      throw "RoleBindings reference undefined Roles: ${concatStringsSep ", " missingRoles}";
}
