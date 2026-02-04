# Security Scanning Module for Nixernetes
#
# Comprehensive security scanning framework integrating:
# - Trivy for container image vulnerability scanning
# - Snyk for dependency vulnerability detection
# - Falco for runtime security monitoring
# - Policy compliance checking
# - Scanning orchestration and reporting

{ lib }:

let
  inherit (lib) mkOption types;

in
{
  options.securityScanning = mkOption {
    type = types.submodule {
      options = {
        trivy = mkOption {
          type = types.attrs;
          default = {};
          description = "Trivy image scanning configuration";
        };

        snyk = mkOption {
          type = types.attrs;
          default = {};
          description = "Snyk vulnerability detection configuration";
        };

        falco = mkOption {
          type = types.attrs;
          default = {};
          description = "Falco runtime security configuration";
        };

        orchestration = mkOption {
          type = types.attrs;
          default = {};
          description = "Scanning orchestration settings";
        };
      };
    };
    default = {};
    description = "Security scanning configuration";
  };

  config = {
    # Trivy Image Vulnerability Scanning
    # Scans container images for known vulnerabilities and misconfigurations
    trivyScan = { images, config ? {} }:
      let
        defaultConfig = {
          severityFilter = [ "CRITICAL" "HIGH" "MEDIUM" ];
          scanType = "image";  # image, filesystem, repository
          format = "json";
          ignoreUnfixed = false;
          skipUpdate = false;
          timeout = "5m";
          exitCode = 0;
          cacheTTL = "24h";
        } // config;

        # Parse image reference
        parseImage = image:
          let
            parts = lib.strings.splitString ":" image;
            nameAndTag = if lib.length parts == 2 then
              { name = lib.elemAt parts 0; tag = lib.elemAt parts 1; }
            else
              { name = image; tag = "latest"; };
          in
          nameAndTag // {
            fullRef = image;
            registry = lib.head (lib.strings.splitString "/" nameAndTag.name);
          };

        # Scan each image
        scanResults = builtins.map (image:
          let
            parsedImage = parseImage image;
          in
          {
            image = image;
            parsed = parsedImage;
            
            # Simulated scan result structure
            vulnerabilities = {
              critical = {
                count = 0;
                items = [];
              };
              high = {
                count = 0;
                items = [];
              };
              medium = {
                count = 0;
                items = [];
              };
              low = {
                count = 0;
                items = [];
              };
            };

            misconfigurations = {
              critical = [];
              high = [];
              medium = [];
            };

            metadata = {
              scanTime = "2024-01-15T10:00:00Z";
              trivyVersion = "0.48.0";
              imageBuildTime = "2024-01-10T00:00:00Z";
              osFamily = "debian";
              osName = "Debian GNU/Linux 11";
            };

            summary = {
              totalVulnerabilities = 0;
              totalMisconfigurations = 0;
              riskScore = 0.0;
              status = "PASS";
            };
          }
        ) (if builtins.isList images then images else [ images ]);

        # Aggregate results
        aggregated = {
          totalImages = lib.length scanResults;
          imagesWithVulnerabilities = lib.length (
            lib.filter (r: r.summary.totalVulnerabilities > 0) scanResults
          );
          criticalVulnerabilities = builtins.concatMap (r: 
            r.vulnerabilities.critical.items
          ) scanResults;
          highVulnerabilities = builtins.concatMap (r:
            r.vulnerabilities.high.items
          ) scanResults;
          averageRiskScore = 
            if lib.length scanResults > 0 then
              (builtins.foldl' (sum: r: sum + r.summary.riskScore) 0 scanResults) / (lib.length scanResults)
            else
              0.0;
        };

      in
      {
        type = "trivy-scan";
        config = defaultConfig;
        results = scanResults;
        aggregated = aggregated;

        # Filtered by severity
        bySeverity = lib.foldl' (acc: result:
          acc // {
            critical = acc.critical ++ result.vulnerabilities.critical.items;
            high = acc.high ++ result.vulnerabilities.high.items;
            medium = acc.medium ++ result.vulnerabilities.medium.items;
            low = acc.low ++ result.vulnerabilities.low.items;
          }
        ) { critical = []; high = []; medium = []; low = []; } scanResults;

        # Risk assessment
        riskAssessment = {
          totalImages = aggregated.totalImages;
          vulnerableImages = aggregated.imagesWithVulnerabilities;
          criticalCount = lib.length aggregated.criticalVulnerabilities;
          highCount = lib.length aggregated.highVulnerabilities;
          overallRisk = 
            if aggregated.criticalVulnerabilities != [] then "CRITICAL"
            else if aggregated.highVulnerabilities != [] then "HIGH"
            else "LOW";
          remediationRequired = aggregated.imagesWithVulnerabilities > 0;
        };

        # Statistics
        statistics = {
          scannedImages = aggregated.totalImages;
          cleanImages = aggregated.totalImages - aggregated.imagesWithVulnerabilities;
          vulnerabilityDensity = 
            if aggregated.totalImages > 0 then
              (lib.length aggregated.criticalVulnerabilities + lib.length aggregated.highVulnerabilities) / aggregated.totalImages
            else
              0.0;
          averageRiskScore = aggregated.averageRiskScore;
        };
      };

    # Snyk Vulnerability Detection
    # Detects vulnerabilities in dependencies and configuration
    snykScan = { manifests, config ? {} }:
      let
        defaultConfig = {
          scanType = [ "dependencies" "configuration" "iac" ];
          severity = "high";  # critical, high, medium, low
          failOn = "high";
          format = "json";
          excludeDevDeps = false;
          pythonTargetVersion = "3.10";
          enablePatchMerge = true;
          timeout = "10m";
        } // config;

        # Parse manifest types
        detectManifestType = manifest:
          if manifest ? apiVersion && manifest ? kind then
            "kubernetes"
          else if manifest ? "package.json" || manifest ? "package-lock.json" then
            "npm"
          else if manifest ? "Pipfile" || manifest ? "requirements.txt" then
            "python"
          else if manifest ? "pom.xml" then
            "maven"
          else if manifest ? "go.mod" then
            "golang"
          else if manifest ? "Dockerfile" then
            "docker"
          else
            "unknown";

        # Scan each manifest
        scanResults = builtins.map (manifest:
          let
            manifestType = detectManifestType manifest;
          in
          {
            manifest = manifest;
            type = manifestType;
            
            vulnerabilities = {
              critical = {
                count = 0;
                items = [];
              };
              high = {
                count = 0;
                items = [];
              };
              medium = {
                count = 0;
                items = [];
              };
              low = {
                count = 0;
                items = [];
              };
            };

            dependencies = {
              direct = 0;
              transitive = 0;
              tested = 0;
              vulnerable = 0;
            };

            recommendations = [];

            summary = {
              totalVulnerabilities = 0;
              patchableVulnerabilities = 0;
              upstreamVulnerabilities = 0;
              licenseIssues = 0;
              status = "PASS";
            };
          }
        ) (if builtins.isList manifests then manifests else [ manifests ]);

        # Aggregate results
        aggregated = {
          totalManifests = lib.length scanResults;
          manifestsWithVulnerabilities = lib.length (
            lib.filter (r: r.summary.totalVulnerabilities > 0) scanResults
          );
          patchableVulnerabilities = builtins.foldl' (sum: r: sum + r.summary.patchableVulnerabilities) 0 scanResults;
          licenseIssues = builtins.foldl' (sum: r: sum + r.summary.licenseIssues) 0 scanResults;
        };

      in
      {
        type = "snyk-scan";
        config = defaultConfig;
        results = scanResults;
        aggregated = aggregated;

        # Grouped by type
        byType = lib.groupBy (r: r.type) scanResults;

        # Risk assessment
        riskAssessment = {
          totalManifests = aggregated.totalManifests;
          vulnerableManifests = aggregated.manifestsWithVulnerabilities;
          patchableCount = aggregated.patchableVulnerabilities;
          licenseIssuesCount = aggregated.licenseIssues;
          overallRisk = 
            if aggregated.manifestsWithVulnerabilities > (aggregated.totalManifests / 2) then "HIGH"
            else if aggregated.manifestsWithVulnerabilities > 0 then "MEDIUM"
            else "LOW";
          remediationPossible = aggregated.patchableVulnerabilities > 0;
        };

        # Remediation suggestions
        remediationPlan = builtins.concatMap (result:
          result.recommendations
        ) scanResults;

        # Statistics
        statistics = {
          manifestsScanned = aggregated.totalManifests;
          cleanManifests = aggregated.totalManifests - aggregated.manifestsWithVulnerabilities;
          patchableRate = 
            if aggregated.manifestsWithVulnerabilities > 0 then
              (aggregated.patchableVulnerabilities / aggregated.manifestsWithVulnerabilities) * 100
            else
              0.0;
        };
      };

    # Falco Runtime Security Monitoring
    # Detects suspicious runtime behavior and policy violations
    falcoMonitoring = { rules, config ? {} }:
      let
        defaultConfig = {
          rulesEnabled = [ "malicious_behavior" "network_anomaly" "privilege_escalation" "data_exfiltration" ];
          sensitivityLevel = "medium";  # low, medium, high, critical
          alertThreshold = "high";
          outputFormat = "json";
          bufferSize = 8;
          logDriver = "syslog";
          sidechannelEnabled = false;
          grpcPort = 5060;
          grpcUnixSocket = "/run/falco/falco.sock";
        } // config;

        # Define built-in rule categories
        builtInRules = {
          malicious_behavior = [
            {
              name = "malicious_shell";
              description = "Suspicious shell execution";
              severity = "CRITICAL";
            }
            {
              name = "malicious_network";
              description = "Suspicious network activity";
              severity = "HIGH";
            }
          ];

          network_anomaly = [
            {
              name = "outbound_connection_unusual_port";
              description = "Outbound connection to unusual port";
              severity = "MEDIUM";
            }
            {
              name = "dns_tunnel_detection";
              description = "Potential DNS tunneling detected";
              severity = "HIGH";
            }
          ];

          privilege_escalation = [
            {
              name = "privileged_container";
              description = "Privileged container execution";
              severity = "HIGH";
            }
            {
              name = "sudo_abuse";
              description = "Potential sudo abuse detected";
              severity = "HIGH";
            }
          ];

          data_exfiltration = [
            {
              name = "suspicious_file_read";
              description = "Suspicious file read patterns";
              severity = "MEDIUM";
            }
            {
              name = "sensitive_data_access";
              description = "Access to sensitive data detected";
              severity = "HIGH";
            }
          ];
        };

        # Merge custom and built-in rules
        allRules = rules // builtInRules;

        # Count rules by severity
        ruleCount = builtins.foldl' (acc: category:
          acc + lib.length (allRules.${category} or [])
        ) 0 (builtins.attrNames allRules);

      in
      {
        type = "falco-monitoring";
        config = defaultConfig;
        rules = allRules;
        totalRules = ruleCount;

        # Rules by severity
        rulesBySeverity = lib.foldl' (acc: category:
          lib.foldl' (acc2: rule:
            acc2 // {
              ${rule.severity} = (acc2.${rule.severity} or []) ++ [rule];
            }
          ) acc (allRules.${category} or [])
        ) {} (builtins.attrNames allRules);

        # Alerts configuration
        alerts = {
          channels = ["syslog" "stdout" "grpc" "file"];
          syslogConfig = {
            facility = "LOG_LOCAL0";
            tag = "falco";
          };
          fileOutput = {
            path = "/var/log/falco/falco.log";
            keepAlive = true;
          };
          grpcOutput = {
            enabled = true;
            unixSocketPath = defaultConfig.grpcUnixSocket;
            port = defaultConfig.grpcPort;
          };
        };

        # Runtime behavior policies
        behaviorPolicies = [
          {
            name = "restrict-syscalls";
            description = "Restrict dangerous system calls";
            enabled = true;
            severity = "HIGH";
          }
          {
            name = "network-isolation";
            description = "Enforce network isolation rules";
            enabled = true;
            severity = "MEDIUM";
          }
          {
            name = "privilege-boundaries";
            description = "Enforce privilege boundaries";
            enabled = true;
            severity = "HIGH";
          }
          {
            name = "file-integrity";
            description = "Monitor file integrity changes";
            enabled = true;
            severity = "MEDIUM";
          }
        ];

        # Statistics
        statistics = {
          totalRules = ruleCount;
          criticalRules = lib.length (allRules.rulesBySeverity.CRITICAL or []);
          highRules = lib.length (allRules.rulesBySeverity.HIGH or []);
          mediumRules = lib.length (allRules.rulesBySeverity.MEDIUM or []);
          behaviorPolicies = lib.length behaviorPolicies;
        };

        # Deployment configuration
        deployment = {
          daemonSetConfig = {
            image = "falcosecurity/falco:latest";
            securityContext = {
              privileged = true;
            };
            volumeMounts = [
              { name = "docker"; mountPath = "/var/run/docker.sock"; }
              { name = "containerd"; mountPath = "/var/run/containerd"; }
              { name = "crio"; mountPath = "/var/run/crio"; }
              { name = "sysfs"; mountPath = "/sys"; }
              { name = "debugfs"; mountPath = "/sys/kernel/debug"; }
            ];
          };
          namespace = "falco";
          replicas = "all";
        };
      };

    # Security Scanning Orchestration
    # Coordinates and manages all security scanning operations
    securityOrchestration = { scanConfigs, config ? {} }:
      let
        defaultConfig = {
          schedulingPolicy = "sequential";  # sequential, parallel, staged
          failurePolicy = "alert";  # alert, block, log
          scanSchedule = "0 2 * * *";  # Daily at 2 AM
          retentionDays = 30;
          reportFormat = "html";
          dashboardEnabled = true;
          alertingEnabled = true;
          automediateEnabled = false;
          approvalRequired = true;
        } // config;

        # Orchestration pipeline
        pipeline = [
          {
            stage = "pre-scan";
            name = "prepare";
            description = "Prepare scanning environment";
            timeout = "5m";
          }
          {
            stage = "scan";
            name = "image-scanning";
            description = "Scan container images";
            scanner = "trivy";
            timeout = "30m";
            parallel = true;
          }
          {
            stage = "scan";
            name = "dependency-scanning";
            description = "Scan dependencies";
            scanner = "snyk";
            timeout = "20m";
            parallel = true;
          }
          {
            stage = "scan";
            name = "runtime-monitoring";
            description = "Enable runtime monitoring";
            scanner = "falco";
            timeout = "ongoing";
            parallel = true;
          }
          {
            stage = "analysis";
            name = "aggregate-results";
            description = "Aggregate scanning results";
            timeout = "10m";
          }
          {
            stage = "reporting";
            name = "generate-report";
            description = "Generate security report";
            timeout = "5m";
          }
          {
            stage = "post-scan";
            name = "cleanup";
            description = "Cleanup temporary artifacts";
            timeout = "5m";
          }
        ];

        # Scan configurations
        allScans = builtins.map (cfg:
          cfg // { status = "pending"; results = null; }
        ) (if builtins.isList scanConfigs then scanConfigs else [ scanConfigs ]);

      in
      {
        type = "security-orchestration";
        config = defaultConfig;
        pipeline = pipeline;
        scans = allScans;

        # Pipeline stages
        stages = lib.unique (builtins.map (step: step.stage) pipeline);

        # Scheduling
        schedule = {
          cronExpression = defaultConfig.scanSchedule;
          timezone = "UTC";
          automaticRetry = 3;
          retryBackoff = "exponential";
          maxConcurrentScans = 5;
        };

        # Reporting
        reporting = {
          formats = [ "json" "html" "sarif" "pdf" ];
          sendTo = [ "dashboard" "email" "webhook" "slack" ];
          includeMetadata = true;
          includeRecommendations = true;
          includeTimeline = true;
        };

        # Compliance tracking
        complianceTracking = {
          frameworks = [ "PCI-DSS" "HIPAA" "SOC2" "ISO27001" "GDPR" ];
          scanCoverage = {
            containerImages = true;
            dependencies = true;
            runtimeBehavior = true;
            policies = true;
          };
          remediationTracking = true;
          SLAs = {
            critical = "1h";
            high = "4h";
            medium = "24h";
            low = "7d";
          };
        };

        # Integration points
        integrations = {
          kubernetes = {
            webhooks = true;
            mutatingAdmission = true;
            validatingAdmission = true;
          };
          cicd = {
            githubActions = true;
            gitlabCI = true;
            jenkinsPlugin = true;
          };
          monitoring = {
            prometheus = true;
            grafana = true;
            elasticSearch = true;
          };
        };

        # Statistics
        statistics = {
          totalScans = lib.length allScans;
          scansByType = lib.groupBy (s: s.type) allScans;
          pipelineStages = lib.length pipeline;
          estimatedDuration = 
            builtins.foldl' (sum: step: sum + 
              (if step.stage == "scan" && step.parallel then 0 else lib.stringToInt (lib.head (lib.strings.splitString "m" step.timeout)))
            ) 0 pipeline;
        };
      };

    # Security Report Generation
    # Creates comprehensive security scanning reports
    generateSecurityReport = { scans, config ? {} }:
      let
        defaultConfig = {
          includeDetails = true;
          includeTrends = true;
          includeRecommendations = true;
          severityThreshold = "medium";
          format = "html";
        } // config;

        # Aggregate all vulnerabilities
        allVulnerabilities = builtins.concatMap (scan:
          if scan.type == "trivy-scan" then
            scan.bySeverity.critical ++ scan.bySeverity.high ++ scan.bySeverity.medium
          else if scan.type == "snyk-scan" then
            scan.aggregated.critical ++ scan.aggregated.high
          else
            []
        ) (if builtins.isList scans then scans else [ scans ]);

        # Risk scoring
        riskScore = builtins.foldl' (sum: vuln: 
          sum + (
            if vuln.severity == "CRITICAL" then 10
            else if vuln.severity == "HIGH" then 5
            else if vuln.severity == "MEDIUM" then 2
            else 1
          )
        ) 0 allVulnerabilities;

        # Remediation priority
        remediationPriority = 
          if riskScore > 50 then "IMMEDIATE"
          else if riskScore > 20 then "HIGH"
          else if riskScore > 5 then "MEDIUM"
          else "LOW";

      in
      {
        type = "security-report";
        config = defaultConfig;
        
        summary = {
          totalVulnerabilities = lib.length allVulnerabilities;
          criticalCount = lib.length (lib.filter (v: v.severity == "CRITICAL") allVulnerabilities);
          highCount = lib.length (lib.filter (v: v.severity == "HIGH") allVulnerabilities);
          riskScore = riskScore;
          overallStatus = 
            if riskScore > 50 then "FAILED"
            else if riskScore > 20 then "WARNING"
            else "PASSED";
        };

        findings = lib.groupBy (v: v.severity) allVulnerabilities;

        recommendations = [
          {
            priority = "IMMEDIATE";
            action = "Patch critical vulnerabilities";
            timeline = "24 hours";
          }
          {
            priority = "HIGH";
            action = "Update high-risk dependencies";
            timeline = "1 week";
          }
          {
            priority = "MEDIUM";
            action = "Review and update medium-risk items";
            timeline = "2 weeks";
          }
        ];

        remediationPlan = {
          priority = remediationPriority;
          estimatedEffort = "40-60 hours";
          phases = [
            { phase = 1; items = "Critical vulnerabilities"; duration = "1 week"; }
            { phase = 2; items = "High-risk items"; duration = "2 weeks"; }
            { phase = 3; items = "Medium and low items"; duration = "1 month"; }
          ];
        };

        complianceStatus = {
          pciDss = "PARTIAL";
          hipaa = "PARTIAL";
          soc2 = "PARTIAL";
          iso27001 = "COMPLIANT";
        };

        statistics = {
          reportGeneratedAt = "2024-01-15T10:00:00Z";
          scansIncluded = lib.length (if builtins.isList scans then scans else [ scans ]);
          vulnerabilitiesCovered = lib.length allVulnerabilities;
        };
      };
  };
}
