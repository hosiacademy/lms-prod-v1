"""
Uvicorn configuration file for ASGI deployment.
"""
import os

# Server socket
host = os.getenv("UVICORN_HOST", "0.0.0.0")
port = int(os.getenv("UVICORN_PORT", 8000))

# Workers
workers = int(os.getenv("UVICORN_WORKERS", 4))

# Logging
log_level = os.getenv("UVICORN_LOG_LEVEL", "info")
access_log = True

# Performance
loop = "auto"
http = "auto"
ws = "auto"
lifespan = "on"

# Limits
limit_concurrency = 1000
limit_max_requests = 1000
backlog = 2048

# Timeouts
timeout_keep_alive = 30
timeout_notify = 30

# Headers
header_limit = 8190
max_header_size = 8192
