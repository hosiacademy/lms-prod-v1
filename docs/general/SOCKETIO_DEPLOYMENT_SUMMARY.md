# Socket.IO Deployment Summary

## Deployment Date
March 12, 2026

## Changes Made

### 1. Backend ASGI Configuration
**File:** `backend/lms_project/asgi.py`

- Configured unified ASGI application combining Django HTTP and Socket.IO WebSockets
- Added Redis manager for production scaling (when `ENVIRONMENT=production`)
- Registered all socket event handlers from `apps.communication.socket_events`
- Configured CORS, ping timeouts, and buffer sizes

### 2. Docker Configuration Updates

#### docker-compose.yml
- Changed backend from Gunicorn (WSGI) to Uvicorn (ASGI)
- Removed separate `socketio` service (now unified with backend)
- Added Socket.IO environment variables:
  - `SOCKETIO_ENABLED=True`
  - `SOCKETIO_REDIS_URL=redis://redis:6379/1`

#### docker-compose.override.yml
- Updated development server to use Uvicorn with hot-reload
- Added Socket.IO configuration for development

#### docker-compose.prod.yml
- Removed separate socketio service definition
- Increased backend resources for ASGI workload
- Added Socket.IO Redis configuration

### 3. Nginx Configuration
**File:** `nginx/nginx.prod.conf`

- Removed separate `socketio_upstream` (now uses `backend_upstream`)
- Updated `/socket.io/` location to proxy to backend (port 8000)
- Added WebSocket upgrade headers:
  - `proxy_set_header Upgrade $http_upgrade`
  - `proxy_set_header Connection "upgrade"`
- Set extended timeouts for long-lived WebSocket connections (86400s)

### 4. New Files Created
- `backend/uvicorn.conf.py` - Uvicorn configuration file

### 5. Updated Files
- `start-lms.sh` - Changed from `python manage.py runserver` to `uvicorn lms_project.asgi:application`

## Architecture

### Before (Fragmented)
```
┌─────────────┐     ┌──────────────┐
│  Backend    │     │   Socket.IO  │
│  Gunicorn   │     │   Separate   │
│  Port 8000  │     │   Port 8001  │
└─────────────┘     └──────────────┘
       │                    │
       └────────┬───────────┘
                │
           ┌────▼────┐
           │  Nginx  │
           └─────────┘
```

### After (Unified)
```
┌─────────────────────────┐
│  Backend (Uvicorn ASGI) │
│  - HTTP Requests        │
│  - WebSocket/Socket.IO  │
│  Port 8000              │
└─────────────────────────┘
         │
    ┌────▼────┐
    │  Nginx  │
    └─────────┘
```

## Container Ports

| Service     | Host Port | Container Port | Purpose                          |
|-------------|-----------|----------------|----------------------------------|
| Backend     | 7001      | 8000           | Django API + Socket.IO           |
| Frontend    | 7000      | 80             | Flutter Web (Nginx)              |
| Nginx       | 7004      | 80             | Reverse Proxy (HTTP)             |
| Nginx       | 7005      | 443            | Reverse Proxy (HTTPS)            |
| Flower      | 7003      | 5555           | Celery Monitor                   |
| Sentry      | 9000      | 9000           | Error Tracking                   |

## Socket.IO Chat Architecture

### Chat Room Types

1. **One-on-One Chat (Instructor ↔ Student)**
   - Room ID format: `direct_{user1}_{user2}` or `chat_{room_id}`
   - Created via: `ChatRoomService.get_or_create_instructor_student_chat()`
   - Frontend: `sio.emit('join_room', {'room': 'direct_10_25'})`

2. **Course Chatroom**
   - Room ID format: `course_learnership_{id}` or `chat_{room_id}`
   - Linked to: `ChatRoom` with `chat_type='course'`
   - Auto-populated via enrollment signals

3. **Community Chatroom**
   - Room ID format: `community_global`
   - Open to all authenticated users
   - Singleton ChatRoom in database

### Frontend Integration

```javascript
// 1. Connect with authentication
const socket = io('http://localhost:7001', {
  auth: { token: jwtToken }
});

// 2. Get user's chat rooms
socket.emit('get_chat_rooms');
socket.on('chat_rooms_list', (data) => {
  data.rooms.forEach(room => {
    socket.emit('join_room', { room: room.id });
  });
  // Join community room
  socket.emit('join_room', { room: 'community_global' });
});

// 3. Send message
socket.emit('send_message', {
  chatId: 'chat_123',
  content: 'Hello!',
  receiverId: 25
});

// 4. Receive message
socket.on('message', (data) => {
  console.log('New message:', data);
});

// 5. Presence
socket.on('user_online', (data) => {
  console.log('User online:', data.username);
});
```

## Testing

### Socket.IO Connection Test
```bash
# Test Socket.IO polling endpoint
curl "http://localhost:7001/socket.io/?EIO=4&transport=polling"

# Expected response:
# 0{"sid":"...", "upgrades":["websocket"], "pingTimeout":25000}
```

### Backend Health
```bash
curl http://localhost:7001/api/v1/courses/masterclasses/
```

## Deployment Commands

### Development
```bash
cd /home/tk/lms-prod
docker-compose up -d
```

### Production
```bash
cd /home/tk/lms-prod
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Restart Backend Only
```bash
docker-compose restart backend
```

### View Logs
```bash
# Backend logs
docker logs lms-prod-backend-1 --tail 100 -f

# Socket.IO specific logs
docker logs lms-prod-backend-1 2>&1 | grep -i "socket\|websocket"
```

## Troubleshooting

### WebSocket Connection Fails
1. Check Nginx WebSocket proxy configuration
2. Verify `Upgrade` and `Connection` headers
3. Check firewall allows WebSocket connections

### Messages Not Sending
1. Verify JWT token is passed in `auth.token`
2. Check `chatId` format matches backend expectations
3. Verify user is a ChatParticipant in the room

### Container Won't Start
```bash
# Check logs
docker logs lms-prod-backend-1

# Enter container for debugging
docker exec -it lms-prod-backend-1 bash

# Test database connection
docker exec lms-prod-backend-1 python -c "from django.db import connection; connection.ensure_connection(); print('DB OK')"
```

## Next Steps for Frontend

1. Update Flutter/React frontend to connect to `http://localhost:7001` or `https://your-domain:7005`
2. Pass JWT token in socket auth: `io(url, { auth: { token } })`
3. Implement chat UI with tabs for:
   - Direct Messages
   - Course Chats
   - Community Chat
4. Add online presence indicators using `user_online`/`user_offline` events

## Security Considerations

- JWT authentication required for all socket connections
- CORS configured with `cors_allowed_origins='*'` (restrict in production)
- Rate limiting on Socket.IO endpoints via Nginx
- WebSocket connections timeout after 24 hours of inactivity
