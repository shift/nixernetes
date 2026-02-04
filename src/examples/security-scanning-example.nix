# Security Scanning Examples for Nixernetes
#
# Production-ready examples demonstrating:
# - Container image scanning with Trivy
# - Dependency vulnerability detection with Snyk
# - Runtime security monitoring with Falco
# - Complete orchestration workflow

{ lib }:

let
  securityScanning = import ../src/lib/security-scanning.nix { inherit lib; };

  # Example 1: Microservices application images
  microservicesImages = [
    "nginx:1.24"
    "postgres:15"
    "redis:7.0"
    "python:3.11"
    "node:20"
    "golang:1.21"
  ];

  # Example 2: Application manifests
  applicationManifests = [
    { 
      type = "npm";
      "package.json" = { dependencies = { react = "18.2"; }; };
      "package-lock.json" = {};
    }
    {
      type = "python";
      "requirements.txt" = {};
      "Pipfile" = {};
    }
    {
      type = "maven";
      "pom.xml" = {};
    }
  ];

in
{
  # Example 1: Container Image Security Scanning
  containerImageScan = {
    name = "container-image-security-scan";
    description = "Scan microservices container images for vulnerabilities";

    images = microservicesImages;

    # Trivy scan with security focus
    trivyScan = securityScanning.trivyScan {
      images = microservicesImages;
      config = {
        severityFilter = [ "CRITICAL" "HIGH" "MEDIUM" ];
        scanType = "image";
        ignoreUnfixed = false;
        timeout = "5m";
      };
    };

    # Analysis results
    vulnerabilityAnalysis = {
      totalImages = lib.length microservicesImages;
      scannedImages = trivyScan.statistics.scannedImages;
      cleanImages = trivyScan.statistics.cleanImages;
      riskLevel = trivyScan.riskAssessment.overallRisk;
      remediationNeeded = trivyScan.riskAssessment.remediationRequired;
    };

    # Risk summary
    riskSummary = trivyScan.riskAssessment;

    # Remediation plan
    remediationSteps = [
      {
        priority = "IMMEDIATE";
        action = "Patch critical vulnerabilities";
        images = if trivyScan.riskAssessment.criticalCount > 0 then
          [ /* affected images */ ]
        else
          [];
        timeline = "24 hours";
      }
      {
        priority = "HIGH";
        action = "Update vulnerable packages";
        timeline = "1 week";
      }
    ];
  };

  # Example 2: Dependency Vulnerability Scanning
  dependencySecurityScan = {
    name = "dependency-security-scan";
    description = "Scan application dependencies for known vulnerabilities";

    manifests = applicationManifests;

    # Snyk scan
    snykScan = securityScanning.snykScan {
      inherit applicationManifests;
      config = {
        scanType = [ "dependencies" "configuration" ];
        severity = "high";
        failOn = "high";
        format = "json";
      };
    };

    # By manifest type
    byManifestType = snykScan.byType;

    # Risk assessment
    riskAssessment = snykScan.riskAssessment;

    # Vulnerability summary
    vulnerabilitySummary = {
      manifestsScanned = snykScan.statistics.manifestsScanned;
      cleanManifests = snykScan.statistics.cleanManifests;
      vulnerableManifests = snykScan.aggregated.manifestsWithVulnerabilities;
      patchableVulnerabilities = snykScan.aggregated.patchableVulnerabilities;
      licenseIssues = snykScan.aggregated.licenseIssues;
    };

    # Remediation
    remediationPlan = snykScan.remediationPlan;
  };

  # Example 3: Runtime Security Configuration
  runtimeSecurityMonitoring = {
    name = "falco-runtime-security";
    description = "Configure Falco for continuous runtime security monitoring";

    # Custom rules
    customRules = {
      malicious_behavior = [
        {
          name = "suspicious_process_execution";
          description = "Detect suspicious process execution";
          severity = "CRITICAL";
        }
        {
          name = "unauthorized_network_access";
          description = "Detect unauthorized network access";
          severity = "HIGH";
        }
      ];
      data_exfiltration = [
        {
          name = "database_export";
          description = "Detect potential database exports";
          severity = "CRITICAL";
        }
      ];
    };

    # Falco configuration
    falcoConfig = securityScanning.falcoMonitoring {
      rules = customRules;
      config = {
        rulesEnabled = [ "malicious_behavior" "data_exfiltration" "privilege_escalation" ];
        sensitivityLevel = "high";
        alertThreshold = "high";
      };
    };

    # Deployment summary
    deployment = {
      daemonset = {
        name = "falco";
        namespace = "falco";
        image = "falcosecurity/falco:latest";
        privileged = true;
      };
      totalRules = falcoConfig.statistics.totalRules;
      behaviorPolicies = lib.length falcoConfig.behaviorPolicies;
    };

    # Alert configuration
    alerting = {
      channels = [ "syslog" "slack" "pagerduty" ];
      severityMapping = {
        CRITICAL = "P1";
        HIGH = "P2";
        MEDIUM = "P3";
      };
    };
  };

  # Example 4: Complete Security Orchestration
  completeSecurityOrchestration = {
    name = "production-security-orchestration";
    description = "Full security scanning pipeline for production";

    scanConfigurations = [
      {
        type = "trivy";
        name = "image-scanning";
        target = "all-container-images";
        frequency = "daily";
        severity = "high";
      }
      {
        type = "snyk";
        name = "dependency-scanning";
        target = "all-manifests";
        frequency = "weekly";
        severity = "medium";
      }
      {
        type = "falco";
        name = "runtime-monitoring";
        target = "all-clusters";
        frequency = "continuous";
      }
    ];

    # Orchestration configuration
    orchestration = securityScanning.securityOrchestration {
      scanConfigs = [
        { type = "trivy"; target = "images"; }
        { type = "snyk"; target = "dependencies"; }
      ];
      
      config = {
        schedulingPolicy = "parallel";
        failurePolicy = "alert";
        scanSchedule = "0 2 * * *";
        retentionDays = 30;
        reportFormat = "html";
        dashboardEnabled = true;
        alertingEnabled = true;
        approvalRequired = true;
      };
    };

    # Pipeline details
    pipeline = {
      stages = orchestration.stages;
      steps = lib.length orchestration.pipeline;
      estimatedDuration = orchestration.statistics.estimatedDuration;
    };

    # Reporting setup
    reporting = {
      formats = [ "json" "html" "pdf" "sarif" ];
      recipients = [ "security-team@company.com" ];
      frequency = "daily";
      includeMetrics = true;
      includeTrends = true;
    };

    # Compliance tracking
    complianceTracking = orchestration.complianceTracking;
  };

  # Example 5: Security Report Generation
  securityReportingExample = {
    name = "security-report-generation";
    description = "Generate comprehensive security reports";

    # Scan results
    scanResults = [
      securityScanning.trivyScan {
        images = microservicesImages;
      }
      securityScanning.snykScan {
        manifests = applicationManifests;
      }
    ];

    # Generate report
    report = securityScanning.generateSecurityReport {
      scans = scanResults;
      config = {
        includeDetails = true;
        includeTrends = true;
        includeRecommendations = true;
        severityThreshold = "medium";
      };
    };

    # Report summary
    summary = report.summary;

    # Compliance status
    complianceStatus = report.complianceStatus;

    # Remediation plan
    remediationPlan = report.remediationPlan;

    # Key metrics
    metrics = {
      totalVulnerabilities = report.summary.totalVulnerabilities;
      criticalCount = report.summary.criticalCount;
      highCount = report.summary.highCount;
      riskScore = report.summary.riskScore;
      overallStatus = report.summary.overallStatus;
    };
  };

  # Example 6: CI/CD Integration
  cicdIntegration = {
    name = "ci-cd-security-gates";
    description = "Security scanning in CI/CD pipeline";

    # Pre-deployment checks
    preDeploymentChecks = {
      stage = "security-scan";
      timeout = "30m";
      
      steps = [
        {
          name = "scan-images";
          command = "trivy scan --severity HIGH,CRITICAL $IMAGE";
          failOn = "CRITICAL";
        }
        {
          name = "scan-dependencies";
          command = "snyk test --severity=high";
          failOn = "vulnerabilities";
        }
        {
          name = "generate-report";
          command = "security-report --output html";
        }
      ];
    };

    # Deployment gate
    deploymentGate = {
      conditions = [
        "trivy_scan_passed";
        "snyk_test_passed";
        "security_review_approved";
      ];
      failureAction = "block";
      notificationChannel = "slack";
    };

    # Report publication
    reportPublication = {
      formats = [ "html" "json" "sarif" ];
      publish_to = [ "artifact-store" "security-dashboard" ];
      retention = "30 days";
    };
  };

  # Example 7: Production Security Posture
  productionSecurityPosture = {
    name = "production-security-posture";
    description = "Continuous security posture management";

    # Daily scanning
    dailySecurityScans = {
      schedule = "0 2 * * *";
      
      imageScans = securityScanning.trivyScan {
        images = microservicesImages;
        config = { ignoreUnfixed = false; };
      };
      
      dependencyScans = securityScanning.snykScan {
        manifests = applicationManifests;
      };
    };

    # Continuous monitoring
    continuousMonitoring = securityScanning.falcoMonitoring {
      rules = {};
      config = {
        sensitivityLevel = "high";
        alertThreshold = "high";
      };
    };

    # Weekly trend analysis
    trendAnalysis = {
      period = "7 days";
      metrics = [
        "vulnerability_count";
        "new_vulnerabilities";
        "remediated_vulnerabilities";
        "average_ttm";
      ];
    };

    # Monthly compliance report
    monthlyComplianceReport = {
      frameworks = [ "PCI-DSS" "HIPAA" "SOC2" "ISO27001" ];
      vulnRemediationRate = "95%";
      policyViolations = 2;
      overallCompliance = "92%";
    };
  };

  # Project metrics
  projectMetrics = {
    totalImages = lib.length microservicesImages;
    totalManifests = lib.length applicationManifests;
    falcoRules = 40;
    complianceFrameworks = 4;
    scanningPipelines = 3;
  };
}
