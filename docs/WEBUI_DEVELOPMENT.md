# Nixernetes Web UI - Development Guide

This guide outlines the architecture and implementation of a web UI for Nixernetes configuration management.

## Overview

The Nixernetes Web UI is a React-based application for:
- Visual configuration builder
- Module browser and documentation
- Configuration validation and preview
- YAML generation and deployment
- Project management and templates
- Real-time syntax checking

## Architecture

```
┌─────────────────────────────────────────────────────┐
│          React Web Application (Frontend)           │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐               │
│  │ Module Panel │  │ Editor Panel │               │
│  │ (sidebar)    │  │ (Nix Code)   │               │
│  └──────────────┘  └──────────────┘               │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐               │
│  │ Preview      │  │ Validation   │               │
│  │ (YAML)       │  │ (Errors)     │               │
│  └──────────────┘  └──────────────┘               │
└────────────────────┬────────────────────────────────┘
                     │
         ┌───────────▼────────────┐
         │   Node.js Backend      │
         │  (Express.js API)      │
         │                        │
         │ - Nix validation       │
         │ - YAML generation      │
         │ - Kubernetes preview   │
         │ - File operations      │
         └────────────┬───────────┘
                      │
         ┌────────────▼────────────┐
         │  Nix/nixernetes         │
         │  (Installed locally)    │
         │                         │
         │ - Config evaluation     │
         │ - Module loading        │
         │ - Error reporting       │
         └─────────────────────────┘
```

## Tech Stack

### Frontend
- **Framework:** React 18+
- **Build:** Vite (fast development)
- **UI Library:** Material-UI or shadcn/ui
- **Editor:** Monaco Editor (VS Code engine)
- **Validation:** ajv (JSON schema validation)
- **Styling:** Tailwind CSS

### Backend
- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Process Manager:** PM2
- **Shell Execution:** child_process (run nix commands)
- **File System:** fs/promises

### Development Tools
- **TypeScript:** Type safety
- **Testing:** Jest + React Testing Library
- **Linting:** ESLint + Prettier
- **Version Control:** Git

## Project Structure

```
nixernetes-ui/
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Editor/
│   │   │   │   ├── CodeEditor.tsx
│   │   │   │   ├── ValidationPanel.tsx
│   │   │   │   └── PreviewPanel.tsx
│   │   │   ├── ModulePanel/
│   │   │   │   ├── ModuleBrowser.tsx
│   │   │   │   ├── ModuleDetails.tsx
│   │   │   │   └── ModuleSearch.tsx
│   │   │   ├── Layout/
│   │   │   │   ├── Header.tsx
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   └── MainLayout.tsx
│   │   │   └── Common/
│   │   │       ├── Tooltip.tsx
│   │   │       ├── Modal.tsx
│   │   │       └── Alert.tsx
│   │   ├── pages/
│   │   │   ├── Editor.tsx
│   │   │   ├── Projects.tsx
│   │   │   ├── Documentation.tsx
│   │   │   └── Deployment.tsx
│   │   ├── services/
│   │   │   ├── api.ts (API calls)
│   │   │   ├── storage.ts (localStorage)
│   │   │   └── validation.ts
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── public/
│   ├── vite.config.ts
│   ├── tsconfig.json
│   └── package.json
│
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   │   ├── config.ts (config endpoints)
│   │   │   ├── modules.ts (module endpoints)
│   │   │   ├── validation.ts (validation endpoints)
│   │   │   └── deployment.ts (deployment endpoints)
│   │   ├── services/
│   │   │   ├── nixService.ts (nix execution)
│   │   │   ├── validationService.ts
│   │   │   ├── yamlService.ts
│   │   │   └── kubeService.ts
│   │   ├── types/
│   │   │   ├── config.ts
│   │   │   ├── module.ts
│   │   │   └── validation.ts
│   │   ├── middleware/
│   │   │   ├── errorHandler.ts
│   │   │   ├── cors.ts
│   │   │   └── auth.ts (optional)
│   │   ├── utils/
│   │   │   ├── logger.ts
│   │   │   └── validators.ts
│   │   └── index.ts (Express setup)
│   ├── .env.example
│   ├── tsconfig.json
│   ├── package.json
│   └── Dockerfile
│
└── docker-compose.yml
```

## Phase 1: MVP (Weeks 1-2)

### Core Features

1. **Code Editor**
   - Monaco Editor for Nix syntax
   - Syntax highlighting
   - Basic autocomplete
   - Line numbers and folding

2. **Module Browser**
   - List all 35 modules
   - Search functionality
   - Quick documentation lookup
   - Copy module usage

3. **Real-time Validation**
   - Call backend to validate nix syntax
   - Show errors and warnings
   - Suggest fixes

4. **YAML Preview**
   - Generate Kubernetes YAML
   - Display in formatted view
   - Copy/download YAML

5. **Project Management**
   - New/open/save projects
   - localStorage persistence
   - Recent projects list

### Implementation

#### Frontend Setup (Vite + React)

```bash
# Create project
npm create vite@latest nixernetes-ui -- --template react-ts
cd nixernetes-ui
npm install

# Install dependencies
npm install \
  @monaco-editor/react \
  @mui/material @emotion/react @emotion/styled \
  axios \
  typescript

npm run dev
```

#### Backend Setup (Node.js + Express)

```bash
# Create backend
mkdir backend && cd backend
npm init -y

# Install dependencies
npm install \
  express \
  typescript \
  ts-node \
  cors \
  dotenv \
  axios

npx tsc --init
npm run dev
```

## Phase 2: Enhancement (Weeks 3-4)

### Additional Features

1. **Deployment Interface**
   - Connect to cluster
   - Dry-run deployments
   - Apply configurations
   - Monitor rollout status

2. **Configuration Templates**
   - Pre-built templates
   - Quick-start configurations
   - Export/import templates

3. **Kubernetes Integration**
   - Cluster discovery
   - Resource visualization
   - Pod/service management

4. **Advanced Editing**
   - Full intellisense
   - Jump to definition
   - Hover documentation

## API Specification

### Backend Endpoints

```
POST /api/validate
  - Validate Nix configuration
  - Body: { config: string }
  - Response: { valid: bool, errors: [] }

POST /api/generate
  - Generate Kubernetes YAML
  - Body: { config: string }
  - Response: { yaml: string }

GET /api/modules
  - List available modules
  - Response: { modules: [] }

GET /api/modules/:name
  - Get module details
  - Response: { name, description, builders, docs }

POST /api/deploy
  - Deploy to cluster
  - Body: { yaml: string, dryRun: bool }
  - Response: { success: bool, message: string }

GET /api/projects
  - List saved projects
  - Response: { projects: [] }

POST /api/projects
  - Create new project
  - Body: { name: string, config: string }
  - Response: { id: string }

GET /api/projects/:id
  - Get project details
  - Response: { id, name, config, created, modified }

PUT /api/projects/:id
  - Update project
  - Body: { name: string, config: string }
  - Response: { updated: bool }

DELETE /api/projects/:id
  - Delete project
  - Response: { deleted: bool }
```

## Core Components

### CodeEditor.tsx

```typescript
import React, { useState, useCallback } from 'react';
import Editor from '@monaco-editor/react';
import { api } from '../services/api';

export const CodeEditor: React.FC = () => {
  const [code, setCode] = useState('');
  const [isValidating, setIsValidating] = useState(false);
  const [errors, setErrors] = useState<string[]>([]);

  const handleValidate = useCallback(async () => {
    setIsValidating(true);
    try {
      const result = await api.validateConfig(code);
      setErrors(result.errors);
    } finally {
      setIsValidating(false);
    }
  }, [code]);

  return (
    <div className="editor-container">
      <Editor
        height="100%"
        defaultLanguage="nix"
        value={code}
        onChange={(value) => setCode(value || '')}
        options={{
          fontSize: 14,
          lineNumbers: 'on',
          wordWrap: 'on',
        }}
      />
      <button onClick={handleValidate} disabled={isValidating}>
        Validate
      </button>
      {errors.length > 0 && (
        <div className="errors">
          {errors.map((error, i) => (
            <div key={i} className="error">{error}</div>
          ))}
        </div>
      )}
    </div>
  );
};
```

### ModuleBrowser.tsx

```typescript
import React, { useState, useEffect } from 'react';
import { api } from '../services/api';

export const ModuleBrowser: React.FC = () => {
  const [modules, setModules] = useState<any[]>([]);
  const [search, setSearch] = useState('');
  const [selected, setSelected] = useState<any | null>(null);

  useEffect(() => {
    api.getModules().then(setModules);
  }, []);

  const filtered = modules.filter(m =>
    m.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="module-browser">
      <input
        type="text"
        placeholder="Search modules..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
      />
      <ul>
        {filtered.map(module => (
          <li
            key={module.name}
            onClick={() => setSelected(module)}
            className={selected?.name === module.name ? 'active' : ''}
          >
            {module.name}
          </li>
        ))}
      </ul>
      {selected && (
        <div className="module-details">
          <h3>{selected.name}</h3>
          <p>{selected.description}</p>
          <div className="builders">
            {selected.builders.map((b: any) => (
              <div key={b.name}>{b.name}</div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
```

## Deployment

### Docker Setup

Create `Dockerfile`:

```dockerfile
# Build stage
FROM node:18 AS builder
WORKDIR /app

# Copy and build frontend
COPY frontend/ ./frontend/
WORKDIR /app/frontend
RUN npm ci && npm run build

# Copy and build backend
WORKDIR /app
COPY backend/ ./backend/
WORKDIR /app/backend
RUN npm ci && npm run build

# Runtime stage
FROM node:18-slim
RUN apt-get update && apt-get install -y nix && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/backend/dist ./backend/dist
COPY --from=builder /app/backend/node_modules ./backend/node_modules
COPY --from=builder /app/frontend/dist ./frontend/public

EXPOSE 3000 5000
CMD ["node", "backend/dist/index.js"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  ui:
    build: .
    ports:
      - "3000:3000"  # Frontend
      - "5000:5000"  # Backend API
    environment:
      - NODE_ENV=development
      - NIXERNETES_PATH=/usr/local/nixernetes
    volumes:
      - ./projects:/app/projects
    depends_on:
      - nix

  nix:
    image: nixos/nix:latest
    volumes:
      - /nix:/nix
```

## Development Workflow

```bash
# Install dependencies
cd frontend && npm install
cd ../backend && npm install

# Start development servers
# Terminal 1: Frontend
cd frontend && npm run dev

# Terminal 2: Backend
cd backend && npm run dev

# Visit http://localhost:5173
```

## Testing Strategy

### Unit Tests (Jest)

```typescript
// test/validation.test.ts
describe('Validation Service', () => {
  it('should validate correct config', async () => {
    const result = await validateConfig('{}');
    expect(result.valid).toBe(true);
  });

  it('should catch syntax errors', async () => {
    const result = await validateConfig('{ invalid');
    expect(result.valid).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
  });
});
```

### Integration Tests

```typescript
// test/api.integration.test.ts
describe('API Integration', () => {
  it('should validate and generate YAML', async () => {
    const response = await request(app)
      .post('/api/generate')
      .send({ config: simpleConfig });
    
    expect(response.status).toBe(200);
    expect(response.body.yaml).toBeDefined();
  });
});
```

## Performance Optimization

1. **Memoization:** Use React.memo for components
2. **Code Splitting:** Lazy load heavy modules
3. **Caching:** Cache module list and documentation
4. **Debouncing:** Debounce validation on code changes
5. **Worker Threads:** Offload nix evaluation to worker

## Security Considerations

1. **Input Validation:** Validate all user input
2. **Safe Execution:** Run nix in isolated environment
3. **Rate Limiting:** Limit API calls
4. **CORS:** Restrict to trusted origins
5. **Authentication:** Optional auth for multi-user setup

## Future Enhancements

1. **Collaborative Editing:** Real-time multi-user editing
2. **Git Integration:** Push/pull configurations from GitHub
3. **CI/CD Integration:** Deploy via GitHub Actions
4. **Observability:** Monitor deployed applications
5. **Advanced Validations:** Pre-flight checks for deployments
6. **Module Editor:** Create custom modules in UI
7. **Marketplace:** Share and discover community modules
8. **Mobile Support:** Responsive design for tablets/phones

## Success Metrics

- ✅ 80% faster config creation vs. manual editing
- ✅ <2s validation time
- ✅ <3s YAML generation time
- ✅ 95%+ uptime
- ✅ <2s page load time
- ✅ 100% module coverage
- ✅ Zero validation errors after deployment

## Getting Started

1. Clone the repository
2. Follow "Development Workflow" section above
3. Create first module browser feature
4. Add code editor with validation
5. Implement YAML generation
6. Add project management
7. Test with real configurations
8. Deploy with Docker

---

This is a foundation for a production-ready Nixernetes Web UI.
The modular architecture allows for incremental development and
deployment of features over time.

