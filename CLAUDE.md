# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Start infrastructure (Postgres 18 + Electric + PostgREST)
pnpm db:up

# Start Vite dev server
pnpm dev

# Tear down and recreate with clean DB
pnpm db:reset

# Type check (project references: app, node)
pnpm tsc -b

# Lint
pnpm lint

# Build for production
pnpm build

# Deploy frontend to Cloudflare Pages
pnpm deploy
```

No test framework is configured yet.

## Architecture

This is a real-time multi-client sync POC using Electric SQL. It's a collaborative todo list where changes in one browser tab appear instantly in all others.

### Two-library split

Each client-side library owns one concern:

- **TanStack DB + Electric SQL** (`@tanstack/react-db` + `@tanstack/electric-db-collection`): Read and write path. An Electric collection syncs the `todos` Postgres table into a reactive client-side store. `useLiveQuery` provides SQL-like reactive queries. Mutations (`.insert()`, `.update()`, `.delete()`) are optimistic by default with auto-rollback. Collection persistence handlers (`onInsert`, `onUpdate`, `onDelete`) send writes to PostgREST.
- **Zustand**: Client-local state that doesn't need server sync (per-tab identity, UI filter selection).

### Data flow

Writes: Component calls `todosCollection.insert()` -> UI updates immediately (optimistic) -> collection handler sends `fetch` to PostgREST (port 4001) -> PostgREST writes to Postgres. Rolls back on failure.

Reads: Postgres WAL -> Electric sync service (port 3000) -> shape stream -> Electric collection in TanStack DB -> `useLiveQuery` re-renders all connected tabs.

### Infrastructure

Docker Compose runs three services:
- **postgres:18-alpine** on port 54321 — runs with `wal_level=logical` for Electric's replication
- **electricsql/electric** on port 3000 — reads the WAL and serves `/v1/shape` streams
- **postgrest/postgrest** on port 4001 — auto-generated REST API from the Postgres schema, replaces the previous Express server

Frontend deploys to Cloudflare Pages (`wrangler.toml`). For local dev, use Vite dev server.

### Key conventions

- The `Todo` interface in `src/electric.ts` requires `[key: string]: unknown` index signature to satisfy Electric's `Row<unknown>` constraint.
- The Electric collection is a module-level singleton in `src/collection.ts`, not created inside React components.
- Postgres table must have `REPLICA IDENTITY FULL` for Electric to work with UPDATE/DELETE.
- UUIDs are generated client-side (`uuid` package) and sent with the create request.
- `src/api.ts` uses PostgREST conventions: filtering via query params (`?id=eq.{uuid}`), `Prefer: return=minimal` header.
- TypeScript uses project references: `tsconfig.app.json` (frontend), `tsconfig.node.json` (Vite config).

### Ports

| Service | Port |
|---|---|
| Vite dev server | 5173 |
| PostgREST | 4001 |
| Electric sync | 3000 |
| Postgres | 54321 |
