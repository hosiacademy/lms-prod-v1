import yaml

# 1. Update docker-compose.yml
with open('docker-compose.yml', 'r') as f:
    data = yaml.safe_load(f)

# Apply explicit user mappings
if 'backend' in data['services']:
    data['services']['backend']['ports'] = ['7001:8000']
if 'socketio' in data['services']:
    data['services']['socketio']['ports'] = ['7002:8001']
if 'flower' in data['services']:
    data['services']['flower']['ports'] = ['7003:5555']
if 'sentry' in data['services']:
    data['services']['sentry']['ports'] = ['9000:9000']
if 'nginx' in data['services']:
    data['services']['nginx']['ports'] = ['7004:80', '7005:443']
if 'frontend' in data['services']:
    data['services']['frontend']['ports'] = ['7000:80']

with open('docker-compose.yml', 'w') as f:
    yaml.dump(data, f, sort_keys=False, default_flow_style=False)

# 2. Update docker-compose.prod.yml if it exists and has conflicting ports
try:
    with open('docker-compose.prod.yml', 'r') as f:
        prod_data = yaml.safe_load(f)
        
    for svc in ['backend', 'socketio', 'flower', 'sentry', 'nginx', 'frontend']:
        if svc in prod_data.get('services', {}):
            if 'ports' in prod_data['services'][svc]:
                # We can remove ports from prod to avoid conflict, as we set them explicitly in main yml.
                # Or set them identically. Let's just remove them so docker-compose.yml takes precedence.
                del prod_data['services'][svc]['ports']

    with open('docker-compose.prod.yml', 'w') as f:
        yaml.dump(prod_data, f, sort_keys=False, default_flow_style=False)
except FileNotFoundError:
    pass

