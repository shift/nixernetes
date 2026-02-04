# Example: Disaster Recovery Module
#
# This example demonstrates comprehensive usage of the Nixernetes Disaster
# Recovery module for backup policies, failover strategies, and recovery procedures.
#
# The Disaster Recovery module provides:
# - Automated backup policies with retention
# - Multi-cluster failover and recovery
# - Recovery Point/Time Objectives
# - Disaster recovery planning and procedures
# - Data replication and synchronization
# - Chaos testing and validation

{ lib, ... }:

let
  dr = import ../src/lib/disaster-recovery.nix { inherit lib; };

in
{
  # ============================================================================
  # Example 1: Daily Backup Policy with Cloud Storage
  # ============================================================================
  
  production_backup_policy =
    let
      policy = dr.mkBackupPolicy "production-daily-backup" {
        namespace = "production";
        enabled = true;
        schedule = "0 2 * * *";  # Daily at 2 AM UTC
        
        retention = {
          daily = 7;    # Keep 7 daily backups
          weekly = 4;   # Keep 4 weekly backups
          monthly = 12; # Keep 12 monthly backups
          yearly = 7;   # Keep 7 yearly backups
        };
        
        backupType = "full";
        storageLocation = "s3://company-backups/production";
        encryptionKey = "arn:aws:kms:us-east-1:123456789:key/prod-backup-key";
        compressionEnabled = true;
        snapshotVolumeData = true;
        
        includeResources = ["*"];
        excludeResources = ["kube-system" "kube-node-lease" "kube-public"];
        
        hooks = {
          preBackup = "notify-ops-backup-starting";
          postBackup = "verify-backup-integrity";
        };
      };
    in
    {
      inherit policy;
      
      # Backup storage configuration
      storage = dr.mkBackupStorage "production-s3" {
        type = "s3";
        location = "company-backups";
        region = "us-east-1";
        redundancy = "high";
        lifecyclePolicy = {
          deleteAfterDays = 2555;  # 7 years
          archiveAfterDays = 90;
          archiveStorageClass = "glacier";
        };
        accessControl = {
          encryption = "AES-256";
          versioning = true;
          publicAccess = false;
        };
        costPerGB = 0.023;  # AWS S3 pricing
      };
    };

  # ============================================================================
  # Example 2: Point-in-Time Recovery with Namespace Restore
  # ============================================================================
  
  point_in_time_restore =
    let
      strategy = dr.mkRestoreStrategy "restore-production-2024-02-04" {
        backupName = "production-backup-2024-02-04";
        namespace = "production";
        
        restoreVolumes = true;
        restorePVs = true;
        restoreSecrets = true;
        restoreConfigMaps = true;
        
        # Map namespaces for multi-cluster restores
        namespaceMapping = {};
        
        # Restore specific resource types
        includeResources = ["Deployment" "StatefulSet" "Service" "PVC" "Secret" "ConfigMap"];
        excludeResources = ["Job" "Pod"];  # Don't restore jobs/pods
        
        existingResourcePolicy = "skip";  # Don't overwrite existing
        
        hooks = {
          preRestore = "backup-current-state";
          postRestore = "run-data-validation";
        };
        
        schedule = null;  # One-time restore
        verifyRestore = true;
      };
    in
    {
      inherit strategy;
    };

  # ============================================================================
  # Example 3: Multi-Region Active-Passive Failover
  # ============================================================================
  
  multi_region_failover =
    let
      failoverPolicy = dr.mkFailoverPolicy "global-app-failover" {
        primaryCluster = "aws-us-east-1";
        secondaryCluster = "aws-us-west-1";
        tertiaryCluster = "gcp-us-central";
        
        failoverTrigger = "health-based";
        healthCheckInterval = 30;  # Check every 30 seconds
        healthCheckThreshold = 3;  # Failover after 3 failures
        
        rtoMinutes = 60;   # Must recover within 1 hour
        rpoMinutes = 15;   # Can lose up to 15 minutes of data
        
        dataReplicationMode = "async";
        readWriteMode = "write-to-primary";
        
        rollbackPolicy = "manual";
        rollbackWindow = 3600;  # 1 hour to rollback
      };
      
      validation = dr.validateFailoverPolicy failoverPolicy;
    in
    {
      inherit failoverPolicy validation;
      
      # Recovery objectives
      rpo = dr.mkRPO "global-rpo" {
        targetRPOMinutes = 15;
        replicationFrequency = 5;  # Every 5 minutes
        dataChangeRate = "medium";
        networkBandwidth = "1Gbps";
        storageCapacity = "10TB";
        backupWindow = 120;  # 2 hour backup window
      };
      
      rto = dr.mkRTO "global-rto" {
        targetRTOMinutes = 60;
        parallelRestores = 10;
        preWarmResources = true;
        automatedRecovery = true;
        testingFrequency = "monthly";
        maxDataLoss = "15 minutes";
      };
    };

  # ============================================================================
  # Example 4: Critical Database with Synchronous Replication
  # ============================================================================
  
  critical_database_dr =
    let
      # Tight RPO for database
      rpo = dr.mkRPO "database-rpo" {
        targetRPOMinutes = 1;  # Maximum 1 minute data loss
        replicationFrequency = 1;  # Every minute
        dataChangeRate = "high";
        networkBandwidth = "10Gbps";
        storageCapacity = "50TB";
        backupWindow = 30;  # 30 minute backup window
      };
      
      # Fast recovery for database
      rto = dr.mkRTO "database-rto" {
        targetRTOMinutes = 30;  # Recover in 30 minutes
        parallelRestores = 20;
        preWarmResources = true;
        automatedRecovery = true;
        testingFrequency = "weekly";
        maxDataLoss = "1 minute";
      };
      
      # Synchronous replication for data consistency
      replication = dr.mkDataReplication "database-replication" {
        sourceCluster = "aws-primary";
        targetClusters = ["aws-secondary" "gcp-backup"];
        
        replicationMode = "sync";  # Synchronous for consistency
        replicationFrequency = 1;
        dataTypes = ["databases"];
        
        compressionEnabled = false;  # Don't compress for latency
        encryptionEnabled = true;
        
        conflictResolution = "source-wins";
        bandwidth = "10Gbps";
      };
    in
    {
      inherit rpo rto replication;
    };

  # ============================================================================
  # Example 5: Mission-Critical Application DR Plan
  # ============================================================================
  
  mission_critical_dr_plan =
    let
      plan = dr.mkDisasterRecoveryPlan "mission-critical-app-dr" {
        version = "2.0.0";
        lastTested = "2024-02-04";
        nextTestDate = "2024-03-04";
        criticality = "critical";
        
        owner = "John Doe";
        ownerEmail = "john.doe@example.com";
        
        backupPolicy = {
          schedule = "0 * * * *";  # Hourly
          retention = {
            hourly = 24;
            daily = 7;
            weekly = 4;
            monthly = 12;
          };
          storageLocation = "s3://mission-critical/backups";
        };
        
        failoverPolicy = {
          primaryCluster = "us-east-1-prod";
          secondaryCluster = "us-west-1-dr";
          failoverTrigger = "health-based";
          rtoMinutes = 30;
          rpoMinutes = 5;
        };
        
        restoreStrategy = {
          backupName = "latest";
          namespace = "production";
          verifyRestore = true;
        };
        
        detectionProcedure = [
          "1. Monitor health check endpoints (API, database, cache)"
          "2. Alert on 3 consecutive failures within 1 minute"
          "3. Verify impact across multiple regions"
          "4. Check DNS propagation and CDN status"
          "5. Notify incident commander"
        ];
        
        initialResponseSteps = [
          "1. (0 min) Declare incident in #incidents"
          "2. (0 min) Start incident bridge call"
          "3. (2 min) Notify executive escalation contacts"
          "4. (3 min) Begin incident communication updates"
          "5. (5 min) Assessment of blast radius"
        ];
        
        recoverySteps = [
          "1. (5 min) Trigger automated failover to secondary"
          "2. (10 min) Verify secondary cluster is healthy"
          "3. (15 min) Update DNS to point to secondary"
          "4. (20 min) Monitor traffic transition"
          "5. (25 min) Run automated smoke tests"
          "6. (30 min) Notify customers of recovery"
        ];
        
        validationSteps = [
          "1. Health check critical endpoints"
          "2. Run integration test suite"
          "3. Verify data consistency"
          "4. Check error rates and latency"
          "5. Validate customer-facing functionality"
        ];
        
        rollbackSteps = [
          "1. Stop accepting new traffic to secondary"
          "2. Verify primary cluster recovery"
          "3. Manually cutback DNS to primary"
          "4. Monitor primary for stability"
          "5. Gradual traffic migration back"
        ];
        
        communicationPlan = {
          internalChannel = "#incidents";
          customerChannel = "status.example.com";
          updateFrequency = "every 5 minutes";
          postIncidentReviewTime = "within 24 hours";
        };
        
        primaryContact = {
          name = "Alice Smith";
          title = "VP Engineering";
          email = "alice@example.com";
          phone = "+1-555-0100";
          timezone = "US/Eastern";
        };
        
        secondaryContact = {
          name = "Bob Johnson";
          title = "Engineering Manager";
          email = "bob@example.com";
          phone = "+1-555-0101";
          timezone = "US/Pacific";
        };
        
        escalationContacts = [
          {
            name = "CTO";
            email = "cto@example.com";
            escalationTime = "15 minutes";
          }
          {
            name = "CEO";
            email = "ceo@example.com";
            escalationTime = "30 minutes";
          }
        ];
        
        runbooks = [
          "runbooks/complete-cluster-failure.md"
          "runbooks/database-recovery.md"
          "runbooks/cache-rebuild.md"
          "runbooks/dns-failover.md"
        ];
        
        postIncidentReview = {
          template = "post-incident-review-template.md";
          owner = "john.doe@example.com";
          dueDate = "within 48 hours";
        };
      };
      
      validation = dr.validateDisasterRecoveryPlan plan;
    in
    {
      inherit plan validation;
    };

  # ============================================================================
  # Example 6: Disaster Recovery Testing with Chaos
  # ============================================================================
  
  dr_testing_suite =
    {
      # Test node failure
      nodeFailureTest = dr.mkChaosTest "node-failure-test" {
        scenario = "node-failure";
        affectedResources = ["node-1" "node-2"];
        duration = 300;  # 5 minutes
        delay = 0;
        enabled = true;
        
        expectedOutcome = "All pods reschedule to remaining nodes within 2 minutes";
        measurableMetrics = [
          "pod-reschedule-time"
          "service-availability-percentage"
          "api-p99-latency"
        ];
        
        passThreshold = 0.99;  # 99% pods must reschedule
        runOn = "staging";
      };
      
      # Test pod failure
      podFailureTest = dr.mkChaosTest "pod-failure-test" {
        scenario = "pod-failure";
        affectedResources = ["deployment/api-server"];
        duration = 120;
        delay = 0;
        enabled = true;
        
        expectedOutcome = "New pods spin up and serve traffic within 30 seconds";
        measurableMetrics = [
          "pod-startup-time"
          "request-success-rate"
          "error-rate"
        ];
        
        passThreshold = 0.98;
        runOn = "staging";
      };
      
      # Test network partition
      networkPartitionTest = dr.mkChaosTest "network-partition-test" {
        scenario = "network-partition";
        affectedResources = ["secondary-cluster"];
        duration = 180;
        delay = 0;
        enabled = true;
        
        expectedOutcome = "Failover to primary, secondary recovers gracefully";
        measurableMetrics = [
          "failover-detection-time"
          "dns-update-time"
          "data-consistency-check"
        ];
        
        passThreshold = 0.95;
        runOn = "staging";
      };
      
      # Test storage failure
      storageFailureTest = dr.mkChaosTest "storage-failure-test" {
        scenario = "storage-failure";
        affectedResources = ["pvc/data-volume"];
        duration = 60;
        delay = 0;
        enabled = false;  # Dangerous, only enable in test
        
        expectedOutcome = "Data is restored from backup";
        measurableMetrics = [
          "restore-time"
          "data-recovery-success"
        ];
        
        passThreshold = 0.99;
        runOn = "staging";
      };
    };

  # ============================================================================
  # Example 7: Recovery Runbooks
  # ============================================================================
  
  recovery_runbooks =
    {
      # Complete cluster recovery
      clusterRecoveryRunbook = dr.mkRecoveryRunbook "complete-cluster-recovery" {
        scenarioType = "complete-cluster-failure";
        estimatedDuration = 120;
        
        requiredRoles = ["cluster-admin" "security-admin" "database-admin"];
        
        prerequisites = [
          "Backup exists and is verified intact"
          "Secondary cluster is operational"
          "DNS failover is configured"
          "Network connectivity to backup region verified"
          "All stakeholders notified"
        ];
        
        steps = [
          {
            number = 1;
            action = "Verify backup integrity";
            expectedResult = "Backup is complete and valid";
            estimatedTime = 5;  # minutes
          }
          {
            number = 2;
            action = "Pause traffic to primary region";
            expectedResult = "No new traffic arriving";
            estimatedTime = 2;
          }
          {
            number = 3;
            action = "Restore to secondary cluster";
            expectedResult = "All resources restored successfully";
            estimatedTime = 30;
          }
          {
            number = 4;
            action = "Run data validation";
            expectedResult = "Data integrity verified";
            estimatedTime = 10;
          }
          {
            number = 5;
            action = "Update DNS to point to secondary";
            expectedResult = "Traffic redirects to secondary";
            estimatedTime = 5;
          }
          {
            number = 6;
            action = "Monitor secondary for stability";
            expectedResult = "No errors, normal performance";
            estimatedTime = 30;
          }
        ];
        
        rollbackSteps = [
          {
            number = 1;
            action = "Verify primary cluster is recovered";
            expectedResult = "Primary cluster is healthy and operational";
            estimatedTime = 10;
          }
          {
            number = 2;
            action = "Pause traffic to secondary";
            expectedResult = "No active connections to secondary";
            estimatedTime = 5;
          }
          {
            number = 3;
            action = "Update DNS back to primary";
            expectedResult = "Traffic flows to primary";
            estimatedTime = 5;
          }
          {
            number = 4;
            action = "Monitor primary for stability";
            expectedResult = "Primary handles full load";
            estimatedTime = 30;
          }
        ];
        
        lastTested = "2024-02-04";
        createdDate = "2024-01-15";
      };
      
      # Database recovery runbook
      databaseRecoveryRunbook = dr.mkRecoveryRunbook "database-recovery" {
        scenarioType = "database-corruption";
        estimatedDuration = 60;
        
        requiredRoles = ["database-admin" "cluster-admin"];
        
        prerequisites = [
          "Database backup exists"
          "Point-in-time recovery window is open"
          "DBA review is complete"
        ];
        
        steps = [
          {
            number = 1;
            action = "Identify corruption point";
            estimatedTime = 5;
          }
          {
            number = 2;
            action = "Take database backup before recovery";
            estimatedTime = 10;
          }
          {
            number = 3;
            action = "Restore database to point-in-time";
            estimatedTime = 30;
          }
          {
            number = 4;
            action = "Run consistency checks";
            estimatedTime = 10;
          }
          {
            number = 5;
            action = "Clear replication lag";
            estimatedTime = 5;
          }
        ];
        
        lastTested = "2024-02-01";
        createdDate = "2024-01-15";
      };
    };

  # ============================================================================
  # Example 8: Development Environment with Minimal DR
  # ============================================================================
  
  dev_environment_dr =
    let
      # Simple backup for dev
      devBackup = dr.mkBackupPolicy "dev-weekly-backup" {
        namespace = "development";
        enabled = true;
        schedule = "0 0 * * 0";  # Weekly on Sunday
        
        retention = {
          daily = 0;
          weekly = 4;
          monthly = 0;
          yearly = 0;
        };
        
        backupType = "full";
        storageLocation = "s3://company-backups/dev";
        compressionEnabled = true;
        snapshotVolumeData = false;  # Don't snapshot dev volumes
        
        includeResources = ["Deployment" "ConfigMap" "Secret"];
        excludeResources = [];
      };
      
      # Quick restore for dev
      devRestore = dr.mkRestoreStrategy "dev-restore" {
        backupName = "latest";
        namespace = "development";
        existingResourcePolicy = "delete";  # Overwrite in dev
        verifyRestore = false;  # Skip verification in dev
      };
    in
    {
      inherit devBackup devRestore;
      
      # Dev doesn't need complex DR
      rto = dr.mkRTO "dev-rto" {
        targetRTOMinutes = 480;  # 8 hours is fine for dev
        parallelRestores = 1;
        preWarmResources = false;
        automatedRecovery = false;
        testingFrequency = "never";  # No testing in dev
      };
    };

  # ============================================================================
  # Framework information
  # ============================================================================
  
  framework_info = dr.framework;
}
