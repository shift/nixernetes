# Stage 1: Build backend
FROM node:20-alpine AS backend-builder

WORKDIR /app/backend

COPY backend/package*.json ./
RUN npm ci

COPY backend/tsconfig.json ./
COPY backend/src ./src

RUN npm run build

# Stage 2: Build frontend
FROM node:20-alpine AS frontend-builder

WORKDIR /app/web-ui

COPY web-ui/package*.json ./
RUN npm ci

COPY web-ui/src ./src
COPY web-ui/public ./public
COPY web-ui/tsconfig.json ./
COPY web-ui/tailwind.config.js ./
COPY web-ui/vite.config.ts ./
COPY web-ui/index.html ./

RUN npm run build

# Stage 3: Runtime
FROM node:20-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy backend
COPY --from=backend-builder --chown=nodejs:nodejs /app/backend/dist ./backend/dist
COPY --from=backend-builder --chown=nodejs:nodejs /app/backend/package*.json ./backend/

# Install production dependencies for backend
WORKDIR /app/backend
RUN npm ci --only=production

# Copy frontend
WORKDIR /app
COPY --from=frontend-builder --chown=nodejs:nodejs /app/web-ui/dist ./web-ui/dist

# Copy public assets
COPY --chown=nodejs:nodejs web-ui/public ./web-ui/public 2>/dev/null || true

# Use non-root user
USER nodejs

# Set environment
ENV NODE_ENV=production
ENV PORT=8080
ENV DB_PATH=/app/data/nixernetes.db

# Expose ports
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:8080/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start backend server
CMD ["node", "backend/dist/server.js"]
