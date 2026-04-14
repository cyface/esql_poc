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

This is a real-time multi-client sync POC using Electric SQL. It's a collaborative Kanban board where ticket changes (drags, field edits, comments) in one browser tab appear instantly in all others.

### Database schema (7 tables)

- **boards** — top-level container (1 seeded board)
- **members** — board participants (4 seeded: Alice, Bob, Charlie, Diana)
- **columns** — Kanban columns with position ordering and optional WIP limits (6 seeded)
- **labels** — reusable color-coded tags (8 seeded)
- **tickets** — the main entity with 27 columns (priority, type, assignee, story points, time tracking, dates, sprint, environment, component, version, git branch, blocked status, etc.). 75 seeded.
- **ticket_labels** — many-to-many join table
- **comments** — ticket discussion threads (50 seeded)

All tables use `REPLICA IDENTITY FULL` for Electric compatibility.

### Two-library split

Each client-side library owns one concern:

- **TanStack DB + Electric SQL** (`@tanstack/react-db` + `@tanstack/electric-db-collection`): Real-time sync for dynamic tables (tickets, ticket_labels, comments). Electric collections provide optimistic mutations with auto-rollback. `useLiveQuery` provides reactive queries.
- **Zustand**: Client-local state that doesn't need server sync (per-tab identity, selected ticket, filters, search).

### Data flow

Writes: Component calls `ticketsCollection.update()` -> UI updates immediately (optimistic) -> `onUpdate` handler sends PATCH to PostgREST (port 4001) -> PostgREST writes to Postgres.

Reads: Postgres WAL -> Electric sync service (port 3000) -> shape stream -> Electric collection in TanStack DB -> `useLiveQuery` re-renders all connected tabs.

### Static vs. dynamic data

- **Static** (boards, members, columns, labels): Loaded once from PostgREST on mount. No Electric shape stream. These are seed data that doesn't change during the demo.
- **Dynamic** (tickets, ticket_labels, comments): Synced in real-time via Electric shape streams. Limited to 3 streams to stay within HTTP/1.1's 6-connection-per-origin browser limit.

### Infrastructure

Docker Compose runs three services:
- **postgres:18-alpine** on port 54321 — runs with `wal_level=logical` for Electric's replication
- **electricsql/electric** on port 3000 — reads the WAL and serves `/v1/shape` streams
- **postgrest/postgrest** on port 4001 — auto-generated REST API from the Postgres schema

Frontend deploys to Cloudflare Pages (`wrangler.toml`). For local dev, use Vite dev server.

### Key conventions

- All type interfaces in `src/types.ts` require `[key: string]: unknown` index signature to satisfy Electric's `Row<unknown>` constraint.
- Electric collections are module-level singletons in `src/collections.ts`, not created inside React components.
- Ticket `onUpdate` handler uses a pending-updates map (`queueTicketUpdate`) to send only changed fields to PostgREST, avoiding a feedback loop where full-object PATCHes cause Electric sync-back → `onUpdate` → repeat.
- Drag-and-drop uses fractional positioning (`REAL` column). Insert between two cards: `position = (above + below) / 2`.
- Postgres tables must have `REPLICA IDENTITY FULL` for Electric to work with UPDATE/DELETE.
- UUIDs are generated client-side (`uuid` package) and sent with the create request.
- `src/api.ts` uses PostgREST conventions: filtering via query params (`?id=eq.{uuid}`), `Prefer: return=minimal` header.
- Shared constants (priorities, types, statuses, colors, icons) live in `src/constants.ts`.
- TypeScript uses project references: `tsconfig.app.json` (frontend), `tsconfig.node.json` (Vite config).

### Ports

| Service | Port |
|---|---|
| Vite dev server | 5173 |
| PostgREST | 4001 |
| Electric sync | 3000 |
| Postgres | 54321 |
