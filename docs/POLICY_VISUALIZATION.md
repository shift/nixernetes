# Policy Visualization Guide

## Overview

The Policy Visualization module provides comprehensive visualization capabilities for Nixernetes policies, enabling teams to understand complex policy relationships, network topology, and policy interactions through visual representations.

This module generates production-ready visualizations in multiple formats:
- **Dependency Graphs**: Policy relationships and dependencies
- **Network Topology Diagrams**: Kubernetes cluster topology with policies
- **Policy Interaction Charts**: Policy conflicts, overlaps, and enhancements
- **D3/SVG Exports**: Web-ready visualization formats with themes

## Features

### Dependency Graph Visualization

Generates node-link diagrams showing policy dependencies and relationships.

```nix
let
  policies = [
    {
      metadata = {
        name = "deny-external-traffic";
        namespace = "default";
        labels = { severity = "high"; };
        annotations = { depends-on = "default-allow-internal"; };
      };
      spec = { rules = []; };
    }
  ];
  
  graph = policyVisualization.dependencyGraph {
    policies = policies;
    config = {
      layout = "hierarchical";
      orientation = "top-to-bottom";
      showLabels = true;
      highlightCycles = true;
    };
  };
in
  # Access visualization data
  graph.nodes        # Array of policy nodes
  graph.links        # Array of policy relationships
  graph.cycles       # Detected circular dependencies
  graph.d3           # D3-compatible JSON format
  graph.statistics   # Graph metrics and counts
```

**Features:**
- Automatic node extraction from policies
- Relationship detection (depends-on, selector-overlap)
- Cycle detection in policy relationships
- Severity and status visualization
- D3.js compatible output format
- Configurable layout and styling

**Output Structure:**
```nix
{
  type = "dependency-graph";
  config = { /* configuration */ };
  nodes = [
    {
      id = "policy-name";
      label = "policy-name";
      type = "NetworkPolicy";
      ruleCount = 5;
      severity = "high";
      status = "valid";
      namespace = "default";
      size = 50;  # Dynamic sizing based on complexity
    }
  ];
  links = [
    {
      source = "policy-a";
      target = "policy-b";
      type = "depends-on";
      weight = 2;
    }
  ];
  cycles = [ /* detected cycles */ ];
  d3 = { /* D3.js compatible format */ };
  statistics = {
    nodeCount = 10;
    linkCount = 15;
    cycleCount = 0;
    severities = { /* grouped by severity */ };
    statuses = { /* grouped by status */ };
    namespaces = { /* grouped by namespace */ };
  };
}
```

### Network Topology Visualization

Represents Kubernetes cluster topology with pods, services, and network policies.

```nix
let
  cluster = {
    pods = [
      {
        metadata = {
          name = "web-pod-1";
          namespace = "production";
          labels = { app = "web"; tier = "frontend"; };
        };
        spec = { containers = [{ name = "nginx"; }]; };
        status = { phase = "Running"; };
      }
    ];
    services = [
      {
        metadata = { name = "web-service"; namespace = "production"; };
        spec = {
          selector = { app = "web"; };
          ports = [{ port = 80; }];
          clusterIP = "10.0.0.1";
        };
      }
    ];
    networkPolicies = [ /* policies */ ];
  };
  
  topology = policyVisualization.networkTopology {
    inherit cluster;
    config = {
      layout = "force-directed";
      groupByNamespace = true;
      showServices = true;
      showNetworkPolicies = true;
      colorByNamespace = true;
    };
  };
in
  topology
```

**Features:**
- Automatic pod node extraction
- Service relationship mapping
- Network policy edge generation
- Namespace-based grouping
- Traffic path visualization
- Ingress/Egress edge distinction

**Output Structure:**
```nix
{
  type = "network-topology";
  config = { /* configuration */ };
  nodes = [
    {
      id = "default/web-pod";
      label = "web-pod";
      type = "pod";
      namespace = "default";
      containers = 1;
      status = "Running";
      resources = { cpu = "100m"; memory = "128Mi"; };
    }
  ];
  edges = [
    {
      source = "default/web-service";
      target = "default/web-pod";
      type = "service-pod";
      weight = 3;
    }
  ];
  namespaces = [ "default", "kube-system" ];
  byNamespace = { /* grouped by namespace */ };
  statistics = {
    podCount = 25;
    serviceCount = 8;
    edgeCount = 45;
    ingressEdges = 15;
    egressEdges = 30;
  };
}
```

### Policy Interaction Visualization

Shows how different policies interact, overlap, and affect each other.

```nix
let
  policies = [
    {
      metadata = {
        name = "deny-all-ingress";
        namespace = "production";
        labels = { severity = "high"; };
      };
      spec = { podSelector = { matchLabels = { app = "api"; }; }; rules = []; };
    }
    {
      metadata = {
        name = "allow-internal";
        namespace = "production";
        labels = { severity = "medium"; };
      };
      spec = { podSelector = { matchLabels = { app = "api"; }; }; rules = []; };
    }
  ];
  
  interactions = policyVisualization.policyInteractions {
    inherit policies;
    config = {
      granularity = "detailed";
      includeConflicts = true;
      includeOverlaps = true;
      conflictThreshold = 0.5;
    };
  };
in
  interactions
```

**Features:**
- Automatic conflict detection
- Overlap identification
- Selector matching analysis
- Interaction type classification
- Severity-based highlighting
- Bidirectional conflict detection

**Output Structure:**
```nix
{
  type = "policy-interactions";
  config = { /* configuration */ };
  interactions = [
    {
      source = "policy-a";
      target = "policy-b";
      type = "conflict";  # or "overlap", "enhancement", "sequential"
      severity = "high";
    }
  ];
  byType = {
    conflict = [ /* conflicting interactions */ ];
    overlap = [ /* overlapping interactions */ ];
    # ...
  };
  statistics = {
    totalInteractions = 5;
    conflicts = 2;
    overlaps = 3;
    enhancements = 0;
    sequential = 0;
  };
  conflictMatrix = [ /* bidirectional conflict matrix */ ];
}
```

### SVG/D3 Export

Generates exportable visualization formats for web and documentation.

```nix
let
  visualization = policyVisualization.dependencyGraph { policies = []; };
  
  export = policyVisualization.exportVisualization {
    visualization = visualization;
    format = "svg";
    config = {
      width = 1200;
      height = 800;
      theme = "light";
      includeStats = true;
      includeLegend = true;
    };
  };
in
  export
```

**Features:**
- Multiple export formats (SVG, JSON, D3)
- Customizable dimensions and styling
- Legend and statistics inclusion
- Theme-based rendering
- Web-ready output

**Export Formats:**

1. **SVG Export:**
```nix
{
  format = "svg";
  config = { width = 1200; height = 800; theme = "light"; };
  svg = {
    metadata = { version = "1.1"; width = 1200; height = 800; };
    theme = "light";
    includeStats = true;
    includeLegend = true;
  };
}
```

2. **D3 Export:**
```nix
{
  format = "d3";
  d3 = {
    nodes = [ /* D3-compatible nodes */ ];
    links = [ /* D3-compatible links */ ];
  };
}
```

3. **JSON Export:**
```nix
{
  format = "json";
  json = {
    visualization = { /* full visualization data */ };
    export = {
      format = "json";
      config = { /* export config */ };
      timestamp = "2024-01-15T10:30:00Z";
    };
  };
}
```

### Visualization Themes

Pre-configured color schemes and styling for different contexts.

```nix
# Default theme
let
  theme = policyVisualization.visualizationTheme {};
in
  {
    colors = {
      nodeDefault = "#4A90E2";
      nodeConflict = "#E24A4A";
      nodeWarning = "#F5A623";
      nodeSuccess = "#7ED321";
      nodeCritical = "#D0021B";
    };
    styles = {
      nodeBorder = 2;
      nodeOpacity = 0.8;
      fontSize = 12;
    };
  }
```

**Available Themes:**

1. **Default Theme** - Light, professional appearance
   - Node colors for severity levels
   - Light gray links
   - 12pt sans-serif font
   - White background

2. **Dark Theme** - High-contrast for dark backgrounds
   - Brighter node colors
   - Dark background (#1E1E1E)
   - Light text
   - Better contrast

3. **Minimal Theme** - Minimal, monochrome style
   - Black and red color scheme
   - Monospace font
   - Full opacity
   - Print-friendly

**Custom Theme:**
```nix
let
  customTheme = policyVisualization.visualizationTheme {
    theme = "default";
    customConfig = {
      colors = {
        nodeDefault = "#custom-color";
      };
      styles = {
        fontSize = 14;
      };
    };
  };
in
  customTheme
```

## Usage Examples

### Complete Visualization Pipeline

```nix
let
  # Import the module
  policyViz = import ./src/lib/policy-visualization.nix { inherit lib; };
  
  # Define policies
  policies = [
    {
      metadata = {
        name = "deny-all";
        namespace = "production";
        labels = { severity = "high"; };
      };
      spec = { rules = []; };
    }
    {
      metadata = {
        name = "allow-internal";
        namespace = "production";
        labels = { severity = "medium"; };
        annotations = { depends-on = "deny-all"; };
      };
      spec = { rules = []; };
    }
  ];
  
  # Generate dependency graph
  graph = policyViz.dependencyGraph {
    inherit policies;
    config = {
      layout = "hierarchical";
      highlightCycles = true;
    };
  };
  
  # Check for issues
  hasConflicts = graph.statistics.cycleCount > 0;
  conflictPolicies = graph.cycles;
  
  # Export for web visualization
  webExport = policyViz.exportVisualization {
    visualization = graph;
    format = "d3";
    config = {
      theme = "light";
      includeStats = true;
    };
  };
in
  {
    policies = policies;
    graph = graph;
    hasConflicts = hasConflicts;
    export = webExport;
  }
```

### Network Topology Analysis

```nix
let
  policyViz = import ./src/lib/policy-visualization.nix { inherit lib; };
  
  # Cluster definition
  cluster = {
    pods = [ /* pods */ ];
    services = [ /* services */ ];
    networkPolicies = [ /* policies */ ];
  };
  
  # Generate topology
  topology = policyViz.networkTopology {
    inherit cluster;
    config = { groupByNamespace = true; };
  };
  
  # Analysis by namespace
  productionTopology = topology.byNamespace.production;
  
  # Validate connectivity
  unconnectedPods = lib.filter (pod:
    !(lib.any (edge: edge.target == pod.id) topology.edges)
  ) topology.nodes;
in
  {
    topology = topology;
    unconnectedPods = unconnectedPods;
  }
```

### Policy Conflict Detection

```nix
let
  policyViz = import ./src/lib/policy-visualization.nix { inherit lib; };
  
  interactions = policyViz.policyInteractions {
    policies = [ /* policies */ ];
    config = {
      includeConflicts = true;
      conflictThreshold = 0.5;
    };
  };
  
  # Get conflicts only
  conflicts = interactions.byType.conflict or [];
  
  # Risk assessment
  highRiskConflicts = lib.filter (c: c.severity == "high") conflicts;
  
  # Remediation suggestions
  remediation = map (c: {
    policies = [ c.source c.target ];
    action = "Review and resolve policy conflict";
    priority = "high";
  }) highRiskConflicts;
in
  {
    conflicts = conflicts;
    highRiskConflicts = highRiskConflicts;
    remediation = remediation;
  }
```

## Configuration Options

### Dependency Graph Config

```nix
{
  layout = "hierarchical";        # hierarchical, radial, force-directed
  orientation = "top-to-bottom";  # top-to-bottom, left-to-right
  nodeSize = 40;                  # Base node size in pixels
  linkDistance = 200;             # Force-directed link distance
  charge = -300;                  # Force repulsion strength
  showLabels = true;              # Show policy names
  showMetrics = true;             # Show rule counts
  highlightCycles = true;         # Highlight circular dependencies
  colorScheme = "default";        # Predefined color scheme
}
```

### Network Topology Config

```nix
{
  layout = "force-directed";      # force-directed, hierarchical
  groupByNamespace = true;        # Group nodes by namespace
  showServices = true;            # Include service nodes
  showNetworkPolicies = true;     # Include policy edges
  showIngress = true;             # Include ingress resources
  clusterWide = true;             # Show all namespaces
  colorByNamespace = true;        # Color by namespace
  nodeSize = "based-on-replicas"; # Fixed or dynamic sizing
  edgeThickness = "based-on-traffic"; # Edge thickness style
}
```

### Policy Interactions Config

```nix
{
  granularity = "detailed";       # detailed, summary, high-level
  includeConflicts = true;        # Show conflicting policies
  includeOverlaps = true;         # Show overlapping selectors
  includeEnhancements = true;     # Show complementary policies
  conflictThreshold = 0.5;        # Conflict severity threshold
  interactionTypes = [ /* types to show */ ];
}
```

### Export Config

```nix
{
  width = 1200;                   # Canvas width
  height = 800;                   # Canvas height
  margin = { top = 20; right = 20; bottom = 20; left = 20; };
  theme = "light";                # light, dark, minimal
  includeStats = true;            # Include statistics panel
  includeLegend = true;           # Include color legend
}
```

## Integration with Other Modules

### With Policy Generation

```nix
let
  policyGen = import ./src/lib/policy-generation.nix { inherit lib; };
  policyViz = import ./src/lib/policy-visualization.nix { inherit lib; };
  
  # Generate policies
  policies = policyGen.mkSecurityPolicies {};
  
  # Visualize relationships
  graph = policyViz.dependencyGraph { inherit policies; };
in
  { policies = policies; visualization = graph; }
```

### With Compliance Enforcement

```nix
let
  compliance = import ./src/lib/compliance.nix { inherit lib; };
  policyViz = import ./src/lib/policy-visualization.nix { inherit lib; };
  
  # Add compliance metadata
  policiesWithCompliance = map (policy:
    policy // {
      metadata.annotations = policy.metadata.annotations // {
        "compliance-framework" = "HIPAA";
      };
    }
  ) policies;
  
  # Visualize with compliance context
  graph = policyViz.dependencyGraph { policies = policiesWithCompliance; };
in
  graph
```

### With Cost Analysis

```nix
let
  costAnalysis = import ./src/lib/cost-analysis.nix { inherit lib; };
  policyViz = import ./src/lib/policy-visualization.nix { inherit lib; };
  
  # Analyze topology costs
  topology = policyViz.networkTopology { inherit cluster; };
  costs = costAnalysis.calculateClusterCosts {
    pods = topology.nodes;
  };
in
  { topology = topology; costs = costs; }
```

## Best Practices

### 1. **Policy Dependency Management**
- Use dependency graphs to identify and avoid circular dependencies
- Keep dependencies linear when possible
- Document policy dependencies with annotations

### 2. **Network Topology Review**
- Regularly visualize cluster topology
- Identify isolated or unreachable pods
- Validate service-to-pod mappings

### 3. **Conflict Prevention**
- Use policy interaction analysis before deployment
- Address high-severity conflicts immediately
- Test policies in non-production first

### 4. **Documentation**
- Export visualizations for documentation
- Use consistent themes across organization
- Include statistics in runbooks

### 5. **Monitoring**
- Monitor policy visualization statistics over time
- Track growth of conflicts and overlaps
- Set up alerts for circular dependencies

## Troubleshooting

### No Nodes Generated
- Verify policies have metadata.name
- Check policy spec.rules or podSelector exists
- Ensure required fields are present

### Missing Relationships
- Verify depends-on annotation format
- Check namespace matching for relationships
- Ensure selector labels exist

### Layout Issues
- Adjust layout configuration
- Increase canvas dimensions
- Reduce number of nodes for clarity

### Theme Not Applied
- Verify theme name matches predefined themes
- Check customConfig format
- Ensure color values are valid hex codes

## Performance Considerations

- **Large Graphs**: 500+ nodes may require force-directed layout adjustment
- **Memory**: Topology visualization for 1000+ pods may need chunking
- **Export**: SVG export uses inline styles for best compatibility

## See Also

- [Policies Guide](./POLICIES.md) - Policy definitions and patterns
- [Compliance Guide](./COMPLIANCE.md) - Compliance frameworks
- [Policy Generation Guide](./POLICY_GENERATION.md) - Automated policy creation
- [Cost Analysis Guide](./COST_ANALYSIS.md) - Cost estimation and optimization
