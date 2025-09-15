# 🚀 MeterSync - Offline-First Meter Reading System

<div align="center">

![MeterSync Logo](https://img.shields.io/badge/MeterSync-v1.0.0-00AA44?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmZmZmYiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIj48cGF0aCBkPSJNMTIgMnYyMG0wLTEwbDguNS04LjVNMTIgMTJMMyAzIi8+PC9zdmc+)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109+-009688?style=flat-square&logo=fastapi)](https://fastapi.tiangolo.com)
[![Next.js](https://img.shields.io/badge/Next.js-14+-000000?style=flat-square&logo=next.js)](https://nextjs.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

**A professional, production-ready meter reading system with offline-first synchronization**

[Features](#-features) • [Architecture](#-architecture) • [Getting Started](#-getting-started) • [Documentation](#-documentation) • [Contributing](#-contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Architecture](#-architecture)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
- [Project Structure](#-project-structure)
- [Development](#-development)
  - [Mobile App](#mobile-app-flutter)
  - [Backend API](#backend-api-fastapi)
  - [Back-office](#back-office-nextjs)
- [API Documentation](#-api-documentation)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contributing](#-contributing)
- [Troubleshooting](#-troubleshooting)
- [Performance](#-performance)
- [Security](#-security)
- [License](#-license)

## 🌟 Overview

MeterSync is a comprehensive meter reading management system designed for field workers and administrators. It provides a robust offline-first mobile application for collecting meter readings in areas with poor connectivity, a powerful API backend for data synchronization, and a modern web-based back-office for administration.

### 🎯 Key Problems Solved

- ✅ **Offline Operation**: Full functionality without internet connection
- ✅ **Data Integrity**: Conflict resolution with client-side IDs
- ✅ **Photo Management**: Direct S3 upload with presigned URLs
- ✅ **GPS Tracking**: Automatic location capture with EXIF fallback
- ✅ **Batch Synchronization**: Efficient bulk data transfer
- ✅ **Real-time Status**: Visual sync indicators

## ✨ Features

### 📱 Mobile App (Flutter)
- **Offline-First Architecture**
  - Local SQLite database with migrations
  - Outbox pattern for reliable sync
  - Background synchronization every 15 minutes
  - Manual sync option with visual feedback

- **Meter Reading**
  - Quick meter selection with search
  - Numeric keypad with unit display
  - Date/time picker for reading timestamp
  - Optional notes field

- **Photo Capture**
  - Multiple photos per reading
  - EXIF data extraction (GPS, timestamp)
  - Automatic compression (80% quality)
  - Local storage with queue for upload

- **Location Services**
  - Automatic GPS capture
  - Accuracy indicator
  - Fallback to photo EXIF data
  - Manual retry option

### 🔌 Backend API (FastAPI)
- **Authentication & Authorization**
  - JWT with refresh tokens
  - Role-based access (Admin/Controller)
  - Secure password hashing (Bcrypt)

- **Data Management**
  - RESTful API with versioning
  - Batch sync endpoint
  - Conflict resolution (Last-Write-Wins)
  - CSV/XLSX import/export

- **File Storage**
  - S3-compatible object storage
  - Presigned URLs for direct upload
  - Photo metadata storage

### 💼 Back-office (Next.js)
- **Dashboard**
  - Real-time statistics
  - Sync status monitoring
  - Recent activity feed

- **Meter Management**
  - CRUD operations
  - Bulk import from CSV/XLSX
  - Advanced filtering and search

- **Export & Reports**
  - Excel export with embedded photos
  - Custom date ranges
  - Multiple format support

## 🏗 Architecture

```mermaid
graph TB
    subgraph "Mobile App"
        A[Flutter UI] --> B[Riverpod State]
        B --> C[Repository Layer]
        C --> D[SQLite DB]
        C --> E[Outbox Queue]
        E --> F[Sync Worker]
    end
    
    subgraph "Backend"
        G[FastAPI] --> H[PostgreSQL]
        G --> I[Redis Cache]
        G --> J[S3 Storage]
    end
    
    subgraph "Back-office"
        K[Next.js] --> L[React Query]
        L --> G
    end
    
    F -.->|Sync| G
    A -.->|Direct Upload| J
```

### 🔄 Sync Flow

```mermaid
sequenceDiagram
    participant M as Mobile App
    participant O as Outbox
    participant W as Worker
    participant A as API
    participant S as S3
    
    M->>O: Save Reading
    M->>M: Update UI
    W->>O: Check Pending
    W->>A: Sync Batch
    A->>A: Validate & Save
    W->>A: Request Presigned URL
    A->>W: Return URL
    W->>S: Upload Photo
    W->>A: Confirm Upload
    W->>O: Mark Complete
```

## 🛠 Tech Stack

### Frontend
- **Mobile**: Flutter 3.0+ with Riverpod
- **Web**: Next.js 14 with TypeScript
- **UI**: Material Design 3, Tailwind CSS

### Backend
- **API**: FastAPI with async/await
- **Database**: PostgreSQL 15 with SQLModel
- **Cache**: Redis 7
- **Storage**: S3-compatible (MinIO/Yandex)

### DevOps
- **Containers**: Docker & Docker Compose
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana
- **Logging**: Structured JSON logs

## 🚀 Getting Started

### Prerequisites

- **Docker & Docker Compose** (v20.10+)
- **Flutter SDK** (3.0+)
- **Node.js** (18+)
- **Python** (3.11+)
- **PostgreSQL** (15+) - via Docker
- **Redis** (7+) - via Docker

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/metersync.git
cd metersync
```

2. **Copy environment files**
```bash
cp .env.example .env
cp mobile/.env.example mobile/.env
cp backoffice/.env.example backoffice/.env
```

3. **Start infrastructure**
```bash
docker-compose up -d postgres redis minio
```

4. **Initialize database**
```bash
docker exec -i metersync_postgres psql -U postgres meter_reading < api/postgres_schema.sql
```

5. **Install dependencies**

**API:**
```bash
cd api
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
```

**Mobile:**
```bash
cd mobile
flutter pub get
```

**Back-office:**
```bash
cd backoffice
npm install
```

### Configuration

#### Environment Variables

**.env (root)**
```env
# Database
DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/meter_reading

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-secret-key-change-in-production
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# S3 Storage
S3_ENDPOINT_URL=http://localhost:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin123
S3_BUCKET_NAME=meter-photos
```

**mobile/.env**
```env
API_BASE_URL=http://10.0.2.2:8000  # Android emulator
# API_BASE_URL=http://localhost:8000  # iOS simulator
# API_BASE_URL=http://192.168.1.100:8000  # Physical device

SYNC_INTERVAL_MINUTES=15
MAX_RETRY_ATTEMPTS=5
```

## 📁 Project Structure

```
metersync/
├── 📱 mobile/                 # Flutter mobile app
│   ├── lib/
│   │   ├── core/             # Core utilities
│   │   │   ├── database/     # SQLite helpers
│   │   │   ├── network/      # API client
│   │   │   ├── sync/         # Sync logic
│   │   │   └── utils/        # Helpers
│   │   ├── data/             # Data layer
│   │   │   ├── models/       # Data models
│   │   │   └── repositories/ # Data repositories
│   │   ├── presentation/     # UI layer
│   │   │   ├── providers/    # Riverpod providers
│   │   │   ├── screens/      # App screens
│   │   │   └── widgets/      # Reusable widgets
│   │   └── config/           # App configuration
│   └── test/                 # Unit & widget tests
│
├── 🔌 api/                   # FastAPI backend
│   ├── app/
│   │   ├── api/             # API routes
│   │   ├── auth/            # Authentication
│   │   ├── models/          # Database models
│   │   ├── schemas/         # Pydantic schemas
│   │   ├── services/        # Business logic
│   │   └── utils/           # Utilities
│   ├── tests/               # API tests
│   └── migrations/          # Alembic migrations
│
├── 💼 backoffice/            # Next.js admin panel
│   ├── app/                 # App router pages
│   ├── components/          # React components
│   ├── lib/                 # Utilities
│   └── hooks/               # Custom hooks
│
├── 📦 samples/               # Sample data
├── 📚 docs/                  # Documentation
├── 🐳 docker-compose.yml     # Container orchestration
└── 📝 README.md             # This file
```

## 💻 Development

### Mobile App (Flutter)

#### Running locally
```bash
cd mobile
flutter run
```

#### Building for release
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

#### Key Commands
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format .

# Clean build
flutter clean
```

### Backend API (FastAPI)

#### Running locally
```bash
cd api
uvicorn app.main:app --reload --port 8000
```

#### Running tests
```bash
pytest tests/ -v
pytest --cov=app tests/  # With coverage
```

#### Database migrations
```bash
# Create migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

### Back-office (Next.js)

#### Running locally
```bash
cd backoffice
npm run dev
```

#### Building for production
```bash
npm run build
npm start
```

## 📖 API Documentation

### Interactive Documentation
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Main Endpoints

#### Authentication
```http
POST /api/v1/auth/login
POST /api/v1/auth/register
POST /api/v1/auth/refresh
GET  /api/v1/auth/me
```

#### Meters
```http
GET    /api/v1/meters
POST   /api/v1/meters
GET    /api/v1/meters/{id}
PATCH  /api/v1/meters/{id}
DELETE /api/v1/meters/{id}
POST   /api/v1/meters/import
```

#### Readings
```http
GET  /api/v1/readings
POST /api/v1/readings
POST /api/v1/readings/sync
GET  /api/v1/readings/{id}
```

#### Photos
```http
POST /api/v1/photos/presigned-url
POST /api/v1/photos/complete
GET  /api/v1/photos/{id}
```

### Example Requests

#### Login
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "admin123"}'
```

#### Create Reading
```bash
curl -X POST http://localhost:8000/api/v1/readings \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "meter_id": "uuid",
    "reading_value": 12345.678,
    "reading_date": "2024-01-15T10:30:00Z",
    "latitude": 48.8566,
    "longitude": 2.3522
  }'
```

## 🧪 Testing

### Running All Tests
```bash
# From root directory
./scripts/test-all.sh
```

### Mobile Tests
```bash
cd mobile
flutter test
flutter test --coverage
```

### API Tests
```bash
cd api
pytest
pytest tests/test_auth.py -v  # Specific file
pytest -k "test_login"  # Specific test
```

### E2E Tests
```bash
cd e2e
npm test
```

## 🚢 Deployment

### Docker Deployment

1. **Build images**
```bash
docker-compose build
```

2. **Start services**
```bash
docker-compose up -d
```

3. **Check status**
```bash
docker-compose ps
docker-compose logs -f
```

### Production Deployment

#### Prerequisites
- Kubernetes cluster or VPS
- Domain with SSL certificate
- PostgreSQL managed instance
- S3-compatible storage
- Redis instance

#### Environment Setup
```bash
# Create secrets
kubectl create secret generic metersync-secrets \
  --from-literal=jwt-secret=$JWT_SECRET \
  --from-literal=db-password=$DB_PASSWORD

# Apply manifests
kubectl apply -f k8s/
```

#### CI/CD Pipeline
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy to production
        run: |
          # Your deployment script
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### How to Contribute

1. **Fork the repository**
```bash
git clone https://github.com/yourusername/metersync.git
```

2. **Create a feature branch**
```bash
git checkout -b feature/amazing-feature
```

3. **Make your changes**
- Follow the code style guide
- Add tests for new features
- Update documentation

4. **Commit your changes**
```bash
git commit -m 'feat: add amazing feature'
```

We use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code restructuring
- `test:` Tests
- `chore:` Maintenance

5. **Push to your fork**
```bash
git push origin feature/amazing-feature
```

6. **Open a Pull Request**

### Development Setup for Contributors

1. **Install pre-commit hooks**
```bash
pip install pre-commit
pre-commit install
```

2. **Run linters**
```bash
# Python
black api/
flake8 api/
mypy api/

# Flutter
flutter analyze
flutter format .

# JavaScript
npm run lint
npm run format
```

## 🐛 Troubleshooting

### Common Issues

#### Mobile App

**Issue**: Can't connect to API
```bash
# Solution: Check API URL configuration
# For emulator: http://10.0.2.2:8000
# For device: Use your machine's IP
```

**Issue**: Location not working
```bash
# Solution: Check permissions
flutter doctor
# Ensure location permissions in AndroidManifest.xml / Info.plist
```

#### API

**Issue**: Database connection failed
```bash
# Solution: Check PostgreSQL is running
docker-compose ps
docker-compose logs postgres
```

**Issue**: Import fails
```bash
# Solution: Check file format and required columns
# Required: meter_number, type
```

#### Back-office

**Issue**: API calls failing
```bash
# Solution: Check CORS settings
# Ensure your domain is in CORS_ORIGINS
```

### Debug Mode

#### Enable debug logging
```python
# api/app/config.py
DEBUG = True
DB_ECHO = True
```

```dart
// mobile/lib/main.dart
const bool kDebugMode = true;
```

## ⚡ Performance

### Optimizations

#### Mobile
- **SQLite indexes** on frequently queried fields
- **Image compression** to 80% quality
- **Batch sync** to reduce API calls
- **Lazy loading** for lists

#### API
- **Connection pooling** for PostgreSQL
- **Redis caching** for frequently accessed data
- **Async/await** throughout
- **Pagination** on all list endpoints

#### Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| App startup | <2s | Cold start |
| Reading save | <100ms | Local only |
| Photo capture | <3s | With compression |
| Sync 100 readings | <5s | Good connection |
| API response | <200ms | P95 latency |

## 🔒 Security

### Security Features

- ✅ **JWT Authentication** with refresh tokens
- ✅ **Password hashing** with Bcrypt (12 rounds)
- ✅ **Role-based access control** (RBAC)
- ✅ **Input validation** with Pydantic
- ✅ **SQL injection protection** via ORM
- ✅ **CORS configuration** with whitelist
- ✅ **Rate limiting** on API endpoints
- ✅ **Secure storage** for mobile tokens

### Security Best Practices

1. **Never commit secrets**
```bash
# Use git-secrets
brew install git-secrets
git secrets --install
git secrets --register-aws
```

2. **Rotate keys regularly**
```bash
# Generate new JWT secret
openssl rand -hex 32
```

3. **Use HTTPS in production**
```nginx
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
}
```

### Reporting Security Issues

Please report security vulnerabilities to security@metersync.com

## 📊 Monitoring

### Metrics

We use Prometheus + Grafana for monitoring:

```yaml
# docker-compose.monitoring.yml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    
  grafana:
    image: grafana/grafana
    ports:
      - "3001:3000"
```

### Key Metrics
- API response time
- Sync success rate
- Active users
- Storage usage
- Error rate

## 📚 Additional Resources

- [API Documentation](docs/api.md)
- [Mobile Development Guide](docs/mobile.md)
- [Deployment Guide](docs/deployment.md)
- [Architecture Decision Records](docs/adr/)
- [Troubleshooting Guide](docs/troubleshooting.md)

## 🏆 Acknowledgments

- Flutter team for the amazing framework
- FastAPI community for the excellent documentation
- All contributors who have helped improve this project

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with ❤️ by the MeterSync Team**

[Report Bug](https://github.com/yourusername/metersync/issues) • [Request Feature](https://github.com/yourusername/metersync/issues) • [Documentation](https://docs.metersync.com)

</div>