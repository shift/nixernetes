# Example 5: Real-Time Chat Application

Deploy a scalable real-time chat application with WebSockets, message persistence, and presence management.

## Overview

This example demonstrates:
- React frontend for chat UI
- Node.js backend with Socket.IO for WebSockets
- PostgreSQL for message persistence
- Redis for presence tracking and session management
- Nginx reverse proxy and load balancing
- Horizontal scaling with session affinity
- Real-time synchronization across clients

## Architecture

```
┌──────────────────────────────────────────────────┐
│          Browser Clients (Chat UI)               │
│          (React + Socket.IO Client)              │
└─────────────────┬────────────────────────────────┘
                  │ WebSocket
        ┌─────────▼──────────┐
        │  Nginx Load         │
        │  Balancer           │
        │  (Sticky Sessions)  │
        └─────────┬──────────┘
                  │
        ┌─────────┼─────────┐
        │         │         │
   ┌────▼──┐ ┌────▼──┐ ┌────▼──┐
   │ Chat  │ │ Chat  │ │ Chat  │
   │Server │ │Server │ │Server │ (3+ replicas)
   │1      │ │2      │ │3      │ (Node.js)
   └────┬──┘ └────┬──┘ └────┬──┘
        │         │         │
        └─────────┼─────────┘
                  │
        ┌─────────┼─────────┐
        │         │         │
   ┌────▼──┐ ┌────▼──┐ ┌────▼──┐
   │ Redis │ │  DB   │ │ Redis │
   │Cache  │ │Persist│ │ Pub   │
   │Session│ │Messages
   └───────┘ └───────┘ └───────┘
```

## Configuration

Create `realtime-chat.nix`:

```nix
{ nixernetes, pkgs }:

let
  modules = nixernetes.modules;
in

{
  # PostgreSQL for Message Persistence
  postgres = modules.database.postgresql {
    name = "chat-db";
    namespace = "default";
    version = "15-alpine";
    resources = {
      requests = { memory = "256Mi"; cpu = "100m"; };
      limits = { memory = "512Mi"; cpu = "500m"; };
    };
    persistence = {
      size = "50Gi";
      storageClass = "fast-ssd";
    };
    backupSchedule = "0 */6 * * *";  # Every 6 hours
  };

  # Redis for Session Management and Pub/Sub
  redis = modules.database.redis {
    name = "chat-redis";
    namespace = "default";
    version = "7-alpine";
    resources = {
      requests = { memory = "256Mi"; cpu = "100m"; };
      limits = { memory = "512Mi"; cpu = "500m"; };
    };
    persistence = {
      size = "10Gi";
      storageClass = "standard";
    };
  };

  # Chat Backend Service
  chatBackend = modules.workload.deployment {
    name = "chat-server";
    namespace = "default";
    image = "node:18-alpine";
    replicas = 3;
    
    containers = [{
      name = "chat";
      image = "node:18-alpine";
      ports = [{ name = "http"; containerPort = 4000; }];
      
      env = [
        { name = "NODE_ENV"; value = "production"; }
        { name = "PORT"; value = "4000"; }
        { name = "DATABASE_URL"; value = "postgresql://user:password@chat-db:5432/chat"; }
        { name = "REDIS_URL"; value = "redis://chat-redis:6379"; }
        { name = "LOG_LEVEL"; value = "info"; }
      ];

      livenessProbe = {
        httpGet = { path = "/health"; port = 4000; };
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        httpGet = { path = "/ready"; port = 4000; };
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };

      resources = {
        requests = { memory = "256Mi"; cpu = "100m"; };
        limits = { memory = "512Mi"; cpu = "500m"; };
      };
    }];

    strategy = {
      type = "RollingUpdate";
      rollingUpdate = {
        maxSurge = 1;
        maxUnavailable = 0;
      };
    };
  };

  # Chat Frontend
  chatFrontend = modules.workload.deployment {
    name = "chat-ui";
    namespace = "default";
    image = "nginx:alpine";
    replicas = 2;
    
    containers = [{
      name = "frontend";
      image = "nginx:alpine";
      ports = [{ name = "http"; containerPort = 80; }];
      
      volumeMounts = [
        { name = "nginx-config"; mountPath = "/etc/nginx/conf.d"; }
        { name = "app"; mountPath = "/usr/share/nginx/html"; }
      ];

      resources = {
        requests = { memory = "64Mi"; cpu = "50m"; };
        limits = { memory = "128Mi"; cpu = "100m"; };
      };
    }];

    volumes = [
      {
        name = "nginx-config";
        configMap = { name = "chat-nginx-config"; };
      }
      {
        name = "app";
        configMap = { name = "chat-frontend-app"; };
      }
    ];
  };

  # Nginx configuration for frontend
  nginxConfig = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = { name = "chat-nginx-config"; namespace = "default"; };
    data = {
      "default.conf" = ''
        upstream chat_backend {
          least_conn;
          server chat-server:4000;
          server chat-server:4000;
          server chat-server:4000;
          keepalive 32;
        }

        server {
          listen 80;
          server_name _;

          root /usr/share/nginx/html;
          index index.html;

          # Gzip compression
          gzip on;
          gzip_types text/plain text/css application/json application/javascript;
          gzip_min_length 1000;

          # Security headers
          add_header X-Content-Type-Options "nosniff" always;
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-XSS-Protection "1; mode=block" always;

          # WebSocket upgrade
          location /socket.io {
            proxy_pass http://chat_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_buffering off;
            proxy_cache off;
          }

          # API proxy
          location /api {
            proxy_pass http://chat_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          }

          # SPA fallback
          location / {
            try_files $uri /index.html;
          }
        }
      '';
    };
  };

  # Frontend React App (ConfigMap)
  frontendApp = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = { name = "chat-frontend-app"; namespace = "default"; };
    data = {
      "index.html" = ''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Real-Time Chat</title>
          <script src="https://cdn.socket.io/4.5.4/socket.io.min.js"></script>
          <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
          <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; }
            #root { height: 100vh; }
            .chat-container { display: flex; height: 100vh; }
            .sidebar { width: 300px; background: #2c3e50; color: white; overflow-y: auto; padding: 20px; }
            .main { flex: 1; display: flex; flex-direction: column; }
            .message-list { flex: 1; overflow-y: auto; padding: 20px; background: white; }
            .message { margin: 10px 0; padding: 10px; background: #ecf0f1; border-radius: 8px; }
            .message.own { background: #3498db; color: white; }
            .message-form { padding: 20px; border-top: 1px solid #ddd; }
            .message-form input { width: calc(100% - 60px); padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
            .message-form button { width: 50px; padding: 10px; background: #3498db; color: white; border: none; border-radius: 4px; cursor: pointer; }
            .user-list { list-style: none; }
            .user-item { padding: 8px; margin: 5px 0; background: rgba(255,255,255,0.1); border-radius: 4px; }
            .user-status { display: inline-block; width: 8px; height: 8px; background: #2ecc71; border-radius: 50%; margin-right: 8px; }
          </style>
        </head>
        <body>
          <div id="root"></div>
          <script type="text/babel">
            const { useState, useEffect, useRef } = React;

            function ChatApp() {
              const [messages, setMessages] = useState([]);
              const [users, setUsers] = useState([]);
              const [username, setUsername] = useState('');
              const [inputMessage, setInputMessage] = useState('');
              const socketRef = useRef(null);
              const messagesEndRef = useRef(null);

              useEffect(() => {
                socketRef.current = io();

                socketRef.current.on('connect', () => {
                  console.log('Connected to chat server');
                });

                socketRef.current.on('chat_message', (data) => {
                  setMessages(prev => [...prev, data]);
                });

                socketRef.current.on('user_joined', (data) => {
                  setUsers(prev => [...prev, data]);
                });

                socketRef.current.on('user_left', (data) => {
                  setUsers(prev => prev.filter(u => u.id !== data.id));
                });

                return () => socketRef.current?.disconnect();
              }, []);

              useEffect(() => {
                messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
              }, [messages]);

              const handleSetUsername = (e) => {
                if (e.key === 'Enter' && username) {
                  socketRef.current.emit('join', { username });
                  setUsername('');
                }
              };

              const handleSendMessage = (e) => {
                e.preventDefault();
                if (inputMessage.trim()) {
                  socketRef.current.emit('message', { text: inputMessage });
                  setInputMessage('');
                }
              };

              return (
                <div className="chat-container">
                  <div className="sidebar">
                    <h2>Chat Room</h2>
                    <input
                      type="text"
                      placeholder="Enter username"
                      value={username}
                      onChange={(e) => setUsername(e.target.value)}
                      onKeyPress={handleSetUsername}
                      style={{ width: '100%', marginTop: '10px', padding: '8px' }}
                    />
                    <h3 style={{ marginTop: '20px' }}>Online Users</h3>
                    <ul className="user-list">
                      {users.map(user => (
                        <li key={user.id} className="user-item">
                          <span className="user-status"></span>
                          {user.username}
                        </li>
                      ))}
                    </ul>
                  </div>
                  <div className="main">
                    <div className="message-list">
                      {messages.map((msg, idx) => (
                        <div key={idx} className={`message ${msg.own ? 'own' : ''}`}>
                          <strong>{msg.username}:</strong> {msg.text}
                        </div>
                      ))}
                      <div ref={messagesEndRef} />
                    </div>
                    <form onSubmit={handleSendMessage} className="message-form">
                      <input
                        type="text"
                        placeholder="Type message..."
                        value={inputMessage}
                        onChange={(e) => setInputMessage(e.target.value)}
                      />
                      <button type="submit">Send</button>
                    </form>
                  </div>
                </div>
              );
            }

            ReactDOM.render(<ChatApp />, document.getElementById('root'));
          </script>
        </body>
        </html>
      '';
    };
  };

  # Backend initialization script
  backendInitScript = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = { name = "chat-server-init"; namespace = "default"; };
    data = {
      "server.js" = ''
        const express = require('express');
        const { Server } = require('socket.io');
        const http = require('http');
        const pg = require('pg');
        const redis = require('redis');

        const app = express();
        const server = http.createServer(app);
        const io = new Server(server, { 
          cors: { origin: '*' },
          adapter: require('socket.io-redis')({
            host: process.env.REDIS_URL.split('//')[1].split(':')[0],
            port: 6379
          })
        });

        const pgPool = new pg.Pool({
          connectionString: process.env.DATABASE_URL
        });

        const redisClient = redis.createClient({
          url: process.env.REDIS_URL
        });

        // Create tables
        pgPool.query(`
          CREATE TABLE IF NOT EXISTS users (
            id VARCHAR(100) PRIMARY KEY,
            username VARCHAR(100) NOT NULL,
            joined_at TIMESTAMP DEFAULT NOW()
          );

          CREATE TABLE IF NOT EXISTS messages (
            id SERIAL PRIMARY KEY,
            user_id VARCHAR(100) REFERENCES users(id),
            text TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT NOW()
          );

          CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);
        `);

        // Health checks
        app.get('/health', (req, res) => res.json({ status: 'ok' }));
        app.get('/ready', (req, res) => res.json({ status: 'ready' }));

        // Socket.IO event handling
        io.on('connection', (socket) => {
          console.log(`User connected: ${socket.id}`);

          socket.on('join', async (data) => {
            const { username } = data;
            
            // Store in Redis for session
            await redisClient.set(`user:${socket.id}`, username);
            
            // Store in database
            await pgPool.query(
              'INSERT INTO users (id, username) VALUES ($1, $2)',
              [socket.id, username]
            );

            // Broadcast user joined
            io.emit('user_joined', { id: socket.id, username });
          });

          socket.on('message', async (data) => {
            const username = await redisClient.get(`user:${socket.id}`);
            const { text } = data;

            // Store in database
            await pgPool.query(
              'INSERT INTO messages (user_id, text) VALUES ($1, $2)',
              [socket.id, text]
            );

            // Broadcast message
            io.emit('chat_message', {
              id: socket.id,
              username,
              text,
              timestamp: new Date(),
              own: false
            });
          });

          socket.on('disconnect', async () => {
            const username = await redisClient.get(`user:${socket.id}`);
            await redisClient.del(`user:${socket.id}`);
            
            await pgPool.query(
              'DELETE FROM users WHERE id = $1',
              [socket.id]
            );

            io.emit('user_left', { id: socket.id, username });
            console.log(`User disconnected: ${socket.id}`);
          });
        });

        server.listen(4000, () => {
          console.log('Chat server running on port 4000');
        });
      '';
    };
  };

  # Service for backend
  chatBackendService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "chat-server"; namespace = "default"; };
    spec = {
      type = "ClusterIP";
      selector = { app = "chat-server"; };
      ports = [{ name = "http"; port = 4000; targetPort = 4000; }];
      sessionAffinity = "ClientIP";
      sessionAffinityConfig = {
        clientIPConfig = { timeoutSeconds = 3600; };
      };
    };
  };

  # Service for frontend
  chatFrontendService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "chat-ui"; namespace = "default"; };
    spec = {
      type = "LoadBalancer";
      selector = { app = "chat-ui"; };
      ports = [{ name = "http"; port = 80; targetPort = 80; }];
    };
  };

  # HPA for backend
  chatBackendHPA = {
    apiVersion = "autoscaling/v2";
    kind = "HorizontalPodAutoscaler";
    metadata = { name = "chat-server-hpa"; namespace = "default"; };
    spec = {
      scaleTargetRef = { apiVersion = "apps/v1"; kind = "Deployment"; name = "chat-server"; };
      minReplicas = 3;
      maxReplicas = 10;
      metrics = [
        {
          type = "Resource";
          resource = {
            name = "cpu";
            target = { type = "Utilization"; averageUtilization = 70; };
          };
        }
        {
          type = "Resource";
          resource = {
            name = "memory";
            target = { type = "Utilization"; averageUtilization = 80; };
          };
        }
      ];
    };
  };
}
```

## Step-by-Step Deployment

### 1. Deploy Infrastructure

```bash
mkdir my-chat-app
cd my-chat-app

nix develop
cp realtime-chat.nix config.nix
nix eval --apply "builtins.toJSON" -f config.nix > manifests.json
kubectl apply -f manifests.json
```

### 2. Access the Chat Application

```bash
# Get LoadBalancer IP
kubectl get svc chat-ui

# Access at http://EXTERNAL_IP

# Or port-forward
kubectl port-forward svc/chat-ui 8080:80
# http://localhost:8080
```

### 3. Monitor the Application

```bash
# View logs
kubectl logs -f deployment/chat-server
kubectl logs -f deployment/chat-ui

# Monitor scaling
kubectl get hpa -w

# Check connection count
kubectl exec -it pod/chat-redis-0 -- redis-cli INFO clients
```

## Performance Optimization

### Connection Pooling

```javascript
// Reuse database connections
const pgPool = new pg.Pool({
  max: 20,
  min: 5,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
});
```

### Message Caching

```javascript
// Cache recent messages in Redis
const CACHE_KEY = 'recent_messages';
const CACHE_TTL = 3600;  // 1 hour

socket.on('get_messages', async (callback) => {
  const cached = await redisClient.get(CACHE_KEY);
  if (cached) {
    return callback(JSON.parse(cached));
  }

  const result = await pgPool.query(
    'SELECT * FROM messages ORDER BY created_at DESC LIMIT 50'
  );
  
  await redisClient.setex(CACHE_KEY, CACHE_TTL, JSON.stringify(result.rows));
  callback(result.rows);
});
```

## Troubleshooting

### WebSocket Connection Issues

```bash
# Check if backend is reachable
kubectl exec -it pod/chat-ui-xxx -- curl http://chat-server:4000/health

# Monitor WebSocket connections
kubectl exec -it pod/chat-redis-0 -- redis-cli MONITOR

# Check socket.io adapter
kubectl logs deployment/chat-server | grep adapter
```

### Database Persistence Issues

```bash
# Check database size
kubectl exec -it pod/chat-db-0 -- psql -c "SELECT pg_size_pretty(pg_database_size('chat'));"

# Check message count
kubectl exec -it pod/chat-db-0 -- psql -c "SELECT COUNT(*) FROM messages;"

# Export messages for backup
kubectl exec -it pod/chat-db-0 -- pg_dump chat > backup.sql
```

## Production Considerations

### 1. Message Archival
- Archive old messages to cold storage
- Implement message retention policies
- Use data compression

### 2. Rate Limiting
- Limit messages per user
- Implement per-IP rate limits
- Handle spam prevention

### 3. Encryption
- Use TLS for all connections
- Encrypt sensitive data at rest
- Implement end-to-end encryption for messages

### 4. Monitoring
- Track active connections
- Monitor message throughput
- Alert on anomalies

### 5. Scalability
- Use Redis Cluster for high availability
- Implement PostgreSQL replication
- Deploy across multiple regions

## Advanced Features

### Typing Indicators

```javascript
socket.on('typing', () => {
  socket.broadcast.emit('user_typing', { username });
});

socket.on('stop_typing', () => {
  socket.broadcast.emit('user_stopped_typing', { username });
});
```

### Message Reactions

```javascript
socket.on('react', async (data) => {
  const { messageId, reaction } = data;
  
  await pgPool.query(
    'INSERT INTO reactions (message_id, reaction) VALUES ($1, $2)',
    [messageId, reaction]
  );
  
  io.emit('message_reacted', { messageId, reaction });
});
```

### Private Messages

```javascript
socket.on('private_message', async (data) => {
  const { toUserId, text } = data;
  
  io.to(toUserId).emit('private_message', {
    from: socket.id,
    text,
    timestamp: new Date()
  });
});
```

## Next Steps

1. Add user authentication and profiles
2. Implement message search and filtering
3. Create chat rooms/channels
4. Add file sharing capabilities
5. Implement message encryption

## Support

- Socket.IO Documentation: https://socket.io/docs/
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Redis Documentation: https://redis.io/documentation
