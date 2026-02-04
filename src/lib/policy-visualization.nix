# Policy Visualization Module for Nixernetes
#
# This module provides comprehensive policy visualization capabilities:
# - Dependency graph generation for policy relationships
# - Network topology diagrams for Kubernetes clusters
# - Policy interaction visualization
# - D3/SVG export support
# - Configuration and styling system

{ lib }:

let
  inherit (lib) mkOption types;

in
{
  options.policyVisualization = mkOption {
    type = types.submodule {
      options = {
        # Visualization types
        graph = mkOption {
          type = types.attrs;
          default = {};
          description = "Dependency graph visualization configuration";
        };

        topology = mkOption {
          type = types.attrs;
          default = {};
          description = "Network topology visualization configuration";
        };

        interactions = mkOption {
          type = types.attrs;
          default = {};
          description = "Policy interaction visualization configuration";
        };

        styling = mkOption {
          type = types.attrs;
          default = {};
          description = "Global styling and theme configuration";
        };
      };
    };
    default = {};
    description = "Policy visualization settings and configurations";
  };

  config = {
    # Dependency Graph Visualization
    # Generates node-link diagrams showing policy dependencies and relationships
    dependencyGraph = { policies, config ? {} }:
      let
        defaultConfig = {
          layout = "hierarchical";
          orientation = "top-to-bottom";
          nodeSize = 40;
          linkDistance = 200;
          charge = -300;
          showLabels = true;
          showMetrics = true;
          highlightCycles = true;
          colorScheme = "default";
        } // config;

        # Extract nodes from policies
        extractNodes = builtins.map (policy:
          let
            ruleCount = lib.length (policy.spec.rules or []);
            severity = policy.metadata.labels."severity" or "medium";
            status = if policy.metadata.annotations."validation-status" == "valid" then "valid" else "invalid";
          in
          {
            id = policy.metadata.name;
            label = policy.metadata.name;
            type = policy.kind;
            ruleCount = ruleCount;
            severity = severity;
            status = status;
            namespace = policy.metadata.namespace or "default";
            size = defaultConfig.nodeSize + (ruleCount * 2);
          }
        ) (if builtins.isList policies then policies else [ policies ]);

        # Extract relationships between policies
        extractLinks = builtins.concatMap (policy:
          let
            policyName = policy.metadata.name;
            annotations = policy.metadata.annotations or {};
            relatedPolicies = lib.optional (annotations ? "depends-on") 
              (lib.strings.splitString "," annotations."depends-on");
            
            relatedSelectors = lib.optional (annotations ? "selector-overlap")
              (lib.strings.splitString "," annotations."selector-overlap");
          in
          (builtins.map (related: {
            source = policyName;
            target = related;
            type = "depends-on";
            weight = 2;
          }) (lib.flatten relatedPolicies)) ++
          (builtins.map (overlap: {
            source = policyName;
            target = overlap;
            type = "selector-overlap";
            weight = 1;
          }) (lib.flatten relatedSelectors))
        ) (if builtins.isList policies then policies else [ policies ]);

        # Detect cycles in policy relationships
        detectCycles = links:
          let
            # Build adjacency list
            buildAdjacency = lib.foldl' (acc: link:
              acc // {
                ${link.source} = (acc.${link.source} or []) ++ [ link.target ];
              }
            ) {} links;

            # DFS to detect cycles
            detectFromNode = node: visited: recStack:
              if builtins.elem node visited then
                if builtins.elem node recStack then
                  [ node ]  # Found cycle
                else
                  []
              else
                let
                  neighbors = buildAdjacency.${node} or [];
                  results = builtins.map (neighbor:
                    detectFromNode neighbor (visited ++ [ node ]) (recStack ++ [ node ])
                  ) neighbors;
                in
                lib.flatten results;

            allNodes = builtins.attrNames buildAdjacency;
            cycles = builtins.concatMap (node: detectFromNode node [] []) allNodes;
          in
          lib.unique cycles;

        cycles = if defaultConfig.highlightCycles then detectCycles extractLinks else [];
      in
      {
        type = "dependency-graph";
        config = defaultConfig;
        nodes = extractNodes;
        links = extractLinks;
        cycles = cycles;
        
        # D3 JSON format for visualization
        d3 = {
          nodes = builtins.map (node:
            node // {
              isCycle = builtins.elem node.id cycles;
              group = node.severity;
            }
          ) extractNodes;
          
          links = builtins.map (link:
            link // {
              value = link.weight;
            }
          ) extractLinks;
        };

        # Statistics
        statistics = {
          nodeCount = lib.length extractNodes;
          linkCount = lib.length extractLinks;
          cycleCount = lib.length cycles;
          severities = lib.groupBy (n: n.severity) extractNodes;
          statuses = lib.groupBy (n: n.status) extractNodes;
          namespaces = lib.groupBy (n: n.namespace) extractNodes;
        };
      };

    # Network Topology Visualization
    # Represents Kubernetes cluster topology with pods, services, and network policies
    networkTopology = { cluster, config ? {} }:
      let
        defaultConfig = {
          layout = "force-directed";
          groupByNamespace = true;
          showServices = true;
          showNetworkPolicies = true;
          showIngress = true;
          clusterWide = true;
          colorByNamespace = true;
          nodeSize = "based-on-replicas";
          edgeThickness = "based-on-traffic";
        } // config;

        # Extract namespaces
        namespaces = lib.unique (
          builtins.concatMap (pod: [ (pod.metadata.namespace or "default") ])
          (cluster.pods or [])
        );

        # Build pod nodes
        podNodes = builtins.map (pod:
          let
            ns = pod.metadata.namespace or "default";
            containers = lib.length (pod.spec.containers or []);
            status = pod.status.phase or "Unknown";
          in
          {
            id = "${ns}/${pod.metadata.name}";
            label = pod.metadata.name;
            type = "pod";
            namespace = ns;
            containers = containers;
            status = status;
            replicas = 1;
            resources = {
              cpu = lib.concatMapStringsSep "," 
                (c: c.resources.requests.cpu or "100m") 
                (pod.spec.containers or []);
              memory = lib.concatMapStringsSep ","
                (c: c.resources.requests.memory or "128Mi")
                (pod.spec.containers or []);
            };
          }
        ) (cluster.pods or []);

        # Build service nodes
        serviceNodes = builtins.map (svc:
          let
            ns = svc.metadata.namespace or "default";
            selectorLabels = svc.spec.selector or {};
            ports = lib.length (svc.spec.ports or []);
          in
          {
            id = "${ns}/${svc.metadata.name}";
            label = svc.metadata.name;
            type = "service";
            namespace = ns;
            selectorLabels = selectorLabels;
            ports = ports;
            clusterIP = svc.spec.clusterIP or "None";
          }
        ) (cluster.services or []);

        # Build service-to-pod edges
        servicePodEdges = builtins.concatMap (svc:
          let
            ns = svc.metadata.namespace or "default";
            svcName = svc.metadata.name;
            selectorLabels = svc.spec.selector or {};
            
            matchingPods = builtins.filter (pod:
              let
                podLabels = pod.metadata.labels or {};
                podNs = pod.metadata.namespace or "default";
              in
              podNs == ns && 
              lib.all (label: podLabels ? ${label}) (builtins.attrNames selectorLabels)
            ) (cluster.pods or []);
          in
          builtins.map (pod:
            {
              source = "${ns}/${svc.metadata.name}";
              target = "${ns}/${pod.metadata.name}";
              type = "service-pod";
              weight = 3;
            }
          ) matchingPods
        ) (cluster.services or []);

        # Build network policy edges
        networkPolicyEdges = builtins.concatMap (policy:
          let
            ns = policy.metadata.namespace or "default";
            policySpec = policy.spec;
            
            # Extract pod selectors
            ingressRules = policySpec.ingress or [];
            egressRules = policySpec.egress or [];
            
            # Get affected pods
            podSelector = policySpec.podSelector or { matchLabels = {}; };
            affectedPods = builtins.filter (pod:
              let
                podLabels = pod.metadata.labels or {};
                podNs = pod.metadata.namespace or "default";
                matchLabels = podSelector.matchLabels or {};
              in
              podNs == ns &&
              lib.all (label: podLabels ? ${label}) (builtins.attrNames matchLabels)
            ) (cluster.pods or []);
          in
          builtins.concatMap (pod:
            (builtins.map (rule:
              {
                source = if rule.from != null then "external" else "${ns}/${pod.metadata.name}";
                target = "${ns}/${pod.metadata.name}";
                type = "ingress";
                policy = policy.metadata.name;
                ports = rule.ports or [];
              }
            ) ingressRules) ++
            (builtins.map (rule:
              {
                source = "${ns}/${pod.metadata.name}";
                target = if rule.to != null then "external" else "internal";
                type = "egress";
                policy = policy.metadata.name;
                ports = rule.ports or [];
              }
            ) egressRules)
          ) affectedPods
        ) (cluster.networkPolicies or []);

        # Combine all edges
        allEdges = servicePodEdges ++ networkPolicyEdges;
      in
      {
        type = "network-topology";
        config = defaultConfig;
        nodes = podNodes ++ serviceNodes;
        edges = allEdges;
        namespaces = namespaces;

        # Grouped by namespace
        byNamespace = lib.foldl' (acc: ns:
          acc // {
            ${ns} = {
              pods = builtins.filter (p: p.namespace == ns) podNodes;
              services = builtins.filter (s: s.namespace == ns) serviceNodes;
              edges = builtins.filter (e: 
                lib.hasPrefix "${ns}/" e.source || lib.hasPrefix "${ns}/" e.target
              ) allEdges;
            };
          }
        ) {} namespaces;

        # Statistics
        statistics = {
          podCount = lib.length podNodes;
          serviceCount = lib.length serviceNodes;
          edgeCount = lib.length allEdges;
          namespaceCount = lib.length namespaces;
          ingressEdges = lib.length (builtins.filter (e: e.type == "ingress") allEdges);
          egressEdges = lib.length (builtins.filter (e: e.type == "egress") allEdges);
          servicePodEdges = lib.length (builtins.filter (e: e.type == "service-pod") allEdges);
        };
      };

    # Policy Interaction Visualization
    # Shows how different policies interact, overlap, and affect each other
    policyInteractions = { policies, config ? {} }:
      let
        defaultConfig = {
          granularity = "detailed";  # detailed, summary, high-level
          includeConflicts = true;
          includeOverlaps = true;
          includeEnhancements = true;
          conflictThreshold = 0.5;
          interactionTypes = [ "conflict" "overlap" "enhancement" "sequential" ];
        } // config;

        # Extract policy selectors
        extractSelector = policy:
          let
            spec = policy.spec or {};
            podSelector = spec.podSelector or {};
            matchLabels = podSelector.matchLabels or {};
          in
          matchLabels;

        # Check if selectors overlap
        selectorsOverlap = selector1: selector2:
          lib.any (label1: 
            lib.any (label2: label1 == label2) 
            (builtins.attrNames selector2)
          ) (builtins.attrNames selector1);

        # Check if policies conflict
        policiesConflict = policy1: policy2:
          let
            selector1 = extractSelector policy1;
            selector2 = extractSelector policy2;
            rules1 = policy1.spec.rules or [];
            rules2 = policy2.spec.rules or [];
            
            # Simple conflict detection: if they overlap and have opposing rules
            overlap = selectorsOverlap selector1 selector2;
            sameNamespace = 
              (policy1.metadata.namespace or "default") == 
              (policy2.metadata.namespace or "default");
          in
          overlap && sameNamespace;

        # Build interaction matrix
        interactions = builtins.concatMap (policy1:
          let
            name1 = policy1.metadata.name;
          in
          builtins.map (policy2:
            let
              name2 = policy2.metadata.name;
              selector1 = extractSelector policy1;
              selector2 = extractSelector policy2;
              conflicts = policiesConflict policy1 policy2;
              overlaps = selectorsOverlap selector1 selector2;
            in
            {
              source = name1;
              target = name2;
              type = if conflicts then "conflict" else if overlaps then "overlap" else "independent";
              severity = if conflicts then "high" else if overlaps then "medium" else "low";
            }
          ) (builtins.filter (p: p.metadata.name != policy1.metadata.name) 
            (if builtins.isList policies then policies else [ policies ]))
        ) (if builtins.isList policies then policies else [ policies ]);

        # Filter interactions based on config
        filteredInteractions = builtins.filter (interaction:
          (interaction.type == "conflict" && defaultConfig.includeConflicts) ||
          (interaction.type == "overlap" && defaultConfig.includeOverlaps) ||
          (interaction.type == "enhancement" && defaultConfig.includeEnhancements) ||
          (interaction.type == "sequential")
        ) interactions;

        # Group by interaction type
        groupedByType = lib.groupBy (i: i.type) filteredInteractions;
      in
      {
        type = "policy-interactions";
        config = defaultConfig;
        interactions = filteredInteractions;
        
        byType = groupedByType;

        # Statistics
        statistics = {
          totalInteractions = lib.length filteredInteractions;
          conflicts = lib.length (groupedByType.conflict or []);
          overlaps = lib.length (groupedByType.overlap or []);
          enhancements = lib.length (groupedByType.enhancement or []);
          sequential = lib.length (groupedByType.sequential or []);
        };

        # Conflict matrix (for detailed view)
        conflictMatrix = builtins.map (int1:
          builtins.map (int2:
            if int1.source == int2.target && int1.target == int2.source then
              { source = int1.source; target = int1.target; type = "bidirectional-conflict"; }
            else if int1.type == "conflict" && int2.type == "conflict" then
              { source = int1.source; target = int1.target; type = "unidirectional-conflict"; }
            else
              { source = int1.source; target = int1.target; type = "independent"; }
          ) filteredInteractions
        ) filteredInteractions;
      };

    # SVG/D3 Export
    # Generates exportable visualization formats
    exportVisualization = { visualization, format ? "svg", config ? {} }:
      let
        defaultConfig = {
          width = 1200;
          height = 800;
          margin = { top = 20; right = 20; bottom = 20; left = 20; };
          theme = "light";
          includeStats = true;
          includeLegend = true;
        } // config;

        # Generate D3-compatible JSON
        toD3JSON = vis:
          if vis.type == "dependency-graph" then
            vis.d3
          else if vis.type == "network-topology" then
            {
              nodes = vis.nodes;
              links = vis.edges;
            }
          else if vis.type == "policy-interactions" then
            {
              nodes = lib.unique (
                (builtins.map (i: { id = i.source; type = "policy"; }) vis.interactions) ++
                (builtins.map (i: { id = i.target; type = "policy"; }) vis.interactions)
              );
              links = builtins.map (i: {
                source = i.source;
                target = i.target;
                type = i.type;
                value = if i.type == "conflict" then 3 else if i.type == "overlap" then 2 else 1;
              }) vis.interactions;
            }
          else
            { nodes = []; links = []; };

        # Generate SVG metadata
        svgMetadata = {
          version = "1.1";
          width = defaultConfig.width;
          height = defaultConfig.height;
          viewBox = "0 0 ${toString defaultConfig.width} ${toString defaultConfig.height}";
        };
      in
      {
        format = format;
        config = defaultConfig;
        
        d3 = toD3JSON visualization;

        svg = {
          metadata = svgMetadata;
          theme = defaultConfig.theme;
          includeStats = defaultConfig.includeStats;
          includeLegend = defaultConfig.includeLegend;
        };

        # Export as JSON
        json = {
          visualization = visualization;
          export = {
            format = format;
            config = defaultConfig;
            timestamp = "generated";
          };
        };
      };

    # Styling and Theme Configuration
    visualizationTheme = { theme ? "default", customConfig ? {} }:
      let
        baseThemes = {
          default = {
            colors = {
              nodeDefault = "#4A90E2";
              nodeConflict = "#E24A4A";
              nodeWarning = "#F5A623";
              nodeSuccess = "#7ED321";
              nodeCritical = "#D0021B";
              linkDefault = "#CCCCCC";
              linkStrong = "#666666";
              linkWeak = "#EEEEEE";
              background = "#FFFFFF";
              text = "#333333";
            };
            styles = {
              nodeBorder = 2;
              nodeOpacity = 0.8;
              linkOpacity = 0.4;
              linkStrokeWidth = 2;
              fontSize = 12;
              fontFamily = "sans-serif";
            };
          };

          dark = {
            colors = {
              nodeDefault = "#6BB6FF";
              nodeConflict = "#FF6B6B";
              nodeWarning = "#FFD93D";
              nodeSuccess = "#6BCF7F";
              nodeCritical = "#FF5252";
              linkDefault = "#666666";
              linkStrong = "#AAAAAA";
              linkWeak = "#333333";
              background = "#1E1E1E";
              text = "#EEEEEE";
            };
            styles = {
              nodeBorder = 2;
              nodeOpacity = 0.9;
              linkOpacity = 0.3;
              linkStrokeWidth = 2;
              fontSize = 12;
              fontFamily = "sans-serif";
            };
          };

          minimal = {
            colors = {
              nodeDefault = "#000000";
              nodeConflict = "#FF0000";
              nodeWarning = "#FF9900";
              nodeSuccess = "#009900";
              nodeCritical = "#990000";
              linkDefault = "#CCCCCC";
              linkStrong = "#666666";
              linkWeak = "#EEEEEE";
              background = "#FFFFFF";
              text = "#000000";
            };
            styles = {
              nodeBorder = 1;
              nodeOpacity = 1.0;
              linkOpacity = 0.5;
              linkStrokeWidth = 1;
              fontSize = 11;
              fontFamily = "monospace";
            };
          };
        };

        selectedTheme = baseThemes.${theme} or baseThemes.default;
      in
      selectedTheme // customConfig;
  };
}
