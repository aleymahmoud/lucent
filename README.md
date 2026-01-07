# LUCENT - Time Series Forecasting Platform

**Multi-Tenant SaaS Platform for Time Series Forecasting**

Transform your data into actionable forecasts with LUCENT - a modern, scalable forecasting platform built with Next.js 14 and FastAPI.

---

## 🚀 Project Status

### Phase 1: Foundation - 🚧 IN PROGRESS (40% Complete)

**Frontend:** ✅ **COMPLETED**
- ✅ Next.js 14 with TypeScript
- ✅ shadcn/ui component library (10 components)
- ✅ Tailwind CSS styling
- ✅ Zustand state management
- ✅ TanStack Query + Axios API client
- ✅ Plotly.js for charts
- ✅ Dashboard layout (Sidebar + Header)
- ✅ Main dashboard page with stats
- ✅ Base path configuration (/lucent)
- ✅ Type-safe API client (68 endpoints defined)
- ✅ Complete TypeScript type definitions
- ✅ **Development server running:** http://localhost:3001/lucent/dashboard

**Backend:** 🚧 **IN SETUP**
- ✅ Environment variables configured (.env)
- ✅ Neon PostgreSQL credentials ready
- ✅ Upstash Redis credentials ready
- ✅ Stack Auth credentials configured
- ⏳ FastAPI project structure (Next)
- ⏳ Database connection testing (Next)
- ⏳ Multi-tenant architecture (Next)
- ⏳ Authentication system (Next)

**Infrastructure:**
- ⏸️ Docker Compose (Deferred - Windows incompatible)
- ✅ Local development setup
- ✅ Cloud databases (Neon + Upstash)

---

## 📦 Tech Stack

### Frontend
- **Framework:** Next.js 14 (App Router)
- **Language:** TypeScript
- **UI Library:** shadcn/ui + Radix UI
- **Styling:** Tailwind CSS
- **State Management:** Zustand
- **Data Fetching:** TanStack Query (React Query)
- **Charts:** Plotly.js + react-plotly.js
- **Forms:** React Hook Form + Zod
- **Authentication:** NextAuth.js

### Backend
- **Framework:** FastAPI (Python 3.11+)
- **ORM:** SQLAlchemy 2.0
- **Validation:** Pydantic v2
- **Task Queue:** Celery + Redis
- **Database:** PostgreSQL (Neon Cloud)
- **Cache:** Redis (Upstash Cloud)

### Forecasting
- **Methods:** ARIMA, ETS, Prophet
- **Libraries:** statsmodels, prophet, scipy, numpy, pandas

---

## 🏗️ Project Structure

```
lucent/
├── frontend/                      # Next.js application
│   ├── src/
│   │   ├── app/                   # Next.js 14 App Router
│   │   │   ├── (dashboard)/       # Dashboard pages
│   │   │   │   ├── layout.tsx     # Dashboard layout
│   │   │   │   └── dashboard/     # Main dashboard
│   │   │   └── (auth)/            # Auth pages (TODO)
│   │   ├── components/
│   │   │   ├── ui/                # shadcn/ui components
│   │   │   ├── layout/            # Layout components
│   │   │   │   ├── Sidebar.tsx    ✅
│   │   │   │   └── Header.tsx     ✅
│   │   │   ├── data/              # Data module (TODO)
│   │   │   ├── preprocessing/     # Preprocessing (TODO)
│   │   │   ├── forecast/          # Forecast (TODO)
│   │   │   ├── results/           # Results (TODO)
│   │   │   └── diagnostics/       # Diagnostics (TODO)
│   │   ├── lib/
│   │   │   ├── api/
│   │   │   │   ├── client.ts      ✅ Axios config
│   │   │   │   └── endpoints.ts   ✅ API endpoints
│   │   │   └── utils.ts           ✅ Utilities
│   │   ├── stores/
│   │   │   └── forecastStore.ts   ✅ Zustand store
│   │   └── types/
│   │       └── index.ts           ✅ TypeScript types
│   ├── .env.local                 ✅ Environment variables
│   └── package.json
│
├── backend/                       # FastAPI application (TODO)
│   └── (To be created in Phase 1 - Part 2)
│
├── docs/
│   ├── LUCENT_Transformation_Plan.md    ✅
│   └── LUCENT App Documentation.md      ✅
│
└── README.md                      ✅ This file
```

---

## 🎯 Current Features

### ✅ Completed (Phase 1 - Frontend Foundation)

1. **Dashboard Layout**
   - Modern sidebar navigation
   - Header with search and notifications
   - Responsive design
   - Clean, professional UI

2. **Navigation**
   - Dashboard overview
   - Data management (placeholder)
   - Preprocessing tools (placeholder)
   - Forecasting (placeholder)
   - Results viewer (placeholder)
   - Diagnostics (placeholder)
   - Settings (placeholder)

3. **Dashboard Overview**
   - Statistics cards (Datasets, Forecasts, Team)
   - Recent activity feed
   - Quick action buttons
   - Visual metrics display

4. **Infrastructure**
   - Type-safe API client with Axios
   - Global state management with Zustand
   - Comprehensive TypeScript types
   - Environment configuration
   - Development server running

### ⏳ Next Steps (Phase 1 - Backend)

1. Set up FastAPI backend project
2. Configure Neon PostgreSQL connection
3. Configure Upstash Redis connection
4. Create database schema & migrations
5. Implement multi-tenant middleware
6. Build authentication system (JWT)
7. Create API endpoints for data upload

---

## 🚀 Getting Started

### Prerequisites

- ✅ Node.js 20.x or higher
- ✅ Python 3.11 or higher
- ✅ Git
- ⏳ Docker Desktop (optional, for later phases)

### Installation

1. **Clone the repository:**
   ```bash
   cd C:\Lucent
   ```

2. **Frontend Setup:**
   ```bash
   cd frontend
   npm install
   ```

3. **Configure environment:**
   - Copy `.env.local` and update values
   - Cloud database credentials are pre-configured

4. **Start development server:**
   ```bash
   npm run dev
   ```

   Frontend will be available at: http://localhost:3000

---

## 🌐 Environment Variables

### Frontend (.env.local)

```bash
# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1

# NextAuth
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key

# Stack Auth (Pre-configured)
NEXT_PUBLIC_STACK_PROJECT_ID=5120c6db-55e9-4c6c-865f-5681b07326e6
NEXT_PUBLIC_STACK_PUBLISHABLE_CLIENT_KEY=pck_7gm6ah76n80k6rqr78v9p0yh9yye3hmg8m4jqefk4gpn8
STACK_SECRET_SERVER_KEY=ssk_1ebqr9vgf89n1n3fpk7krhnjr1thyaha1amct39tdk4jr
```

### Backend (TODO - To be created)

```bash
# Database (Neon PostgreSQL)
DATABASE_URL=postgresql://neondb_owner:npg_M5G0ixkwjonq@ep-red-field-ahjnxa6j-pooler.c-3.us-east-1.aws.neon.tech/neondb?sslmode=require

# Redis (Upstash)
REDIS_URL=rediss://default:AXeTAAIncDJlNDc4MGU2MmVhNjU0MjBiOGJlMGRlZWYyNWI5N2U4YXAyMzA2MTE@secure-seal-30611.upstash.io:6379
```

---

## 📚 Available Scripts

### Frontend

```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
```

### Backend (TODO)

```bash
python -m uvicorn app.main:app --reload    # Start development server
alembic upgrade head                        # Run database migrations
pytest                                      # Run tests
```

---

## 🎨 UI Components

We use **shadcn/ui** - a collection of re-usable components built with Radix UI and Tailwind CSS.

### Installed Components:
- ✅ Button
- ✅ Card
- ✅ Input
- ✅ Label
- ✅ Select
- ✅ Table
- ✅ Tabs
- ✅ Dialog
- ✅ Dropdown Menu
- ✅ Sonner (Toast notifications)

### Adding More Components:

```bash
npx shadcn@latest add [component-name]
```

---

## 📊 Implementation Roadmap

### ✅ Phase 1: Foundation (Week 1-2) - IN PROGRESS
- [x] Project setup (Next.js + FastAPI)
- [x] Frontend foundation
- [x] UI component library
- [x] Basic layout & navigation
- [ ] Backend setup
- [ ] Database configuration
- [ ] Authentication system

### 📅 Phase 2: Data Module (Week 3-4)
- [ ] File upload functionality
- [ ] Data validation
- [ ] Data preview tables
- [ ] Summary statistics
- [ ] Sample data loader

### 📅 Phase 3: Preprocessing Module (Week 5-6)
- [ ] Missing values handler
- [ ] Outlier detection
- [ ] Time aggregation
- [ ] Data transformations

### 📅 Phase 4: Forecasting Module (Week 7-9)
- [ ] ARIMA implementation
- [ ] ETS implementation
- [ ] Prophet implementation
- [ ] Batch forecasting
- [ ] Background job processing

### 📅 Phase 5-9: Results, Diagnostics, Connectors, Admin (Week 10-18)
- [ ] Results visualization
- [ ] Diagnostic tools
- [ ] Data connectors
- [ ] Admin panel
- [ ] Performance optimization

---

## 🤝 Development Workflow

1. **Frontend development:** `cd frontend && npm run dev`
2. **Backend development:** (To be set up)
3. **Access the app:** http://localhost:3000
4. **API docs:** http://localhost:8000/docs (when backend is ready)

---

## 📖 Documentation

- [Transformation Plan](docs/LUCENT_Transformation_Plan.md) - Complete technical specification
- [App Documentation](docs/LUCENT%20App%20Documentation.md) - Original R Shiny app reference

---

## 🎯 Key Features (Planned)

- 📊 **Multi-Tenant SaaS:** Isolated data for multiple organizations
- 📈 **Time Series Forecasting:** ARIMA, ETS, and Prophet methods
- 🔄 **Data Preprocessing:** Handle missing values, outliers, aggregation
- 📉 **Interactive Charts:** Plotly.js visualizations
- 🔌 **Data Connectors:** PostgreSQL, MySQL, S3, BigQuery, Snowflake
- 👥 **Team Collaboration:** Role-based access control
- 📱 **Responsive Design:** Works on desktop, tablet, and mobile
- ⚡ **Real-time Updates:** WebSocket progress tracking
- 📁 **Export Options:** CSV, Excel, PDF reports

---

## 🛠️ Technology Decisions

### Why Next.js 14?
- Server-side rendering for better SEO
- App Router for modern React patterns
- Built-in API routes
- Excellent TypeScript support
- Great developer experience

### Why FastAPI?
- Fast performance (async/await)
- Automatic API documentation
- Type hints with Pydantic
- Python ecosystem for data science
- Easy integration with ML libraries

### Why Cloud Databases?
- No local database setup required
- Automatic backups
- Scalability
- Managed infrastructure
- Free tier available

---

## 📝 Notes

- Frontend is currently running in development mode
- Backend setup will begin next
- Cloud database credentials are pre-configured
- All sensitive data should be in environment variables

---

## 🐛 Known Issues

None at this time. The frontend is running successfully!

---

## 📧 Support

For questions or issues, refer to:
- [Transformation Plan](docs/LUCENT_Transformation_Plan.md)
- [Original Documentation](docs/LUCENT%20App%20Documentation.md)

---

**Last Updated:** 2026-01-07
**Phase:** 1 - Foundation (Frontend Complete ✅)
**Status:** ✅ Frontend Development Server Running
**Next:** Backend Setup with FastAPI
