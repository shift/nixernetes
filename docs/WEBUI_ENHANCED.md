# Web UI Development Guide - Enhanced Architecture

Interactive web interface for Nixernetes with real-time configuration editing, validation, and deployment.

## Complete Architecture & Implementation Plan

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Web Browsers (Clients)                   │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP/WebSocket
        ┌────────────▼──────────────┐
        │  Frontend (React + Vite)  │
        │  - Monaco Editor          │
        │  - Module Browser         │
        │  - Project Manager        │
        └────────────┬──────────────┘
                     │ API Calls
        ┌────────────▼──────────────────────┐
        │  Backend (Node.js + Express.js)   │
        │  - Validation Engine              │
        │  - YAML Generator                 │
        │  - Module Registry                │
        │  - K8s Integration                │
        └────────────┬──────────────────────┘
                     │
        ┌────────────┴──────────┬───────────────┐
        │                       │               │
    ┌───▼───┐            ┌─────▼────┐    ┌─────▼────┐
    │  Nix  │            │ SQLite/  │    │Kubernetes│
    │ Engine│            │  File    │    │  API     │
    └───────┘            └──────────┘    └──────────┘
```

## Phase 1: MVP (Weeks 1-2)

### Frontend Components

Create `webui/frontend/src/App.tsx`:

```typescript
import React, { useState } from 'react';
import { Box, Container, Tabs, TabList, TabPanels, Tab, TabPanel } from '@chakra-ui/react';
import CodeEditor from './components/CodeEditor';
import ModuleBrowser from './components/ModuleBrowser';
import ProjectManager from './components/ProjectManager';
import YAMLPreview from './components/YAMLPreview';

function App() {
  const [config, setConfig] = useState('');
  const [yaml, setYaml] = useState('');

  return (
    <Container maxW="100vw" h="100vh" p={0}>
      <Tabs h="100%" display="flex" flexDirection="column">
        <TabList>
          <Tab>Code Editor</Tab>
          <Tab>Modules</Tab>
          <Tab>Projects</Tab>
          <Tab>Preview</Tab>
        </TabList>

        <TabPanels flex="1" overflow="auto">
          <TabPanel h="100%">
            <CodeEditor value={config} onChange={setConfig} onGenerate={setYaml} />
          </TabPanel>
          <TabPanel h="100%">
            <ModuleBrowser onSelect={(module) => {
              setConfig(prev => prev + '\n# ' + module.name);
            }} />
          </TabPanel>
          <TabPanel h="100%">
            <ProjectManager />
          </TabPanel>
          <TabPanel h="100%">
            <YAMLPreview yaml={yaml} />
          </TabPanel>
        </TabPanels>
      </Tabs>
    </Container>
  );
}

export default App;
```

Create `webui/frontend/src/components/CodeEditor.tsx`:

```typescript
import React, { useRef, useEffect } from 'react';
import { Box, Button, HStack, VStack, useToast } from '@chakra-ui/react';
import Editor from '@monaco-editor/react';

interface CodeEditorProps {
  value: string;
  onChange: (value: string) => void;
  onGenerate: (yaml: string) => void;
}

export default function CodeEditor({ value, onChange, onGenerate }: CodeEditorProps) {
  const toast = useToast();
  const editorRef = useRef(null);

  const handleValidate = async () => {
    try {
      const response = await fetch('/api/validate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ config: value })
      });
      const result = await response.json();
      
      if (result.valid) {
        toast({
          title: 'Valid configuration',
          status: 'success',
          duration: 3000
        });
      } else {
        toast({
          title: 'Validation failed',
          description: result.errors.join('\n'),
          status: 'error',
          duration: 5000
        });
      }
    } catch (error) {
      toast({
        title: 'Error',
        description: error.message,
        status: 'error'
      });
    }
  };

  const handleGenerate = async () => {
    try {
      const response = await fetch('/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ config: value })
      });
      const result = await response.json();
      
      if (result.yaml) {
        onGenerate(result.yaml);
        toast({
          title: 'YAML generated',
          status: 'success'
        });
      }
    } catch (error) {
      toast({
        title: 'Generation failed',
        description: error.message,
        status: 'error'
      });
    }
  };

  const handleDeploy = async () => {
    try {
      const response = await fetch('/api/deploy', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ config: value })
      });
      const result = await response.json();
      
      toast({
        title: 'Deployment initiated',
        description: result.message,
        status: 'success'
      });
    } catch (error) {
      toast({
        title: 'Deployment failed',
        description: error.message,
        status: 'error'
      });
    }
  };

  return (
    <VStack h="100%" spacing={4} p={4}>
      <HStack>
        <Button colorScheme="blue" onClick={handleValidate}>
          Validate
        </Button>
        <Button colorScheme="green" onClick={handleGenerate}>
          Generate YAML
        </Button>
        <Button colorScheme="purple" onClick={handleDeploy}>
          Deploy
        </Button>
      </HStack>
      
      <Box flex="1" w="100%" border="1px" borderColor="gray.200" borderRadius="md">
        <Editor
          height="100%"
          defaultLanguage="nix"
          value={value}
          onChange={(val) => onChange(val || '')}
          options={{
            minimap: { enabled: false },
            wordWrap: 'on',
            formatOnPaste: true,
            fontSize: 13
          }}
        />
      </Box>
    </VStack>
  );
}
```

Create `webui/frontend/src/components/ModuleBrowser.tsx`:

```typescript
import React, { useState, useEffect } from 'react';
import {
  Box,
  Input,
  VStack,
  HStack,
  Text,
  Badge,
  useToast,
  Spinner,
  SimpleGrid
} from '@chakra-ui/react';

interface Module {
  name: string;
  description: string;
  category: string;
  builders: string[];
}

interface ModuleBrowserProps {
  onSelect: (module: Module) => void;
}

export default function ModuleBrowser({ onSelect }: ModuleBrowserProps) {
  const [modules, setModules] = useState<Module[]>([]);
  const [filtered, setFiltered] = useState<Module[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const toast = useToast();

  useEffect(() => {
    fetchModules();
  }, []);

  const fetchModules = async () => {
    try {
      const response = await fetch('/api/modules');
      const data = await response.json();
      setModules(data.modules);
      setFiltered(data.modules);
    } catch (error) {
      toast({
        title: 'Failed to load modules',
        description: error.message,
        status: 'error'
      });
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = (term: string) => {
    setSearch(term);
    const results = modules.filter(m =>
      m.name.toLowerCase().includes(term.toLowerCase()) ||
      m.description.toLowerCase().includes(term.toLowerCase())
    );
    setFiltered(results);
  };

  if (loading) {
    return <Spinner />;
  }

  return (
    <VStack h="100%" spacing={4} p={4} align="stretch">
      <Input
        placeholder="Search modules..."
        value={search}
        onChange={(e) => handleSearch(e.target.value)}
      />
      
      <SimpleGrid columns={2} spacing={4} overflow="auto" flex="1">
        {filtered.map((module) => (
          <Box
            key={module.name}
            p={4}
            border="1px"
            borderColor="gray.200"
            borderRadius="md"
            cursor="pointer"
            _hover={{ boxShadow: 'md', borderColor: 'blue.300' }}
            onClick={() => onSelect(module)}
          >
            <HStack justify="space-between" mb={2}>
              <Text fontWeight="bold">{module.name}</Text>
              <Badge colorScheme="blue">{module.category}</Badge>
            </HStack>
            <Text fontSize="sm" color="gray.600" mb={2}>
              {module.description}
            </Text>
            <HStack spacing={1} wrap="wrap">
              {module.builders.slice(0, 3).map((builder) => (
                <Badge key={builder} colorScheme="green" fontSize="xs">
                  {builder}
                </Badge>
              ))}
              {module.builders.length > 3 && (
                <Badge fontSize="xs">+{module.builders.length - 3}</Badge>
              )}
            </HStack>
          </Box>
        ))}
      </SimpleGrid>
    </VStack>
  );
}
```

### Backend API Specification

Create `webui/backend/src/api/routes.ts`:

```typescript
import express, { Request, Response } from 'express';
import { validateConfig, generateYAML, deployConfig } from '../services';
import { getModules, getModuleDetails } from '../services/moduleRegistry';

const router = express.Router();

// Validation endpoint
router.post('/validate', async (req: Request, res: Response) => {
  try {
    const { config } = req.body;
    const errors = await validateConfig(config);
    
    res.json({
      valid: errors.length === 0,
      errors,
      warnings: []
    });
  } catch (error) {
    res.status(500).json({ 
      valid: false, 
      errors: [error.message] 
    });
  }
});

// YAML generation endpoint
router.post('/generate', async (req: Request, res: Response) => {
  try {
    const { config } = req.body;
    const yaml = await generateYAML(config);
    
    res.json({
      yaml,
      stats: {
        resources: countResources(yaml),
        services: countServices(yaml),
        deployments: countDeployments(yaml)
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Deployment endpoint
router.post('/deploy', async (req: Request, res: Response) => {
  try {
    const { config, namespace = 'default', dryRun = false } = req.body;
    const result = await deployConfig(config, namespace, dryRun);
    
    res.json({
      success: true,
      message: dryRun ? 'Dry run completed' : 'Deployment initiated',
      result
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Module list endpoint
router.get('/modules', async (req: Request, res: Response) => {
  try {
    const modules = await getModules();
    res.json({ modules });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Module details endpoint
router.get('/modules/:name', async (req: Request, res: Response) => {
  try {
    const module = await getModuleDetails(req.params.name);
    res.json(module);
  } catch (error) {
    res.status(404).json({ error: 'Module not found' });
  }
});

export default router;
```

## Phase 2: Intermediate Features (Weeks 3-4)

### Project Management

Create `webui/frontend/src/components/ProjectManager.tsx`:

```typescript
import React, { useState, useEffect } from 'react';
import {
  VStack,
  Button,
  Input,
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  useToast,
  Modal,
  ModalOverlay,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalCloseButton,
  ModalFooter,
  useDisclosure,
  FormControl,
  FormLabel
} from '@chakra-ui/react';

interface Project {
  id: string;
  name: string;
  template: string;
  created: string;
  updated: string;
}

export default function ProjectManager() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [newProjectName, setNewProjectName] = useState('');
  const { isOpen, onOpen, onClose } = useDisclosure();
  const toast = useToast();

  useEffect(() => {
    fetchProjects();
  }, []);

  const fetchProjects = async () => {
    try {
      const response = await fetch('/api/projects');
      const data = await response.json();
      setProjects(data.projects);
    } catch (error) {
      toast({ title: 'Error', description: error.message, status: 'error' });
    }
  };

  const createProject = async () => {
    try {
      const response = await fetch('/api/projects', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: newProjectName })
      });
      const data = await response.json();
      setProjects([...projects, data.project]);
      setNewProjectName('');
      onClose();
      toast({ title: 'Project created', status: 'success' });
    } catch (error) {
      toast({ title: 'Error', description: error.message, status: 'error' });
    }
  };

  return (
    <VStack spacing={4} align="stretch" p={4}>
      <Button colorScheme="blue" onClick={onOpen}>
        New Project
      </Button>

      <Table>
        <Thead>
          <Tr>
            <Th>Name</Th>
            <Th>Template</Th>
            <Th>Created</Th>
            <Th>Actions</Th>
          </Tr>
        </Thead>
        <Tbody>
          {projects.map(project => (
            <Tr key={project.id}>
              <Td>{project.name}</Td>
              <Td>{project.template}</Td>
              <Td>{new Date(project.created).toLocaleDateString()}</Td>
              <Td>
                <Button size="sm" colorScheme="blue" mr={2}>
                  Open
                </Button>
                <Button size="sm" colorScheme="red">
                  Delete
                </Button>
              </Td>
            </Tr>
          ))}
        </Tbody>
      </Table>

      <Modal isOpen={isOpen} onClose={onClose}>
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>Create New Project</ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            <FormControl>
              <FormLabel>Project Name</FormLabel>
              <Input
                value={newProjectName}
                onChange={(e) => setNewProjectName(e.target.value)}
              />
            </FormControl>
          </ModalBody>
          <ModalFooter>
            <Button variant="ghost" mr={3} onClick={onClose}>
              Cancel
            </Button>
            <Button colorScheme="blue" onClick={createProject}>
              Create
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </VStack>
  );
}
```

## Phase 3: Production Deployment

### Docker Deployment

Create `webui/Dockerfile`:

```dockerfile
# Frontend build stage
FROM node:18 as frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend .
RUN npm run build

# Backend stage
FROM node:18
WORKDIR /app

# Copy backend
COPY backend/package*.json ./
RUN npm install --production
COPY backend ./

# Copy built frontend
COPY --from=frontend-build /app/frontend/dist ./public

EXPOSE 3000
CMD ["npm", "start"]
```

### Kubernetes Deployment

Create `webui/k8s-deployment.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: webui-config
data:
  backend-url: "http://localhost:3000"

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nixernetes-webui
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nixernetes-webui
  template:
    metadata:
      labels:
        app: nixernetes-webui
    spec:
      containers:
      - name: webui
        image: nixernetes/webui:latest
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: production
        - name: PORT
          value: "3000"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: nixernetes-webui
spec:
  type: LoadBalancer
  selector:
    app: nixernetes-webui
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
```

## Backend Implementation Details

### Validation Service

Create `webui/backend/src/services/validator.ts`:

```typescript
import { execSync } from 'child_process';

export async function validateConfig(config: string): Promise<string[]> {
  const errors: string[] = [];

  try {
    // Syntax validation
    const result = execSync('nix eval --strict', {
      input: config,
      encoding: 'utf-8'
    });
  } catch (error) {
    errors.push(`Syntax error: ${error.message}`);
  }

  // Semantic validation
  const checks = [
    validateRequiredFields,
    validateResourceNames,
    validateNetworking,
    validateStorageConfig
  ];

  for (const check of checks) {
    const result = check(config);
    if (result) errors.push(result);
  }

  return errors;
}

function validateRequiredFields(config: string): string | null {
  const required = ['apiVersion', 'kind', 'metadata'];
  for (const field of required) {
    if (!config.includes(field)) {
      return `Missing required field: ${field}`;
    }
  }
  return null;
}

function validateResourceNames(config: string): string | null {
  const namePattern = /name = "([a-z0-9-]+)"/g;
  const matches = [...config.matchAll(namePattern)];
  
  for (const match of matches) {
    if (!/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/.test(match[1])) {
      return `Invalid resource name: ${match[1]}`;
    }
  }
  return null;
}

function validateNetworking(config: string): string | null {
  // Add networking validation logic
  return null;
}

function validateStorageConfig(config: string): string | null {
  // Add storage validation logic
  return null;
}
```

## Development Workflow

### Setup Instructions

```bash
# Clone repository
git clone https://github.com/nixernetes/webui.git
cd webui

# Frontend setup
cd frontend
npm install
npm run dev

# Backend setup (in another terminal)
cd ../backend
npm install
npm run dev

# Both run on localhost:3000 and localhost:3001
```

### Project Structure

```
webui/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── CodeEditor.tsx
│   │   │   ├── ModuleBrowser.tsx
│   │   │   ├── ProjectManager.tsx
│   │   │   ├── YAMLPreview.tsx
│   │   │   └── DeploymentStatus.tsx
│   │   ├── services/
│   │   │   └── api.ts
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── package.json
│   └── vite.config.ts
│
├── backend/
│   ├── src/
│   │   ├── services/
│   │   │   ├── validator.ts
│   │   │   ├── generator.ts
│   │   │   ├── deployer.ts
│   │   │   └── moduleRegistry.ts
│   │   ├── api/
│   │   │   └── routes.ts
│   │   ├── middleware/
│   │   │   └── auth.ts
│   │   └── server.ts
│   ├── package.json
│   └── tsconfig.json
│
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
└── README.md
```

## Testing Strategy

### Unit Tests

```bash
# Frontend
cd frontend
npm test

# Backend
cd backend
npm test
```

### Integration Tests

```bash
# Start services
docker-compose up

# Run tests
npm run test:integration
```

## Performance Targets

- **Editor Response**: <100ms for syntax highlighting
- **Validation**: <500ms for large configs
- **YAML Generation**: <1000ms
- **Module Search**: <200ms
- **Bundle Size**: <500KB (gzipped)

## Deployment Checklist

- [ ] Code review completed
- [ ] All tests passing
- [ ] Security scanning passed
- [ ] Performance benchmarks met
- [ ] Documentation updated
- [ ] Release notes prepared
- [ ] Docker image built and tested
- [ ] Kubernetes manifests validated
- [ ] User guide completed

## Future Enhancements

1. **Advanced Features**
   - Git integration for version control
   - Collaborative editing (real-time sync)
   - AI-powered configuration suggestions
   - Policy-as-code validation

2. **Integrations**
   - GitHub/GitLab integration
   - Slack notifications
   - OIDC/SAML authentication
   - Terraform Cloud integration

3. **Analytics**
   - Configuration history and audit trail
   - Usage analytics
   - Cost estimation
   - Performance recommendations

## Support

- GitHub Issues: https://github.com/nixernetes/webui/issues
- Documentation: https://github.com/nixernetes/webui/blob/main/README.md
- Slack Channel: #webui-dev
