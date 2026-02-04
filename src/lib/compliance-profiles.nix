# Compliance Configuration Management
#
# This module provides:
# - Environment-specific compliance profiles
# - Multi-environment deployment strategies
# - Compliance baseline definitions
# - Environment compliance compatibility checking

{ lib }:

let
  inherit (lib) mkOption types mkDefault mkEnableOption;

in
{
  # Predefined compliance profiles for common scenarios
  complianceProfiles = {
    # Development environment - minimal requirements
    development = {
      level = "low";
      requireNetworkPolicy = false;
      requireAudit = false;
      requireEncryption = false;
      requireRBAC = true;
      podSecurityPolicy = "baseline";
      description = "Development environment with minimal compliance";
    };

    # Staging environment - moderate requirements
    staging = {
      level = "medium";
      requireNetworkPolicy = true;
      requireAudit = true;
      requireEncryption = false;
      requireRBAC = true;
      podSecurityPolicy = "restricted";
      description = "Staging environment with moderate compliance";
    };

    # Production environment - high requirements
    production = {
      level = "high";
      requireNetworkPolicy = true;
      requireAudit = true;
      requireEncryption = true;
      requireRBAC = true;
      podSecurityPolicy = "restricted";
      mutualTLS = true;
      description = "Production environment with high compliance";
    };

    # Regulated production - maximum requirements
    regulated = {
      level = "restricted";
      requireNetworkPolicy = true;
      requireAudit = true;
      requireEncryption = true;
      requireRBAC = true;
      podSecurityPolicy = "restricted";
      mutualTLS = true;
      binaryAuthorization = true;
      imageScan = true;
      description = "Regulated environment with maximum compliance";
    };
  };

  # Get a predefined profile
  getProfile = name:
    complianceProfiles.${name}
      or (throw "Unknown compliance profile: ${name}. Available: ${lib.concatStringsSep ", " (builtins.attrNames complianceProfiles)}");

  # All available profiles
  availableProfiles = builtins.attrNames complianceProfiles;

  # Merge compliance settings
  mergeCompliance = { base, override }:
    base // override;

  # Create environment-specific compliance
  mkEnvironmentCompliance = { environment, framework, owner }:
    let
      profile = getProfile environment;
    in
    profile // {
      inherit environment framework owner;
    };

  # Check if deployment is compatible with environment
  isCompatible = { deployment, environment }:
    let
      profile = getProfile environment;
      deploymentLevel = deployment.compliance.level or "low";
      profileLevel = profile.level;

      # Define level hierarchy
      hierarchy = {
        "unrestricted" = 0;
        "low" = 1;
        "medium" = 2;
        "high" = 3;
        "restricted" = 4;
      };

      deploymentScore = hierarchy.${deploymentLevel} or 0;
      profileScore = hierarchy.${profileLevel} or 0;
    in
    deploymentScore >= profileScore;

  # Generate environment-specific manifest
  generateForEnvironment = { resources, environment, framework, owner }:
    let
      compliance = mkEnvironmentCompliance { inherit environment framework owner; };
    in
    {
      inherit resources compliance environment;
      metadata = {
        generatedFor = environment;
        complianceProfile = compliance;
        managedBy = "nixernetes";
      };
    };

  # Multi-environment configuration
  mkMultiEnvironmentDeployment = { name, framework, owner, dev ? { }, staging ? { }, production ? { } }:
    {
      inherit name framework owner;

      dev = mkEnvironmentCompliance {
        environment = "development";
        inherit framework owner;
      } // dev;

      staging = mkEnvironmentCompliance {
        environment = "staging";
        inherit framework owner;
      } // staging;

      production = mkEnvironmentCompliance {
        environment = "production";
        inherit framework owner;
      } // production;

      # Helper to get config for specific environment
      forEnvironment = env:
        if env == "dev" then this.dev
        else if env == "staging" then this.staging
        else if env == "production" then this.production
        else throw "Unknown environment: ${env}";
    };
}
