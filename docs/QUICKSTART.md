Quick Start Guide

Get Nixernetes running locally in 5 minutes.

Prerequisites

- Node.js 18+ (check: node --version)
- npm or yarn (check: npm --version)

Option 1: Local Development (Recommended for Development)

1. Start Backend

   cd backend
   npm install
   npm run dev

   Backend running at http://localhost:8080

2. Start Frontend (in new terminal)

   cd web-ui
   npm install
   npm run dev

   Frontend running at http://localhost:5173

3. Open Browser

   http://localhost:5173

Done! Both frontend and backend are running.

Option 2: Docker Compose (Complete Stack)

1. Start Everything

   docker-compose up

   Waits for services to be ready (~30 seconds)

2. Open Browser

   http://localhost:5173

3. Stop Everything

   docker-compose down

Option 3: Production Docker Image

1. Build Image

   docker build -t nixernetes:latest .

2. Run Container

   docker run -p 8080:8080 nixernetes:latest

3. Access

   http://localhost:8080

Common Tasks

View Backend Logs

   cd backend
   npm run dev

   Or with Docker:
   docker-compose logs -f backend

View Frontend Logs

   cd web-ui
   npm run dev

   Or with Docker:
   docker-compose logs -f frontend

Test API

Check if backend is working:

   curl http://localhost:8080/health

Response should be:
   {"status":"ok"}

Create a Project

   curl -X POST http://localhost:8080/api/projects \
     -H "Content-Type: application/json" \
     -d '{"name":"My Project","owner":"admin"}'

Access API Documentation

See docs/API.md for complete endpoint reference.

Database

The backend automatically creates a SQLite database at:
   - Local: ./backend/nixernetes.db
   - Docker: /app/data/nixernetes.db

Reset Database

   rm backend/nixernetes.db
   docker-compose down -v  # Also removes Docker volume

Next Steps

Read the full documentation:

- docs/DEPLOYMENT.md - Production deployment guide
- docs/API.md - Complete API reference
- docs/MANIFEST_VALIDATION.md - Manifest validation system
- docs/DEVELOPMENT.md - Development guide

Troubleshooting

Port 8080 or 5173 already in use?

Option A: Kill the process
   lsof -i :8080  # Find process
   kill -9 <PID>   # Kill it

Option B: Use different ports
   PORT=9000 npm run dev     # Backend on 9000
   VITE_PORT=5174 npm run dev # Frontend on 5174

Database errors?

   rm backend/nixernetes.db
   cd backend
   npm run db:migrate

Frontend won't connect to backend?

1. Check backend is running
   curl http://localhost:8080/health

2. Check frontend logs in browser console
   - Press F12 in browser
   - Look for API errors

3. Verify API URL in frontend
   - For dev: http://localhost:8080
   - For production: same origin as frontend

Module installation issues?

   # Clear npm cache
   npm cache clean --force

   # Reinstall dependencies
   rm -rf node_modules package-lock.json
   npm install

Getting Help

- Check docs/ directory for guides
- See docs/TROUBLESHOOTING.md for common issues
- Check GitHub issues for similar problems
