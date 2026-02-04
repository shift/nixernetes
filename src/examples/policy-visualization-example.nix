# Policy Visualization Examples for Nixernetes
#
# Production-ready examples demonstrating:
# - Dependency graph generation
# - Network topology visualization
# - Policy interaction analysis
# - SVG/D3 export with themes

{ lib }:

let
  policyViz = import ../src/lib/policy-visualization.nix { inherit lib; };

  # Example 1: Multi-tier application policies with dependency analysis
  multiTierPolicies = [
    {
      metadata = {
        name = "deny-all-ingress";
        namespace = "production";
        labels = {
          severity = "high";
          tier = "platform";
        };
        annotations = {
          description = "Default deny all ingress traffic";
          "validation-status" = "valid";
        };
      };
      spec = {
        podSelector = {};
        policyTypes = ["Ingress"];
        ingress = [];
        rules = [{} {} {}];
      };
    }

    {
      metadata = {
        name = "allow-frontend-to-api";
        namespace = "production";
        labels = {
          severity = "high";
          tier = "application";
        };
        annotations = {
          description = "Allow frontend pods to access API tier";
          depends-on = "deny-all-ingress";
          "validation-status" = "valid";
        };
      };
      spec = {
        podSelector = { matchLabels = { tier = "api"; }; };
        policyTypes = ["Ingress"];
        ingress = [{
          from = [{ podSelector = { matchLabels = { tier = "frontend"; }; }; }];
          ports = [{ protocol = "TCP"; port = 8080; }];
        }];
        rules = [{} {} {}];
      };
    }

    {
      metadata = {
        name = "allow-api-to-database";
        namespace = "production";
        labels = {
          severity = "high";
          tier = "application";
        };
        annotations = {
          description = "Allow API pods to access database";
          depends-on = "deny-all-ingress";
          "validation-status" = "valid";
        };
      };
      spec = {
        podSelector = { matchLabels = { tier = "database"; }; };
        policyTypes = ["Ingress"];
        ingress = [{
          from = [{ podSelector = { matchLabels = { tier = "api"; }; }; }];
          ports = [{ protocol = "TCP"; port = 5432; }];
        }];
        rules = [{} {} {} {}];
      };
    }

    {
      metadata = {
        name = "allow-external-to-frontend";
        namespace = "production";
        labels = {
          severity = "medium";
          tier = "application";
        };
        annotations = {
          description = "Allow external traffic to frontend";
          depends-on = "deny-all-ingress";
          "validation-status" = "valid";
        };
      };
      spec = {
        podSelector = { matchLabels = { tier = "frontend"; }; };
        policyTypes = ["Ingress"];
        ingress = [{
          from = [{ namespaceSelector = { matchLabels = { role = "ingress"; }; }; }];
          ports = [{ protocol = "TCP"; port = 80; } { protocol = "TCP"; port = 443; }];
        }];
        rules = [{} {} {}];
      };
    }

    {
      metadata = {
        name = "allow-monitoring-scrape";
        namespace = "production";
        labels = {
          severity = "low";
          tier = "monitoring";
        };
        annotations = {
          description = "Allow monitoring system to scrape metrics";
          "validation-status" = "valid";
        };
      };
      spec = {
        podSelector = {};
        policyTypes = ["Ingress"];
        ingress = [{
          from = [{ namespaceSelector = { matchLabels = { name = "monitoring"; }; }; }];
          ports = [{ protocol = "TCP"; port = 9090; }];
        }];
        rules = [{}];
      };
    }

    {
      metadata = {
        name = "allow-dns-queries";
        namespace = "production";
        labels = {
          severity = "low";
          tier = "platform";
        };
        annotations = {
          description = "Allow DNS queries to kube-dns";
          "validation-status" = "valid";
        };
      };
      spec = {
        podSelector = {};
        policyTypes = ["Egress"];
        egress = [{
          to = [{ namespaceSelector = { matchLabels = { name = "kube-system"; }; }; }];
          ports = [{ protocol = "UDP"; port = 53; }];
        }];
        rules = [{}];
      };
    }
  ];

  # Example 2: Production cluster topology
  productionCluster = {
    pods = [
      {
        metadata = { name = "frontend-1"; namespace = "production"; labels = { app = "web"; tier = "frontend"; }; };
        spec = { containers = [{ name = "nginx"; }]; };
        status = { phase = "Running"; };
      }
      {
        metadata = { name = "frontend-2"; namespace = "production"; labels = { app = "web"; tier = "frontend"; }; };
        spec = { containers = [{ name = "nginx"; }]; };
        status = { phase = "Running"; };
      }
      {
        metadata = { name = "api-1"; namespace = "production"; labels = { app = "api"; tier = "api"; }; };
        spec = { containers = [{ name = "app"; } { name = "sidecar"; }]; };
        status = { phase = "Running"; };
      }
      {
        metadata = { name = "api-2"; namespace = "production"; labels = { app = "api"; tier = "api"; }; };
        spec = { containers = [{ name = "app"; } { name = "sidecar"; }]; };
        status = { phase = "Running"; };
      }
      {
        metadata = { name = "db-1"; namespace = "production"; labels = { app = "postgres"; tier = "database"; }; };
        spec = { containers = [{ name = "postgres"; }]; };
        status = { phase = "Running"; };
      }
      {
        metadata = { name = "cache-1"; namespace = "production"; labels = { app = "redis"; tier = "cache"; }; };
        spec = { containers = [{ name = "redis"; }]; };
        status = { phase = "Running"; };
      }
      {
        metadata = { name = "prometheus"; namespace = "monitoring"; labels = { app = "prometheus"; }; };
        spec = { containers = [{ name = "prometheus"; }]; };
        status = { phase = "Running"; };
      }
    ];

    services = [
      {
        metadata = { name = "frontend"; namespace = "production"; };
        spec = {
          selector = { app = "web"; tier = "frontend"; };
          ports = [{ port = 80; targetPort = 8080; } { port = 443; targetPort = 8443; }];
          clusterIP = "10.0.0.10";
        };
      }
      {
        metadata = { name = "api"; namespace = "production"; };
        spec = {
          selector = { app = "api"; tier = "api"; };
          ports = [{ port = 8080; targetPort = 8080; }];
          clusterIP = "10.0.0.20";
        };
      }
      {
        metadata = { name = "postgres"; namespace = "production"; };
        spec = {
          selector = { app = "postgres"; tier = "database"; };
          ports = [{ port = 5432; targetPort = 5432; }];
          clusterIP = "10.0.0.30";
        };
      }
      {
        metadata = { name = "redis"; namespace = "production"; };
        spec = {
          selector = { app = "redis"; tier = "cache"; };
          ports = [{ port = 6379; targetPort = 6379; }];
          clusterIP = "10.0.0.40";
        };
      }
    ];

    networkPolicies = multiTierPolicies;
  };

in
{
  # Example 1: Dependency graph for policy analysis
  dependencyGraphExample = {
    name = "production-policies-dependency-graph";
    description = "Dependency graph showing multi-tier application policy relationships";

    policies = multiTierPolicies;

    graph = policyViz.dependencyGraph {
      policies = multiTierPolicies;
      config = {
        layout = "hierarchical";
        orientation = "top-to-bottom";
        showLabels = true;
        showMetrics = true;
        highlightCycles = true;
      };
    };

    # Analysis results
    summary = {
      totalPolicies = lib.length multiTierPolicies;
      highSeverity = lib.length (lib.filter (p: p.metadata.labels.severity == "high") multiTierPolicies);
      mediumSeverity = lib.length (lib.filter (p: p.metadata.labels.severity == "medium") multiTierPolicies);
      lowSeverity = lib.length (lib.filter (p: p.metadata.labels.severity == "low") multiTierPolicies);
      hasCycles = (lib.length (graph.cycles or [])) > 0;
    };

    # Export for web visualization
    webExport = policyViz.exportVisualization {
      visualization = graph;
      format = "d3";
      config = { theme = "light"; includeStats = true; };
    };

    # Export as SVG for documentation
    svgExport = policyViz.exportVisualization {
      visualization = graph;
      format = "svg";
      config = {
        width = 1200;
        height = 800;
        theme = "default";
        includeStats = true;
        includeLegend = true;
      };
    };
  };

  # Example 2: Network topology visualization
  networkTopologyExample = {
    name = "production-cluster-topology";
    description = "Network topology for production cluster with pods and services";

    cluster = productionCluster;

    topology = policyViz.networkTopology {
      inherit (productionCluster) cluster;
      config = {
        layout = "force-directed";
        groupByNamespace = true;
        showServices = true;
        showNetworkPolicies = true;
        colorByNamespace = true;
      };
    };

    # Analysis by tier
    byTier = lib.groupBy (n: 
      if n.type == "pod" then
        n.labels.tier or "unknown"
      else if n.type == "service" then
        "service"
      else
        "other"
    ) topology.nodes;

    # Service connectivity analysis
    serviceConnectivity = lib.map (svc: {
      service = svc.id;
      targets = lib.filter (edge:
        edge.source == svc.id && edge.type == "service-pod"
      ) topology.edges;
    }) (lib.filter (n: n.type == "service") topology.nodes);

    # Export for visualization
    d3Export = policyViz.exportVisualization {
      visualization = topology;
      format = "d3";
      config = { theme = "light"; };
    };
  };

  # Example 3: Policy interaction analysis
  policyInteractionsExample = {
    name = "production-policy-interactions";
    description = "Analysis of policy conflicts and overlaps";

    policies = multiTierPolicies;

    interactions = policyViz.policyInteractions {
      policies = multiTierPolicies;
      config = {
        granularity = "detailed";
        includeConflicts = true;
        includeOverlaps = true;
        conflictThreshold = 0.5;
      };
    };

    # Risk assessment
    highRiskConflicts = lib.filter (i: i.severity == "high") 
      (interactions.byType.conflict or []);

    mediumRiskConflicts = lib.filter (i: i.severity == "medium")
      (interactions.byType.conflict or []);

    # Remediation plan
    remediationPlan = lib.map (conflict: {
      policies = [ conflict.source conflict.target ];
      severity = conflict.severity;
      action = "Review and resolve policy conflict";
      priority = if conflict.severity == "high" then "immediate" else "scheduled";
    }) highRiskConflicts;
  };

  # Example 4: Visualization with themes
  themedVisualizationExample = {
    name = "policy-visualization-themes";
    description = "Demonstration of different visualization themes";

    # Light theme for web display
    lightTheme = policyViz.visualizationTheme { theme = "default"; };

    # Dark theme for documentation
    darkTheme = policyViz.visualizationTheme { theme = "dark"; };

    # Minimal theme for printing
    minimalTheme = policyViz.visualizationTheme { theme = "minimal"; };

    # Custom theme
    customTheme = policyViz.visualizationTheme {
      theme = "default";
      customConfig = {
        colors = {
          nodeDefault = "#0066CC";
          nodeConflict = "#CC0000";
          nodeWarning = "#FF9900";
        };
        styles = {
          fontSize = 13;
          linkStrokeWidth = 2;
        };
      };
    };
  };

  # Example 5: Complete production workflow
  productionWorkflow = {
    name = "complete-policy-visualization-workflow";
    description = "End-to-end policy visualization for production deployment";

    # Step 1: Generate dependency graph
    step1_dependencyGraph = policyViz.dependencyGraph {
      policies = multiTierPolicies;
    };

    # Step 2: Check for cycles
    step2_cycleCheck = {
      hasCycles = (lib.length step1_dependencyGraph.cycles) > 0;
      cycles = step1_dependencyGraph.cycles;
      status = if step1_dependencyGraph.statistics.cycleCount == 0 then "OK" else "NEEDS_REVIEW";
    };

    # Step 3: Analyze interactions
    step3_interactions = policyViz.policyInteractions {
      policies = multiTierPolicies;
    };

    # Step 4: Generate topology
    step4_topology = policyViz.networkTopology {
      cluster = productionCluster;
    };

    # Step 5: Validate connectivity
    step5_connectivity = {
      totalNodes = step4_topology.statistics.podCount + step4_topology.statistics.serviceCount;
      totalConnections = step4_topology.statistics.edgeCount;
      ingressPolicies = step4_topology.statistics.ingressEdges;
      egressPolicies = step4_topology.statistics.egressEdges;
      healthStatus = "OK";
    };

    # Step 6: Export for documentation
    step6_exports = {
      dependencyGraphSVG = policyViz.exportVisualization {
        visualization = step1_dependencyGraph;
        format = "svg";
      };
      topologyD3 = policyViz.exportVisualization {
        visualization = step4_topology;
        format = "d3";
      };
      interactionsJSON = policyViz.exportVisualization {
        visualization = step3_interactions;
        format = "json";
      };
    };

    # Final summary
    summary = {
      policies = lib.length multiTierPolicies;
      conflicts = lib.length (step3_interactions.byType.conflict or []);
      topologyNodes = step4_topology.statistics.podCount + step4_topology.statistics.serviceCount;
      readyForDeployment = 
        step2_cycleCheck.status == "OK" &&
        (lib.length (step3_interactions.byType.conflict or [])) == 0;
      recommendedActions = [
        "Review dependency graph for complexity"
        "Validate network connectivity"
        "Test policies in staging environment"
        "Document policy relationships"
      ];
    };
  };

  # Summary statistics
  projectMetrics = {
    totalPolicies = lib.length multiTierPolicies;
    policyTypes = lib.groupBy (p: p.kind or "NetworkPolicy") multiTierPolicies;
    clusterSize = {
      pods = lib.length productionCluster.pods;
      services = lib.length productionCluster.services;
      namespaces = lib.length (lib.unique (
        lib.map (p: p.metadata.namespace) productionCluster.pods
      ));
    };
  };
}
