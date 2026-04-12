# Electric SQL Sync POC

A proof-of-concept for real-time multi-client synchronization using Electric SQL. Open the app in multiple browser tabs and watch changes sync instantly between them.

## Stack

- **React 19** + **Vite** — frontend, deployed to Cloudflare Pages
- **TanStack DB** + **Electric SQL** — reactive client-side collection synced to Postgres in real time, with optimistic mutations
- **Zustand** — client-local UI state (identity, filters)
- **PostgREST** — auto-generated REST API from the Postgres schema (Docker)
- **PostgreSQL 18** — database (Docker)

## Prerequisites

- [pnpm](https://pnpm.io/) (see `packageManager` in package.json)
- [Docker](https://www.docker.com/) and Docker Compose

## Getting Started

```bash
# Install dependencies
pnpm install

# Start Postgres 18 + Electric + PostgREST
pnpm db:up

# Start Vite dev server
pnpm dev
```

Open http://localhost:5173 in two or more browser tabs. Each tab gets a random identity. Add, toggle, or delete todos in one tab and see them appear in the others.

## Scripts

| Script | Description |
|---|---|
| `pnpm dev` | Start Vite dev server |
| `pnpm build` | Type check + production build |
| `pnpm lint` | Run ESLint |
| `pnpm db:up` | Start Docker services (Postgres, Electric, PostgREST) |
| `pnpm db:down` | Stop Docker services |
| `pnpm db:reset` | Tear down volumes + restart (clean DB) |
| `pnpm deploy` | Build + deploy frontend to Cloudflare Pages |

## Ports

| Service | Port |
|---|---|
| Vite dev server | 5173 |
| PostgREST | 4001 |
| Electric sync | 3000 |
| PostgreSQL | 54321 |

## Architecture

See [docs/01-architecture.md](docs/01-architecture.md) for the full architecture writeup, including data flow diagrams and library responsibility breakdown.
