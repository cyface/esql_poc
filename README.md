# Electric SQL Sync POC

A proof-of-concept for real-time multi-client synchronization using Electric SQL. Open the app in multiple browser tabs and watch changes sync instantly between them.

## Stack

- **React 19** + **Vite** — frontend
- **Electric SQL** — real-time read sync from Postgres via shape streams
- **TanStack Query** — write mutations with optimistic UI
- **Zustand** — client-local UI state (identity, filters)
- **Express** + **pg** — write API server
- **PostgreSQL 18** — database (Docker)

## Prerequisites

- [pnpm](https://pnpm.io/) (see `packageManager` in package.json)
- [Docker](https://www.docker.com/) and Docker Compose

## Getting Started

```bash
# Install dependencies
pnpm install

# Start Postgres 18 + Electric sync service
pnpm db:up

# Start Vite dev server + Express API server
pnpm dev
```

Open http://localhost:5173 in two or more browser tabs. Each tab gets a random identity. Add, toggle, or delete todos in one tab and see them appear in the others.

## Scripts

| Script | Description |
|---|---|
| `pnpm dev` | Start Vite + Express API concurrently |
| `pnpm dev:frontend` | Start Vite only |
| `pnpm dev:server` | Start Express API only |
| `pnpm build` | Type check + production build |
| `pnpm lint` | Run ESLint |
| `pnpm db:up` | Start Docker services |
| `pnpm db:down` | Stop Docker services |
| `pnpm db:reset` | Tear down volumes + restart (clean DB) |

## Ports

| Service | Port |
|---|---|
| Vite dev server | 5173 |
| Express API | 4001 |
| Electric sync | 3000 |
| PostgreSQL | 54321 |

## Architecture

See [docs/01-architecture.md](docs/01-architecture.md) for the full architecture writeup, including data flow diagrams and library responsibility breakdown.
