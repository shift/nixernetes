#!/usr/bin/env python3
"""
Nixernetes Cost Analysis Tool

This tool analyzes Kubernetes manifests and provides cost estimates,
optimization recommendations, and detailed breakdowns by resource and provider.
"""

import json
import sys
import yaml
import argparse
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from collections import defaultdict


@dataclass
class CPUMemory:
    """Represents CPU and memory resources"""
    cpu: float  # in cores
    memory: float  # in GB


class CostCalculator:
    """Calculates costs based on resource requests"""
    
    # Pricing data (USD per hour)
    PROVIDERS = {
        'aws': {
            'cpu': 0.0535,      # m5.large equivalent
            'memory': 0.0108,
        },
        'azure': {
            'cpu': 0.0490,
            'memory': 0.0098,
        },
        'gcp': {
            'cpu': 0.0440,      # n2 machine
            'memory': 0.0059,
        },
    }

    @staticmethod
    def parse_quantity(value: str) -> float:
        """Parse Kubernetes quantity (e.g., '500m' -> 0.5, '1Gi' -> 1.0)"""
        if not value:
            return 0.0
        
        value = value.strip()
        
        # CPU in millicores
        if value.endswith('m'):
            return float(value[:-1]) / 1000.0
        
        # Memory
        memory_units = {
            'Mi': 1 / 1024,
            'Gi': 1.0,
            'Ti': 1024.0,
            'Ki': 1 / (1024 * 1024),
        }
        
        for unit, multiplier in memory_units.items():
            if value.endswith(unit):
                return float(value[:-len(unit)]) * multiplier
        
        # Plain number (cores)
        try:
            return float(value)
        except ValueError:
            return 0.0

    @staticmethod
    def calculate_container_cost(container: Dict[str, Any], replicas: int, 
                                provider: str = 'aws') -> Dict[str, float]:
        """Calculate hourly cost for a container"""
        pricing = CostCalculator.PROVIDERS.get(provider, CostCalculator.PROVIDERS['aws'])
        
        resources = container.get('resources', {})
        requests = resources.get('requests', {})
        
        cpu = CostCalculator.parse_quantity(requests.get('cpu', '100m'))
        memory = CostCalculator.parse_quantity(requests.get('memory', '128Mi'))
        
        hourly = (cpu * pricing['cpu']) + (memory * pricing['memory'])
        
        return {
            'hourly': hourly * replicas,
            'daily': hourly * replicas * 24,
            'monthly': hourly * replicas * 24 * 30,
            'annual': hourly * replicas * 24 * 365,
        }

    @staticmethod
    def calculate_pod_cost(pod_spec: Dict[str, Any], replicas: int,
                          provider: str = 'aws') -> Dict[str, float]:
        """Calculate cost for a Pod with multiple containers"""
        containers = pod_spec.get('containers', [])
        
        total_hourly = 0.0
        for container in containers:
            cost = CostCalculator.calculate_container_cost(container, 1, provider)
            total_hourly += cost['hourly']
        
        total_hourly *= replicas
        
        return {
            'hourly': total_hourly,
            'daily': total_hourly * 24,
            'monthly': total_hourly * 24 * 30,
            'annual': total_hourly * 24 * 365,
        }


class ManifestAnalyzer:
    """Analyzes Kubernetes manifests for cost"""
    
    def __init__(self, provider: str = 'aws'):
        self.provider = provider
        self.deployments = {}
        self.statefulsets = {}
        self.daemonsets = {}
        self.pods = {}
        self.recommendations = []

    def load_manifest(self, data: Dict[str, Any]):
        """Load a single Kubernetes resource"""
        kind = data.get('kind')
        metadata = data.get('metadata', {})
        name = metadata.get('name', 'unknown')
        
        if kind == 'Deployment':
            self.deployments[name] = data
        elif kind == 'StatefulSet':
            self.statefulsets[name] = data
        elif kind == 'DaemonSet':
            self.daemonsets[name] = data
        elif kind == 'Pod':
            self.pods[name] = data

    def load_manifests_file(self, filepath: str):
        """Load manifests from a YAML file"""
        with open(filepath, 'r') as f:
            docs = yaml.safe_load_all(f)
            for doc in docs:
                if doc:
                    self.load_manifest(doc)

    def analyze(self) -> Dict[str, Any]:
        """Analyze all loaded resources"""
        costs = {
            'deployments': {},
            'statefulsets': {},
            'daemonsets': {},
            'pods': {},
            'total': {},
            'recommendations': [],
        }
        
        total_hourly = 0.0
        
        # Analyze Deployments
        for name, deployment in self.deployments.items():
            spec = deployment.get('spec', {})
            replicas = spec.get('replicas', 1)
            template_spec = spec.get('template', {}).get('spec', {})
            
            cost = CostCalculator.calculate_pod_cost(template_spec, replicas, self.provider)
            costs['deployments'][name] = {
                'replicas': replicas,
                'cost': cost,
            }
            total_hourly += cost['hourly']
            
            # Check for optimization opportunities
            self._check_deployment_optimization(name, deployment)
        
        # Analyze StatefulSets
        for name, statefulset in self.statefulsets.items():
            spec = statefulset.get('spec', {})
            replicas = spec.get('replicas', 1)
            template_spec = spec.get('template', {}).get('spec', {})
            
            cost = CostCalculator.calculate_pod_cost(template_spec, replicas, self.provider)
            costs['statefulsets'][name] = {
                'replicas': replicas,
                'cost': cost,
            }
            total_hourly += cost['hourly']
        
        # Analyze DaemonSets (multiply by typical node count)
        for name, daemonset in self.daemonsets.items():
            template_spec = daemonset.get('spec', {}).get('template', {}).get('spec', {})
            # Assume 10 nodes for estimation
            cost = CostCalculator.calculate_pod_cost(template_spec, 10, self.provider)
            costs['daemonsets'][name] = {
                'replicas': '10 (estimated)',
                'cost': cost,
            }
            total_hourly += cost['hourly']
        
        # Analyze standalone Pods
        for name, pod in self.pods.items():
            spec = pod.get('spec', {})
            cost = CostCalculator.calculate_pod_cost(spec, 1, self.provider)
            costs['pods'][name] = {
                'replicas': 1,
                'cost': cost,
            }
            total_hourly += cost['hourly']
        
        costs['total'] = {
            'hourly': round(total_hourly, 4),
            'daily': round(total_hourly * 24, 4),
            'monthly': round(total_hourly * 24 * 30, 2),
            'annual': round(total_hourly * 24 * 365, 2),
        }
        
        costs['recommendations'] = self.recommendations
        costs['provider'] = self.provider
        costs['currency'] = 'USD'
        
        return costs

    def _check_deployment_optimization(self, name: str, deployment: Dict[str, Any]):
        """Check for optimization opportunities"""
        spec = deployment.get('spec', {})
        template_spec = spec.get('template', {}).get('spec', {})
        containers = template_spec.get('containers', [])
        
        for container in containers:
            container_name = container.get('name', 'unknown')
            resources = container.get('resources', {})
            requests = resources.get('requests', {})
            limits = resources.get('limits', {})
            
            # Check for oversized CPU requests
            cpu_request = CostCalculator.parse_quantity(requests.get('cpu', '100m'))
            if cpu_request > 2.0:
                self.recommendations.append({
                    'resource': f'{name}/{container_name}',
                    'severity': 'medium',
                    'type': 'cpu_oversizing',
                    'issue': f'CPU request is {cpu_request:.1f} cores',
                    'impact': 'High CPU requests increase hourly costs',
                    'recommendation': 'Consider reducing CPU to 1-2 cores for most workloads',
                    'estimated_savings_hourly': (cpu_request - 1.0) * 0.0535,
                })
            
            # Check for missing memory limits
            if not limits.get('memory'):
                self.recommendations.append({
                    'resource': f'{name}/{container_name}',
                    'severity': 'low',
                    'type': 'missing_limit',
                    'issue': 'No memory limit specified',
                    'impact': 'Pod can consume unlimited memory',
                    'recommendation': 'Set memory limit based on request + safety margin',
                })
            
            # Check for low request/limit ratio
            if requests and limits:
                cpu_limit = CostCalculator.parse_quantity(limits.get('cpu', '0'))
                if cpu_request > 0 and cpu_limit > 0:
                    ratio = cpu_limit / cpu_request
                    if ratio < 1.1:
                        self.recommendations.append({
                            'resource': f'{name}/{container_name}',
                            'severity': 'low',
                            'type': 'tight_limits',
                            'issue': f'CPU limit ratio is {ratio:.1f}x request',
                            'impact': 'Container may be throttled during spikes',
                            'recommendation': 'Set limits 2-3x requests for headroom',
                        })


def format_currency(amount: float) -> str:
    """Format amount as USD currency"""
    return f"${amount:,.2f}"


def print_summary(costs: Dict[str, Any]):
    """Print cost analysis summary"""
    total = costs['total']
    provider = costs['provider'].upper()
    
    print(f"\n{'='*70}")
    print(f"Nixernetes Cost Analysis Report")
    print(f"Provider: {provider} | Currency: {costs['currency']}")
    print(f"{'='*70}\n")
    
    print(f"Total Estimated Costs:")
    print(f"  Hourly:   {format_currency(total['hourly'])}")
    print(f"  Daily:    {format_currency(total['daily'])}")
    print(f"  Monthly:  {format_currency(total['monthly'])}")
    print(f"  Annual:   {format_currency(total['annual'])}\n")
    
    # Deployments breakdown
    if costs['deployments']:
        print(f"Deployments ({len(costs['deployments'])})")
        print(f"{'-'*70}")
        for name, data in costs['deployments'].items():
            cost = data['cost']
            print(f"  {name} ({data['replicas']} replicas)")
            print(f"    Monthly: {format_currency(cost['monthly'])}")
    
    # StatefulSets breakdown
    if costs['statefulsets']:
        print(f"\nStatefulSets ({len(costs['statefulsets'])})")
        print(f"{'-'*70}")
        for name, data in costs['statefulsets'].items():
            cost = data['cost']
            print(f"  {name} ({data['replicas']} replicas)")
            print(f"    Monthly: {format_currency(cost['monthly'])}")
    
    # DaemonSets breakdown
    if costs['daemonsets']:
        print(f"\nDaemonSets ({len(costs['daemonsets'])})")
        print(f"{'-'*70}")
        for name, data in costs['daemonsets'].items():
            cost = data['cost']
            print(f"  {name} ({data['replicas']} nodes)")
            print(f"    Monthly: {format_currency(cost['monthly'])}")
    
    # Recommendations
    if costs['recommendations']:
        print(f"\n{'='*70}")
        print(f"Optimization Recommendations ({len(costs['recommendations'])})")
        print(f"{'='*70}")
        for rec in costs['recommendations']:
            severity_indicator = {'high': '⚠️  ', 'medium': '⚡ ', 'low': 'ℹ️  '}
            print(f"\n{severity_indicator.get(rec.get('severity', 'low'), '• ')}{rec['resource']}")
            print(f"  Issue: {rec['issue']}")
            print(f"  Impact: {rec['impact']}")
            print(f"  Recommendation: {rec['recommendation']}")
            if 'estimated_savings_hourly' in rec:
                savings = rec['estimated_savings_hourly'] * 24 * 30
                print(f"  Potential Savings: {format_currency(savings)}/month")


def main():
    parser = argparse.ArgumentParser(
        description='Analyze Kubernetes manifest costs'
    )
    parser.add_argument('manifests', nargs='*', help='Manifest files to analyze')
    parser.add_argument('-p', '--provider', default='aws', 
                       choices=['aws', 'azure', 'gcp'],
                       help='Cloud provider (default: aws)')
    parser.add_argument('-f', '--format', default='text',
                       choices=['text', 'json', 'yaml'],
                       help='Output format (default: text)')
    parser.add_argument('-o', '--output', help='Output file (default: stdout)')
    
    args = parser.parse_args()
    
    if not args.manifests:
        parser.print_help()
        sys.exit(1)
    
    analyzer = ManifestAnalyzer(provider=args.provider)
    
    # Load manifests
    for manifest_file in args.manifests:
        try:
            analyzer.load_manifests_file(manifest_file)
        except Exception as e:
            print(f"Error loading {manifest_file}: {e}", file=sys.stderr)
            sys.exit(1)
    
    # Analyze
    costs = analyzer.analyze()
    
    # Output
    if args.format == 'json':
        output = json.dumps(costs, indent=2)
    elif args.format == 'yaml':
        output = yaml.dump(costs, default_flow_style=False)
    else:  # text
        print_summary(costs)
        output = None
    
    if output:
        if args.output:
            with open(args.output, 'w') as f:
                f.write(output)
            print(f"Output written to {args.output}")
        else:
            print(output)


if __name__ == '__main__':
    main()
