# Prova

AI-powered fashion e-commerce platform combining virtual try-on, RAG-based chat, and a modern shopping experience.

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Available Commands](#available-commands)
- [Environment Variables](#environment-variables)
- [Services](#services)
- [License](#license)

## Overview

Prova is a full-stack fashion technology platform that brings together:

- **Virtual Try-On** — 2D and 360° virtual try-on experiences powered by AI (OOTDiffusion, TrueFit, VTON360, Runway)
- **AI Fashion Assistant** — Arabic-first RAG chatbot using Egyptian Arabic (Nile-Chat-12B.PROVA) with product retrieval and outfit assembly
- **Modern E-Commerce Frontend** — Next.js app with multilingual support, responsive UI, and dynamic product catalog
- **Production Backend** — Express API with MongoDB, JWT auth, real-time sockets, image processing, and email

## Tech Stack

| Layer | Technologies |
|---|---|
| Frontend | Next.js 15, React 19, TypeScript, Tailwind CSS, ShadCN UI, Radix, Framer Motion, next-intl |
| Backend | Express.js, TypeScript, MongoDB (Mongoose), Socket.IO, JWT, Cloudinary, Sharp |
| AI / Chat | FastAPI, Pydantic, sentence-transformers, ChromaDB, OpenRouter (Gemma 4) |
| Try-On Service | FastAPI, OOTDiffusion, TrueFit, Runway ML, VTON360, Taichi Three, Body Measurements |
| Data / ML | Python, pandas, numpy, scikit-learn, LoRA fine-tuning |

## Project Structure

```
Prova/
├── frontend/            # Next.js web application
├── backend/             # Express API server
├── chat/                # AI assistant, RAG pipeline, and data ingestion
│   ├── rag/            # FastAPI RAG router (intent, retrieval, outfit assembly)
│   ├── src/            # Agents, API, data, and fine-tuning modules
│   └── requirements.txt
├── tryon/              # Virtual try-on microservice (FastAPI)
│   ├── app/            # Routers, services, validators, schemas
│   └── vton_modeling/  # Rendering and human parsing models
└── Makefile            # Cross-platform dev/build shortcuts
```

### Frontend (`frontend/`)

Next.js app with:

- ShadCN UI components (accordion, dialog, tabs, toast, carousel, etc.)
- Internationalization via `next-intl`
- Real-time chat via `socket.io-client`
- Image optimization with Cloudinary and Sharp
- Animations powered by Framer Motion and tsparticles

### Backend (`backend/`)

Express service with:

- REST API + Socket.IO real-time layer
- MongoDB models and migrations
- JWT authentication (access + refresh tokens)
- Image upload and compression with Sharp
- Email delivery via Nodemailer
- Rate limiting and security via Helmet
- Chat proxy forwarding requests to the Python RAG service

### AI Chat (`chat/`)

Fashion assistant built on RAG:

- **RAG Pipeline** (`chat/rag/`) — message classification, intent extraction, hybrid retrieval, outfit assembly, and response composition via Gemma 4
- **Data & Ingestion** — product collection, preprocessing, ChromaDB embeddings
- **Fine-Tuning** — LoRA training for Nile-Chat-12B.PROVA on Egyptian Arabic fashion conversations
- **Agents** — orchestrator, planner, and tool integration for conversational flows

### Try-On (`tryon/`)

FastAPI microservice exposing:

- 2D try-on (OOTDiffusion & TrueFit)
- 360° video preview (Runway image-to-video)
- VTON360 preprocessing + orchestration
- Body measurements and size recommendation (Shapy)
- Analytics middleware

## Getting Started

### Prerequisites

- [Node.js](https://nodejs.org/) >= 18
- [pnpm](https://pnpm.io/) or npm
- [Python](https://www.python.org/) >= 3.10
- [MongoDB](https://www.mongodb.com/) (local or Atlas)
- LM Studio (optional, for local model debugging)

### 1. Clone the repository

```bash
git clone https://github.com/<org>/prova.git
cd prova
```

### 2. Install dependencies

```bash
make install
# or
cd frontend && pnpm install && cd ../backend && pnpm install
cd chat && pip install -r requirements.txt
```

### 3. Configure environment

Copy example env files and fill in your values:

```bash
cp backend/.env.example backend/.env
cp frontend/.env.local.example frontend/.env.local
cp chat/.env.example chat/.env
cp chat/rag/.env.example chat/rag/.env
cp tryon/.env.example tryon/.env
```

### 4. Start development

```bash
make dev
```

This starts the backend and frontend dev servers in parallel.

## Available Commands

All commands are cross-platform (Windows, macOS, Linux) via the included `Makefile`.

```bash
make help              # Show all available commands
make install           # Install frontend + backend dependencies
make dev               # Start all development servers
make backend-dev       # Start only the backend
make frontend-dev      # Start only the frontend
make backend-install   # Install backend dependencies
make frontend-install  # Install frontend dependencies
make backend-test      # Run backend tests
make clean             # Remove node_modules and lock files
make status            # Show project and dependency status
make setup             # Print setup instructions
```

Direct npm/pnpm scripts are also available:

```bash
# Frontend
cd frontend
pnpm dev              # Next.js dev server with Turbopack
pnpm build            # Production build
pnpm lint             # ESLint

# Backend
cd backend
pnpm dev              # TSX watch mode
pnpm build            # TypeScript compile
pnpm test             # Vitest
pnpm lint             # ESLint
pnpm format           # Prettier
```

## Services

### Frontend

| URL | Description |
|---|---|
| `http://localhost:3000` | Main web app |

### Backend

| URL | Description |
|---|---|
| `http://localhost:<PORT>` | REST API |
| Socket.IO | Real-time events (chat, notifications) |

### Chat / RAG

| Command | Description |
|---|---|
| `uvicorn src.api.app:app --reload` | Chat API server |
| `POST /chat` | Send a message (Arabic fashion assistant) |
| `POST /precompute-embeddings` | One-time embedding precomputation |
| `GET /health` | Health check |

### Try-On

| Command | Description |
|---|---|
| `python main.py` | Start try-on service |
| `http://localhost:8000/docs` | OpenAPI docs |
| `/api/tryon/*` | OOTDiffusion endpoints |
| `/api/truefit/*` | TrueFit endpoints |
| `/api/runway360/*` | 360° video preview |
| `/api/vton360/*` | VTON360 pipeline |
| `/api/measurements/*` | Body measurements & sizing |

## Environment Variables

Key variables by service:

### Backend

- `MONGO_URI` — MongoDB connection string
- `JWT_SECRET` / `REFRESH_TOKEN_SECRET` — Auth tokens
- `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_USER`, `EMAIL_PASS`, `EMAIL_FROM` — SMTP
- `CHAT_SERVICE_URL` — Python RAG service base URL
- `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` — Media storage
- `AI_SERVICE_URL` — Optional AI microservice
- `MEASUREMENTS_SERVICE_URL` — Try-on measurements service
- `SHAPY_SERVICE_URL` — Size recommendation service

### Chat / RAG

- `OPENROUTER_API_KEY` — LLM provider (Gemma 4 via OpenRouter)
- `MONGODB_URI` — Product database
- `LMSTUDIO_BASE_URL` — Local model endpoint (optional)

### Try-On

- `OPENROUTER_API_KEY` — TrueFit / LLM features
- `RUNWAY_API_KEY` — 360° video generation
- Provider-specific keys for Colab, Shapy, etc.

## Architecture

```
Browser (Next.js)
    │
    ├── REST API ──────────────► Backend (Express + MongoDB)
    │                              ├── Auth
    │                              ├── Products
    │                              ├── Orders
    │                              ├── Images (Cloudinary + Sharp)
    │                              └── Socket.IO (real-time)
    │
    ├── Chat ──────────────────► Chat Proxy (Backend)
    │                              └── RAG Service (FastAPI)
    │                                   ├── Intent Extraction (Gemma 4)
    │                                   ├── Hybrid Retrieval (Mongo + embeddings)
    │                                   ├── Outfit Assembly
    │                                   └── Response Composition
    │
    └── Try-On ────────────────► Try-On Service (FastAPI)
                                   ├── OOTDiffusion
                                   ├── TrueFit
                                   ├── Runway 360
                                   ├── VTON360
                                   └── Body Measurements
```

## License

MIT
