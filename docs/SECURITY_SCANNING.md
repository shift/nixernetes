# Security Scanning Integration Guide

## Overview

The Security Scanning module provides comprehensive vulnerability and threat detection through integrated scanners, runtime monitoring, and automated orchestration. It coordinates Trivy for image scanning, Snyk for dependency analysis, and Falco for runtime security.

## Features

### Trivy Image Vulnerability Scanning

Scans container images for known vulnerabilities and misconfigurations.

```nix
let
  images = [ "nginx:latest" "postgres:15" "redis:7.0" ];
  
  scan = securityScanning.trivyScan {
    inherit images;
    config = {
      severityFilter = [ "CRITICAL" "HIGH" "MEDIUM" ];
      scanType = "image";
      ignoreUnfixed = false;
      timeout = "5m";
    };
  };
in
  {
    results = scan.results;            # Per-image results
    riskAssessment = scan.riskAssessment;  # Overall risk
    statistics = scan.statistics;      # Metrics and counts
  }
```

**Output Structure:**
```nix
{
  type = "trivy-scan";
  results = [
    {
      image = "nginx:latest";
      vulnerabilities = {
        critical = { count = 0; items = []; };
        high = { count = 0; items = []; };
      };
      summary = { totalVulnerabilities = 0; status = "PASS"; };
    }
  ];
  riskAssessment = {
    totalImages = 3;
    vulnerableImages = 0;
    overallRisk = "LOW";
  };
  statistics = {
    scannedImages = 3;
    cleanImages = 3;
    vulnerabilityDensity = 0.0;
  };
}
```

**Configuration Options:**
- `severityFilter`: Vulnerability severity levels to report
- `scanType`: "image", "filesystem", or "repository"
- `ignoreUnfixed`: Skip vulnerabilities without fixes
- `timeout`: Scan timeout duration

### Snyk Vulnerability Detection

Detects vulnerabilities in dependencies and application code.

```nix
let
  manifests = [
    { "package.json" = {}; }
    { "requirements.txt" = {}; }
    { "pom.xml" = {}; }
  ];
  
  scan = securityScanning.snykScan {
    inherit manifests;
    config = {
      scanType = [ "dependencies" "configuration" "iac" ];
      severity = "high";
      failOn = "high";
      format = "json";
    };
  };
in
  scan
```

**Supported Manifest Types:**
- `npm` - Node.js dependencies
- `python` - Python packages
- `maven` - Java Maven
- `golang` - Go modules
- `docker` - Dockerfiles
- `kubernetes` - K8s manifests

**Risk Assessment:**
```nix
{
  totalManifests = 3;
  vulnerableManifests = 1;
  patchableCount = 5;
  licenseIssuesCount = 2;
  overallRisk = "MEDIUM";
  remediationPossible = true;
}
```

### Falco Runtime Security Monitoring

Detects suspicious runtime behavior and policy violations.

```nix
let
  rules = {
    malicious_behavior = [];
    network_anomaly = [];
    privilege_escalation = [];
    data_exfiltration = [];
  };
  
  monitoring = securityScanning.falcoMonitoring {
    inherit rules;
    config = {
      rulesEnabled = [ "malicious_behavior" "network_anomaly" ];
      sensitivityLevel = "medium";
      alertThreshold = "high";
    };
  };
in
  monitoring
```

**Rule Categories:**
- `malicious_behavior` - Suspicious shell/network execution
- `network_anomaly` - Unusual network connections
- `privilege_escalation` - Privilege boundary violations
- `data_exfiltration` - Sensitive data access

**Deployment:**
```nix
{
  daemonSetConfig = {
    image = "falcosecurity/falco:latest";
    securityContext = { privileged = true; };
    volumeMounts = [
      { name = "docker"; mountPath = "/var/run/docker.sock"; }
      { name = "containerd"; mountPath = "/var/run/containerd"; }
    ];
  };
  namespace = "falco";
}
```

### Security Scanning Orchestration

Coordinates all scanning operations with scheduling and reporting.

```nix
let
  scanConfigs = [
    { type = "trivy"; target = "images"; }
    { type = "snyk"; target = "dependencies"; }
    { type = "falco"; target = "runtime"; }
  ];
  
  orchestration = securityScanning.securityOrchestration {
    inherit scanConfigs;
    config = {
      schedulingPolicy = "sequential";
      failurePolicy = "alert";
      scanSchedule = "0 2 * * *";
      retentionDays = 30;
      approvalRequired = true;
    };
  };
in
  orchestration
```

**Pipeline Stages:**
1. **pre-scan** - Prepare environment
2. **scan** - Run all scanners (parallel/sequential)
3. **analysis** - Aggregate results
4. **reporting** - Generate reports
5. **post-scan** - Cleanup

**Compliance Tracking:**
```nix
{
  frameworks = [ "PCI-DSS" "HIPAA" "SOC2" "ISO27001" "GDPR" ];
  scanCoverage = {
    containerImages = true;
    dependencies = true;
    runtimeBehavior = true;
    policies = true;
  };
  SLAs = {
    critical = "1h";
    high = "4h";
    medium = "24h";
    low = "7d";
  };
}
```

### Security Report Generation

Creates comprehensive vulnerability reports with remediation plans.

```nix
let
  scans = [
    # Scan results from trivy, snyk, falco
  ];
  
  report = securityScanning.generateSecurityReport {
    inherit scans;
    config = {
      includeDetails = true;
      includeTrends = true;
      includeRecommendations = true;
      severityThreshold = "medium";
    };
  };
in
  report
```

**Report Contents:**
```nix
{
  summary = {
    totalVulnerabilities = 42;
    criticalCount = 3;
    highCount = 8;
    riskScore = 45.0;
    overallStatus = "WARNING";
  };
  findings = {
    CRITICAL = [ /* vulnerabilities */ ];
    HIGH = [ /* vulnerabilities */ ];
  };
  recommendations = [ /* remediation steps */ ];
  remediationPlan = {
    priority = "HIGH";
    estimatedEffort = "40-60 hours";
    phases = [ /* phased approach */ ];
  };
  complianceStatus = {
    pciDss = "PARTIAL";
    hipaa = "PARTIAL";
    soc2 = "PARTIAL";
  };
}
```

## Usage Examples

### Complete Security Workflow

```nix
let
  # 1. Scan container images
  images = [ "app:v1.0" "database:v1.0" "cache:v1.0" ];
  trivyScan = securityScanning.trivyScan { inherit images; };
  
  # 2. Scan dependencies
  manifests = [
    { "package.json" = {}; }
    { "requirements.txt" = {}; }
  ];
  snykScan = securityScanning.snykScan { inherit manifests; };
  
  # 3. Setup runtime monitoring
  falcoRules = {
    malicious_behavior = [];
    network_anomaly = [];
  };
  falcoConfig = securityScanning.falcoMonitoring { rules = falcoRules; };
  
  # 4. Orchestrate scans
  scanConfigs = [
    { type = "trivy"; images = images; }
    { type = "snyk"; manifests = manifests; }
  ];
  orchestration = securityScanning.securityOrchestration { inherit scanConfigs; };
  
  # 5. Generate report
  allScans = [ trivyScan snykScan ];
  report = securityScanning.generateSecurityReport { scans = allScans; };
in
  {
    trivyScan = trivyScan;
    snykScan = snykScan;
    falcoConfig = falcoConfig;
    orchestration = orchestration;
    report = report;
    
    summary = {
      trivy_status = trivyScan.riskAssessment.overallRisk;
      snyk_status = snykScan.riskAssessment.overallRisk;
      falco_rules = falcoConfig.statistics.totalRules;
      report_status = report.summary.overallStatus;
    };
  }
```

### CI/CD Integration

```nix
let
  # Pre-deployment scanning
  scans = {
    images = securityScanning.trivyScan { 
      images = [ "myapp:latest" ]; 
    };
    
    dependencies = securityScanning.snykScan {
      manifests = [ /* dependency manifests */ ];
    };
  };
  
  # Check for failures
  canDeploy = 
    scans.images.riskAssessment.overallRisk != "CRITICAL" &&
    scans.dependencies.riskAssessment.overallRisk != "CRITICAL";
in
  {
    can_deploy = canDeploy;
    action = if canDeploy then "PROCEED" else "BLOCK";
    report = securityScanning.generateSecurityReport { 
      scans = [ scans.images scans.dependencies ]; 
    };
  }
```

### Production Security Posture

```nix
let
  securityScanning = import ./src/lib/security-scanning.nix { inherit lib; };
  
  # Continuous scanning orchestration
  continuous_scanning = securityScanning.securityOrchestration {
    scanConfigs = [
      { type = "trivy"; scope = "all-images"; frequency = "daily"; }
      { type = "snyk"; scope = "all-repos"; frequency = "weekly"; }
      { type = "falco"; scope = "all-clusters"; frequency = "continuous"; }
    ];
    
    config = {
      schedulingPolicy = "parallel";
      failurePolicy = "alert";
      scanSchedule = "0 */6 * * *";
      approvalRequired = true;
      automediateEnabled = false;
    };
  };
  
  # Compliance reporting
  compliance_report = securityScanning.generateSecurityReport {
    scans = [ /* all scan results */ ];
    config = {
      includeDetails = true;
      includeTrends = true;
      includeRecommendations = true;
    };
  };
in
  {
    orchestration = continuous_scanning;
    compliance = compliance_report;
  }
```

## Configuration

### Trivy Configuration

```nix
{
  severityFilter = [ "CRITICAL" "HIGH" "MEDIUM" ];
  scanType = "image";           # image, filesystem, repository
  format = "json";               # json, table, sarif, cyclonedx
  ignoreUnfixed = false;         # Skip unfixed vulnerabilities
  skipUpdate = false;            # Skip DB update
  timeout = "5m";                # Scan timeout
  exitCode = 0;                  # Exit code on findings
  cacheTTL = "24h";              # Cache validity
}
```

### Snyk Configuration

```nix
{
  scanType = [ "dependencies" "configuration" "iac" ];
  severity = "high";             # critical, high, medium, low
  failOn = "high";               # Fail threshold
  format = "json";               # Output format
  excludeDevDeps = false;        # Skip dev dependencies
  pythonTargetVersion = "3.10";  # Python version
  enablePatchMerge = true;       # Merge patch suggestions
  timeout = "10m";               # Scan timeout
}
```

### Falco Configuration

```nix
{
  rulesEnabled = [               # Rule categories
    "malicious_behavior"
    "network_anomaly"
    "privilege_escalation"
    "data_exfiltration"
  ];
  sensitivityLevel = "medium";   # low, medium, high, critical
  alertThreshold = "high";       # high, medium, low
  outputFormat = "json";         # Output format
  bufferSize = 8;                # Ring buffer size
  logDriver = "syslog";          # syslog, file, grpc
  grpcPort = 5060;               # gRPC listen port
}
```

### Orchestration Configuration

```nix
{
  schedulingPolicy = "sequential";    # sequential, parallel, staged
  failurePolicy = "alert";            # alert, block, log
  scanSchedule = "0 2 * * *";         # Cron expression
  retentionDays = 30;                 # Result retention
  reportFormat = "html";              # html, pdf, json
  dashboardEnabled = true;            # Enable dashboard
  alertingEnabled = true;             # Enable alerts
  automediateEnabled = false;         # Auto-remediate
  approvalRequired = true;            # Require approval
}
```

## Integration Patterns

### With CI/CD Pipeline

```yaml
# GitHub Actions example
scan:
  trivy-images: |
    nix develop -c security-scan --type trivy --images $IMAGES
  snyk-deps: |
    nix develop -c security-scan --type snyk --manifests $MANIFESTS
  report: |
    nix develop -c security-report --output html
```

### With Kubernetes

```nix
# Deploy Falco monitoring
falcoDeployment = {
  apiVersion = "apps/v1";
  kind = "DaemonSet";
  metadata = { name = "falco"; namespace = "falco"; };
  spec = securityScanning.falcoMonitoring { rules = {}; };
}
```

### With Monitoring Stack

```nix
# Prometheus + Grafana
prometheus_scrape = {
  job_name = "security-scans";
  static_configs = [{
    targets = [ "security-scanner:9090" ];
  }];
}
```

## Best Practices

1. **Regular Scanning** - Run scans on schedule (daily minimum)
2. **Early Detection** - Scan at build time before deployment
3. **Baseline Tracking** - Monitor trends over time
4. **Approval Gates** - Require review before remediation
5. **Inventory Management** - Keep detailed scan history
6. **SLA Compliance** - Set and track remediation SLAs
7. **Team Communication** - Share results with security teams
8. **Continuous Improvement** - Refine rules and policies

## Troubleshooting

### Scanner Not Found
- Verify scanner installation
- Check PATH configuration
- Verify image pull permissions

### Scan Timeouts
- Increase timeout configuration
- Reduce scope of scan
- Check network connectivity

### Missing Vulnerabilities
- Update vulnerability database
- Check DB cache TTL
- Verify scanner version

## See Also

- [Policies Guide](./POLICIES.md)
- [Kyverno Guide](./KYVERNO.md)
- [Compliance Guide](./COMPLIANCE.md)
- [Policy Visualization Guide](./POLICY_VISUALIZATION.md)
