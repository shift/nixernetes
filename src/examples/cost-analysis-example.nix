# Example: Cost Analysis for Multi-Tier Application
#
# This example shows how to use the cost analysis module to estimate
# costs for the comprehensive multi-tier application deployment.
#
# The deployment includes:
# - Frontend (3 replicas, low resource usage)
# - API Gateway (2 replicas, medium resource usage)
# - PostgreSQL (1 replica, high resource usage)
# - Redis (1 replica, medium resource usage)
# - RabbitMQ (1 replica, medium resource usage)
# - Prometheus (1 replica, high storage usage)
# - Grafana (1 replica, low resource usage)

{ lib }:

let
  costAnalysis = import ../lib/cost-analysis.nix { inherit lib; };

  # Define all deployments with resource specifications
  deployments = {
    frontend = {
      kind = "Deployment";
      metadata.name = "frontend";
      spec = {
        replicas = 3;
        template.spec = {
          containers = [
            {
              name = "nginx";
              image = "nginx:1.24-alpine";
              resources = {
                requests = {
                  cpu = "50m";
                  memory = "64Mi";
                };
                limits = {
                  cpu = "250m";
                  memory = "256Mi";
                };
              };
            }
          ];
        };
      };
    };

    api-gateway = {
      kind = "Deployment";
      metadata.name = "api-gateway";
      spec = {
        replicas = 2;
        template.spec = {
          containers = [
            {
              name = "api";
              image = "node:18-alpine";
              resources = {
                requests = {
                  cpu = "250m";
                  memory = "256Mi";
                };
                limits = {
                  cpu = "500m";
                  memory = "512Mi";
                };
              };
            }
          ];
        };
      };
    };

    database = {
      kind = "StatefulSet";
      metadata.name = "postgres";
      spec = {
        replicas = 1;
        template.spec = {
          containers = [
            {
              name = "postgres";
              image = "postgres:15-alpine";
              resources = {
                requests = {
                  cpu = "500m";
                  memory = "512Mi";
                };
                limits = {
                  cpu = "1000m";
                  memory = "1Gi";
                };
              };
            }
          ];
        };
      };
    };

    redis = {
      kind = "StatefulSet";
      metadata.name = "redis";
      spec = {
        replicas = 1;
        template.spec = {
          containers = [
            {
              name = "redis";
              image = "redis:7-alpine";
              resources = {
                requests = {
                  cpu = "100m";
                  memory = "128Mi";
                };
                limits = {
                  cpu = "250m";
                  memory = "256Mi";
                };
              };
            }
          ];
        };
      };
    };

    rabbitmq = {
      kind = "StatefulSet";
      metadata.name = "rabbitmq";
      spec = {
        replicas = 1;
        template.spec = {
          containers = [
            {
              name = "rabbitmq";
              image = "rabbitmq:3.12-management-alpine";
              resources = {
                requests = {
                  cpu = "250m";
                  memory = "256Mi";
                };
                limits = {
                  cpu = "500m";
                  memory = "512Mi";
                };
              };
            }
          ];
        };
      };
    };

    prometheus = {
      kind = "StatefulSet";
      metadata.name = "prometheus";
      spec = {
        replicas = 1;
        template.spec = {
          containers = [
            {
              name = "prometheus";
              image = "prom/prometheus:latest";
              resources = {
                requests = {
                  cpu = "250m";
                  memory = "512Mi";
                };
                limits = {
                  cpu = "500m";
                  memory = "1Gi";
                };
              };
            }
          ];
        };
      };
    };

    grafana = {
      kind = "Deployment";
      metadata.name = "grafana";
      spec = {
        replicas = 1;
        template.spec = {
          containers = [
            {
              name = "grafana";
              image = "grafana/grafana:latest";
              resources = {
                requests = {
                  cpu = "50m";
                  memory = "128Mi";
                };
                limits = {
                  cpu = "250m";
                  memory = "256Mi";
                };
              };
            }
          ];
        };
      };
    };
  };

  # Cost analysis for AWS
  awsCostSummary = costAnalysis.mkCostSummary {
    inherit deployments;
    provider = "aws";
  };

  # Cost analysis for Azure
  azureCostSummary = costAnalysis.mkCostSummary {
    inherit deployments;
    provider = "azure";
  };

  # Cost analysis for GCP
  gcpCostSummary = costAnalysis.mkCostSummary {
    inherit deployments;
    provider = "gcp";
  };

  # Individual deployment costs
  frontendCost = costAnalysis.mkDeploymentCost {
    replicas = deployments.frontend.spec.replicas;
    template = deployments.frontend.spec.template;
    provider = "aws";
  };

  databaseCost = costAnalysis.mkDeploymentCost {
    replicas = deployments.database.spec.replicas;
    template = deployments.database.spec.template;
    provider = "aws";
  };

  # Optimization recommendations
  recommendations = costAnalysis.mkCostRecommendations {
    inherit deployments;
  };

in
{
  # Cost Analysis Results Summary
  costAnalysis = {
    summary = {
      aws = awsCostSummary;
      azure = azureCostSummary;
      gcp = gcpCostSummary;
    };

    byDeployment = {
      aws = {
        frontend = frontendCost;
        database = databaseCost;
      };
    };

    recommendations = recommendations;

    # Comparison across providers
    comparison = {
      monthly = {
        aws = awsCostSummary.total.monthly;
        azure = azureCostSummary.total.monthly;
        gcp = gcpCostSummary.total.monthly;
      };

      annual = {
        aws = awsCostSummary.total.annual;
        azure = azureCostSummary.total.annual;
        gcp = gcpCostSummary.total.annual;
      };

      # Cost savings compared to AWS
      savings = {
        azure = {
          monthly = awsCostSummary.total.monthly - azureCostSummary.total.monthly;
          annual = awsCostSummary.total.annual - azureCostSummary.total.annual;
          percentage = ((awsCostSummary.total.monthly - azureCostSummary.total.monthly) / awsCostSummary.total.monthly) * 100;
        };
        gcp = {
          monthly = awsCostSummary.total.monthly - gcpCostSummary.total.monthly;
          annual = awsCostSummary.total.annual - gcpCostSummary.total.annual;
          percentage = ((awsCostSummary.total.monthly - gcpCostSummary.total.monthly) / awsCostSummary.total.monthly) * 100;
        };
      };
    };

    # Cost optimization opportunities
    optimizations = {
      highImpact = [
        {
          name = "Monitor database CPU usage";
          description = "PostgreSQL requests 500m CPU but may not need 1000m limit";
          potentialSavings = databaseCost.hourly * 0.1;  # 10% optimization
        }
      ];

      mediumImpact = [
        {
          name = "Use smaller Prometheus instance";
          description = "Prometheus could potentially use smaller disk and memory";
          potentialSavings = frontendCost.hourly * 0.05;  # 5% optimization
        }
      ];

      lowImpact = [
        {
          name = "Right-size API Gateway";
          description = "Consider if 250m CPU request is necessary";
          potentialSavings = frontendCost.hourly * 0.02;  # 2% optimization
        }
      ];
    };
  };

  # Output all deployment specifications for reference
  deployments = deployments;
}
