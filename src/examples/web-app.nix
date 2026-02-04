# Example: Simple Web Application Deployment
#
# This example demonstrates using Nixernetes to deploy a simple
# web application with proper compliance, security policies, and
# dependencies on a database.

{ lib, ... }:

{
  framework = {
    kubernetesVersion = "1.30";
    namespace = "example";
    
    compliance = {
      labels = {
        "nixernetes.io/framework" = "SOC2";
        "nixernetes.io/owner" = "platform-team";
      };
      level = "high";
    };

    network = {
      policyMode = "deny-all";
      defaultDenyIngress = true;
    };

    secrets = {
      backend = "external-secret";
    };
  };

  # Layer 3: High-level application declarations
  applications = {
    web-app = {
      name = "web-app";
      image = "nginx:latest";
      replicas = 3;
      ports = [ 8080 ];
      
      compliance = {
        framework = "SOC2";
        level = "high";
        owner = "platform-team";
        dataClassification = "internal";
      };

      # This app depends on the database
      dependencies = [ "postgres" ];

      # Resource constraints
      resources = {
        limits = {
          cpu = "500m";
          memory = "512Mi";
        };
        requests = {
          cpu = "100m";
          memory = "128Mi";
        };
      };
    };

    postgres = {
      name = "postgres";
      image = "postgres:14-alpine";
      replicas = 1;
      ports = [ 5432 ];
      
      compliance = {
        framework = "SOC2";
        level = "high";
        owner = "data-team";
        dataClassification = "confidential";
        auditRequired = true;
      };

      # Postgres doesn't have external dependencies
      dependencies = [];

      resources = {
        limits = {
          cpu = "2000m";
          memory = "4Gi";
        };
        requests = {
          cpu = "1000m";
          memory = "2Gi";
        };
      };

      # External Secret for postgres password
      secrets = {
        password = {
          backend = "external-secret";
          secretStore = "vault";
          secretKey = "postgres-password";
        };
      };
    };
  };
}
