# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Start everything (Vite + Express API, requires Docker already running)
pnpm dev

# Start infrastructure (Postgres 18 + Electric sync service)
pnpm db:up

# Tear down and recreate with clean DB
pnpm db:reset

# Run frontend or API server independently
pnpm dev:frontend
pnpm dev:server

# Type check (project references: app, node, server)
pnpm tsc -b

# Lint
pnpm lint

# Build for production
pnpm build
```

No test framework is configured yet.

## Architecture

This is a real-time multi-client sync POC using Electric SQL. It's a collaborative todo list where changes in one browser tab appear instantly in all others.

### Three-library split

Each client-side library owns one concern:

- **Electric SQL** (`@electric-sql/react`, `useShape`): Read path only. Subscribes to a Postgres table via Electric's shape stream HTTP endpoint. Does not handle writes.
- **TanStack Query** (`@tanstack/react-query`, `useMutation` + `useMutationState`): Write path only. Sends mutations to the Express API. `useMutationState` tracks in-flight creates for optimistic UI. This project does **not** use `useQuery` — reads are Electric's job.
- **Zustand**: Client-local state that doesn't need server sync (per-tab identity, UI filter selection).

### Data flow

Writes: React component -> TanStack Query mutation -> `fetch` to Express API (port 4001) -> `pg.Pool` INSERT/UPDATE/DELETE -> Postgres.

Reads: Postgres WAL -> Electric sync service (port 3000) -> HTTP shape stream -> `useShape` hook -> React re-render in all connected tabs.

Optimistic merge: `src/hooks/useTodos.ts` merges Electric's server data with TanStack Query's pending mutation state. Server data always wins when a todo ID exists in both.

### Infrastructure

Docker Compose runs two services:
- **postgres:18-alpine** on port 54321 — runs with `wal_level=logical` for Electric's replication
- **electricsql/electric** on port 3000 — reads the WAL and serves `/v1/shape` streams

The Express API server (port 4001) is a separate Node process, not Dockerized.

### Key conventions

- The `Todo` interface in `src/electric.ts` requires `[key: string]: unknown` index signature to satisfy Electric's `Row<unknown>` constraint.
- Postgres table must have `REPLICA IDENTITY FULL` for Electric to work with UPDATE/DELETE.
- UUIDs are generated client-side (`uuid` package) and sent with the create request.
- TypeScript uses project references: `tsconfig.app.json` (frontend), `tsconfig.server.json` (Express API), `tsconfig.node.json` (Vite config).

### Ports

| Service | Port |
|---|---|
| Vite dev server | 5173 |
| Express API | 4001 |
| Electric sync | 3000 |
| Postgres | 54321 |
