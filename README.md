# LMS Production Platform

## Overview
Full-stack Learning Management System with Django backend and Flutter frontend.

## Quick Start
\\\ash
# Backend
cd backend
python -m venv venv_windows
source venv_windows/Scripts/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:7001

# Frontend
cd frontend
flutter pub get
flutter run -d chrome --web-port 7005
\\\

## Docker Deployment
\\\ash
docker-compose up -d
\\\

## Access
- Frontend: http://localhost:7005
- Backend API: http://localhost:7001
- Admin: http://localhost:7001/admin
- Socket.IO: http://localhost:7002
\\\

## Database
PostgreSQL running in Docker on port 5432

## Features
- 174 database tables
- 71 AICERTS courses
- Payment integration (M-Pesa, Paystack, Stripe, etc.)
- Real-time chat with Socket.IO
- Instructor/Student portals
