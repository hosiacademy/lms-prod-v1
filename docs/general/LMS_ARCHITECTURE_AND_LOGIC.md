# Hosi Academy LMS — System Architecture & Business Logic

## 1. System Overview
Hosi Academy LMS is a comprehensive Learning Management System designed for the African market, supporting diverse training pathways including AI certifications (via AICERTS), learnerships, corporate training, and industry-specific programs.

### Tech Stack
- **Backend**: Django (Python 3.11) with Django REST Framework (DRF)
- **Frontend**: Flutter Web (Release build served via Nginx)
- **Database**: PostgreSQL (Primary storage)
- **Cache & Message Broker**: Redis
- **Task Queue**: Celery (for asynchronous jobs and scheduled tasks)
- **Real-time**: Socket.IO (for notifications and chat)
- **Deployment**: Docker Compose (Multi-container orchestration)
- **Reverse Proxy**: Nginx (Dual-layer: Host and Container levels)
- **Monitoring**: Sentry (Error tracking) and Flower (Celery monitor)

---

## 2. Business Logic & Core Modules

### A. Training Pathways & Course Management
The system categorizes learning into three primary tracks:
1. **AICERTS Courses**: Integration with external AI certification providers. Supports SSO (Single Sign-On) and enrollment synchronization.
2. **Learnerships**: Structured work-based learning programs prevalent in the South African context.
3. **Masterclasses**: High-impact, short-term expert-led training sessions.

### B. Payment Ecosystem
Designed for the African landscape, the payment module supports:
- **Aggregators**: Flutterwave, Paystack, MFS Africa.
- **Mobile Money**: M-Pesa, MTN MoMo, Airtel Money, EcoCash.
- **Local Gateways**: Bank-specific APIs and country-specific providers (e.g., GHIPSS in Ghana, Interswitch in Nigeria).
- **Multi-Country Support**: Automatic location detection (IP-based) to offer context-relevant payment methods (e.g., showing EcoCash to users in Zimbabwe).

### C. Enrollment Logic
- **Provisioning**: When a payment is successful, the system automatically provisions the enrollment.
- **Syncing**: For external courses (AICERTS), the backend synchronizes the enrollment status with the partner API.
- **Access Control**: Role-based access for Students, Instructors, and Administrators.

### D. Instructor Portal & Live Sessions
- **Instructor Dashboard**: Tools for managing learnerships and students.
- **BigBlueButton (BBB) Integration**: Support for scheduling and hosting live virtual classrooms directly within the platform.

---

## 3. Infrastructure & Deployment

### Directory Structure
- `/backend`: Django application source, migrations, and environment configuration.
- `/frontend`: Flutter source code and assets.
- `/nginx`: Nginx configuration files and SSL certificates.
- `/scripts`: Utility scripts for deployment and maintenance.

### Request Flow
1. **User Request**: Hits the Host Nginx (Port 443).
2. **SSL Termination**: Host Nginx handles SSL and proxies to the `lms_nginx` container (Port 7000).
3. **Routing**: `lms_nginx` routes requests based on path:
   - `/api/*` → Django Backend (Gunicorn)
   - `/socket.io/*` → Socket.IO Server
   - `/*` (Catch-all) → Flutter Web Frontend

### Environment Management
- Configuration is driven by `.env` files in the `backend/` directory.
- Critical keys include Database credentials, AICERTS API tokens, and Payment Gateway secrets.

---

## 4. Key Integration: AICERTS
- **API Surface**: Uses HMAC-SHA256 signatures for secure communication.
- **Data Flow**: Syncs course metadata and assets (images, badges) from AICERTS to the local database.
- **Image Proxy**: A custom Django view proxies external course images to bypass CORS restrictions for the Flutter web client.

---

## 5. Maintenance & Debugging
- **Logs**: Access via `docker logs <container_name>`.
- **Shell**: Access Django shell inside the container for data manipulation.
- **Status**: Monitor background tasks via Flower at port 7003.
