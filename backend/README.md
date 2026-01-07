# LUCENT Backend - FastAPI Application

**Multi-Tenant SaaS Platform for Time Series Forecasting - Backend API**

---

## 🚀 Setup Status

### ✅ Completed
- Backend folder structure created
- requirements.txt with all dependencies
- FastAPI main application (app/main.py)
- Configuration module (app/config.py)
- Database connection (app/db/database.py)
- Redis connection (app/db/redis.py)
- Environment variables (.env)

### ⏳ Next Steps
1. Install Python (if not already installed)
2. Install dependencies: `pip install -r requirements.txt`
3. Test database connections
4. Create database models
5. Set up Alembic migrations
6. Start development server

---

## 📁 Project Structure

```
backend/
├── app/
│   ├── __init__.py              ✅ Created
│   ├── main.py                  ✅ FastAPI application
│   ├── config.py                ✅ Settings & configuration
│   │
│   ├── api/
│   │   └── v1/                  📁 API endpoints (to be created)
│   │
│   ├── core/                    📁 Core utilities (to be created)
│   ├── db/
│   │   ├── __init__.py          ✅ Created
│   │   ├── database.py          ✅ PostgreSQL connection
│   │   └── redis.py             ✅ Redis connection
│   │
│   ├── models/                  📁 SQLAlchemy models (to be created)
│   ├── schemas/                 📁 Pydantic schemas (to be created)
│   ├── services/                📁 Business logic (to be created)
│   ├── forecasting/             📁 Forecasting engines (to be created)
│   ├── connectors/              📁 Data connectors (to be created)
│   ├── middleware/              📁 Middleware (to be created)
│   └── workers/                 📁 Celery tasks (to be created)
│
├── alembic/                     📁 Database migrations
├── tests/                       📁 Unit tests
├── logs/                        📁 Log files
├── uploads/                     📁 Uploaded files
│
├── .env                         ✅ Environment variables
├── .env.example                 ✅ Environment template
├── requirements.txt             ✅ Python dependencies
└── README.md                    ✅ This file
```

---

## 🔧 Installation

### Prerequisites
- Python 3.11 or higher
- pip (Python package manager)

### Step 1: Install Python

**If Python is not installed**, run one of the installation scripts in the parent directory:
```bash
# PowerShell (recommended)
cd C:\Lucent
.\install-python.ps1

# Or Batch file
.\install-python-simple.bat
```

### Step 2: Verify Python Installation

```bash
python --version
# Should output: Python 3.11.x or higher
```

### Step 3: Create Virtual Environment (Recommended)

```bash
cd C:\Lucent\backend
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate

# You should see (venv) in your terminal
```

### Step 4: Install Dependencies

```bash
pip install -r requirements.txt
```

This will install:
- FastAPI & Uvicorn (web framework)
- SQLAlchemy & Alembic (database)
- asyncpg (PostgreSQL driver)
- redis (cache)
- Celery (task queue)
- pandas, numpy, statsmodels, prophet (forecasting)
- And many more...

---

## 🗄️ Database Configuration

All database credentials are pre-configured in `.env`:

### Neon PostgreSQL
```bash
DATABASE_URL=postgresql://neondb_owner:npg_M5G0ixkwjonq@ep-red-field-ahjnxa6j-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require
```

### Upstash Redis
```bash
REDIS_URL=rediss://default:AXeTAAIncDJlNDc4MGU2MmVhNjU0MjBiOGJlMGRlZWYyNWI5N2U4YXAyMzA2MTE@secure-seal-30611.upstash.io:6379
```

**Test connections before proceeding!**

---

## 🧪 Testing Database Connections

### Test PostgreSQL Connection

Create a test file `test_db.py`:

```python
import asyncio
from app.db.database import init_db

async def test_postgres():
    try:
        await init_db()
        print("✅ PostgreSQL connection successful!")
    except Exception as e:
        print(f"❌ PostgreSQL connection failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_postgres())
```

Run:
```bash
python test_db.py
```

### Test Redis Connection

Create a test file `test_redis.py`:

```python
import asyncio
from app.db.redis import init_redis

async def test_redis():
    try:
        redis = await init_redis()
        await redis.set("test_key", "Hello LUCENT!")
        value = await redis.get("test_key")
        print(f"✅ Redis connection successful! Value: {value}")
        await redis.delete("test_key")
    except Exception as e:
        print(f"❌ Redis connection failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_redis())
```

Run:
```bash
python test_redis.py
```

---

## 🚀 Running the Development Server

### Start FastAPI Server

```bash
# Method 1: Using uvicorn directly
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Method 2: Using Python
python -m app.main
```

### Access the API

- **Root:** http://localhost:8000/
- **API Docs (Swagger):** http://localhost:8000/api/v1/docs
- **API Docs (ReDoc):** http://localhost:8000/api/v1/redoc
- **Health Check:** http://localhost:8000/api/v1/health

---

## 📊 Next Development Steps

### 1. Create Database Models (SQLAlchemy)

Create models in `app/models/`:
- `user.py` - User model
- `tenant.py` - Tenant model
- `connector.py` - Data connector model
- etc.

### 2. Set up Alembic Migrations

```bash
# Initialize Alembic (if not done)
alembic init alembic

# Create first migration
alembic revision --autogenerate -m "Initial schema"

# Apply migration
alembic upgrade head
```

### 3. Create API Endpoints

Create endpoints in `app/api/v1/`:
- `auth.py` - Authentication
- `users.py` - User management
- `datasets.py` - Dataset operations
- etc.

### 4. Implement Authentication

Create JWT token handling in `app/core/security.py`

### 5. Add Middleware

Create middleware in `app/middleware/`:
- Tenant context
- Request logging
- Error handling

---

## 🔐 Security Notes

**IMPORTANT:** Before deploying to production:

1. Change `SECRET_KEY` and `JWT_SECRET_KEY` in `.env`
2. Use strong, unique passwords
3. Never commit `.env` to version control
4. Add `.env` to `.gitignore`
5. Rotate credentials regularly

---

## 📝 Environment Variables

All configuration is loaded from `.env` file:

```bash
# Application
APP_NAME=LUCENT
APP_ENV=development
DEBUG=True

# Database
DATABASE_URL=postgresql://...

# Redis
REDIS_URL=rediss://...

# Security
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-key

# ... and more
```

See `.env.example` for full list.

---

## 🐛 Troubleshooting

### Python not found
- Run installation scripts: `install-python.ps1` or `install-python-simple.bat`
- Restart terminal/VS Code after installation

### Database connection failed
- Check `.env` file has correct credentials
- Verify network access to Neon (cloud service)
- Check firewall settings

### Redis connection failed
- Check `.env` file has correct Redis URL
- Verify network access to Upstash (cloud service)

### Dependencies installation failed
- Ensure pip is up to date: `python -m pip install --upgrade pip`
- Try installing dependencies one by one
- Check Python version: `python --version` (should be 3.11+)

---

## 📚 Documentation

- FastAPI: https://fastapi.tiangolo.com/
- SQLAlchemy: https://docs.sqlalchemy.org/
- Alembic: https://alembic.sqlalchemy.org/
- Neon PostgreSQL: https://neon.tech/docs
- Upstash Redis: https://upstash.com/docs/redis

---

**Status:** Backend structure complete. Ready for dependency installation and testing!

**Last Updated:** 2026-01-07
