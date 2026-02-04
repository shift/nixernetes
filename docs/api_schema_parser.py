# This is a conceptual helper script that could be used in a derivation 
# to pre-process the massive K8s Swagger JSON into a Nix-friendly 
# API version map for the module system.

import json
import sys

def extract_api_map(swagger_path):
    with open(swagger_path, 'r') as f:
        spec = json.load(f)
    
    api_map = {}
    for path, details in spec.get('paths', {}).items():
        # Look for the primary POST/GET paths to determine preferred API versions
        if 'post' in details:
            gvk = details['post'].get('x-kubernetes-group-version-kind', {})
            kind = gvk.get('kind')
            group = gvk.get('group')
            version = gvk.get('version')
            
            if kind:
                api_version = f"{group}/{version}" if group else version
                # Prefer stable over beta/alpha
                if kind not in api_map or 'v1' in api_version:
                    api_map[kind] = api_version
    
    return api_map

if __name__ == "__main__":
    print(json.dumps(extract_api_map(sys.argv[1]), indent=2))
