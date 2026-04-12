# Architecture

## Overview

This is a proof-of-concept for real-time multi-client synchronization using Electric SQL. The app is a collaborative todo list where changes made in one browser tab appear instantly in all other connected tabs.

The three client-side libraries each own a distinct concern:

| Library | Concern | Scope |
|---|---|---|
| **Electric SQL** | Read path | Streams Postgres rows to the browser in real time |
| **TanStack Query** | Write path | Sends mutations to the API, tracks optimistic state |
| **Zustand** | Client-local UI state | Per-tab identity, filter selection |

## Data Flow

```
  Browser Tab A                              Browser Tab B
  ┌─────────────────────┐                    ┌─────────────────────┐
  │  Zustand             │                    │  Zustand             │
  │  (filter, identity)  │                    │  (filter, identity)  │
  │         │            │                    │         │            │
  │  TanStack Query      │                    │  TanStack Query      │
  │  (mutations)  ──────────── POST /api ──────────►              │
  │         │            │                    │                      │
  │  Electric SQL        │                    │  Electric SQL        │
  │  (useShape) ◄───── shape stream ─────────── (useShape)        │
  └─────────────────────┘                    └─────────────────────┘
              │                                         ▲
              ▼                                         │
  ┌──────────────────────────────────────────────────────┐
  │  Express API (port 4001)                             │
  │  POST/PATCH/DELETE /api/todos  ──►  Postgres INSERT  │
  └──────────────────────────────────────────────────────┘
              │                                         ▲
              ▼                                         │
  ┌──────────────────────────────────────────────────────┐
  │  PostgreSQL 18  (port 54321)                         │
  │  wal_level=logical                                   │
  │          │                                           │
  │          ▼                                           │
  │  Electric Sync Service  (port 3000)                  │
  │  Reads WAL, pushes changes via /v1/shape             │
  └──────────────────────────────────────────────────────┘
```

### Write path (client -> Postgres)

1. User action triggers a TanStack Query `useMutation` call.
2. `onMutate` returns an optimistic `Todo` object, stored as mutation context.
3. The mutation function sends a `fetch` request to the Express API on port 4001.
4. The API writes directly to Postgres using the `pg` connection pool.
5. The mutation settles (success or error).

### Read path (Postgres -> all clients)

1. Postgres commits the row change.
2. Electric's sync service reads the change from the WAL (logical replication).
3. Electric pushes the change over HTTP to all clients subscribed to the `todos` shape.
4. `useShape<Todo>` updates its `data` array, triggering a React re-render.

### Optimistic merge

Between steps 3 and 5 above there is a brief window where the write has been sent but Electric hasn't confirmed it yet. During this window:

- `useMutationState` surfaces all pending `createTodo` mutations.
- `useTodos` merges pending optimistic todos into the server data using a `Map<id, Todo>`.
- Server data always wins (if a todo already exists in the Electric data, the optimistic entry is discarded).

This merge happens in `src/hooks/useTodos.ts`:

```ts
const map = new Map<string, Todo>();
for (const todo of serverTodos) {
  map.set(todo.id, todo);
}
for (const todo of pendingCreates) {
  if (!map.has(todo.id)) {
    map.set(todo.id, todo);
  }
}
```

## Library Responsibilities

### Electric SQL (`@electric-sql/react`)

- Owns the **read path** exclusively.
- `useShape<Todo>(todosShapeOptions)` subscribes to the `todos` table.
- The shape stream is an HTTP connection to Electric's `/v1/shape` endpoint.
- Electric does **not** handle writes. It is a read-only sync layer.

Configuration is in `src/electric.ts`:

```ts
export const todosShapeOptions = {
  url: `${ELECTRIC_URL}/v1/shape`,
  params: { table: "todos" },
};
```

### TanStack Query (`@tanstack/react-query`)

- Owns the **write path** and **optimistic state tracking**.
- `useMutation` sends writes to the Express API.
- `useMutationState` provides a list of in-flight mutations so the UI can display optimistic entries before Electric confirms them.
- `QueryClientProvider` wraps the app in `src/main.tsx`.

This project does **not** use `useQuery` from TanStack Query -- reads are handled entirely by Electric's `useShape`. TanStack Query is here only for its mutation and optimistic state primitives.

### Zustand

- Owns **client-local state** that does not belong in Postgres.
- `clientId`, `clientName`, `clientColor`: randomly generated per tab on load. Used to tag which client created a todo.
- `filter`: the current todo filter (all / active / completed). Pure UI state, not synced.

Store is defined in `src/store.ts`:

```ts
export const useAppStore = create<AppState>((set) => ({
  clientId: crypto.randomUUID(),
  clientName: pickRandom(NAMES),
  clientColor: pickRandom(COLORS),
  filter: "all",
  setFilter: (filter) => set({ filter }),
}));
```

## Infrastructure

### Docker Compose

Two services, defined in `docker-compose.yml`:

- **postgres** (`postgres:18-alpine`): The source of truth. Runs with `wal_level=logical` to enable Electric's logical replication. The `db/init.sql` script creates the `todos` table and sets `REPLICA IDENTITY FULL` on startup.
- **electric** (`electricsql/electric:latest`): The sync service. Connects to Postgres, reads the WAL, and serves shape streams over HTTP on port 3000.

### Express API Server

A minimal write API in `server/index.ts`. Four endpoints:

| Method | Path | Action |
|---|---|---|
| `POST` | `/api/todos` | Insert a new todo |
| `PATCH` | `/api/todos/:id` | Toggle completed status |
| `DELETE` | `/api/todos/:id` | Delete a single todo |
| `DELETE` | `/api/todos` | Clear all todos |

All endpoints write directly to Postgres via `pg.Pool`. There is no ORM.

### Ports

| Service | Port |
|---|---|
| Vite dev server | 5173 |
| Express API | 4001 |
| Electric sync | 3000 |
| Postgres | 54321 |

## File Map

```
esql_poc/
├── docker-compose.yml              # Postgres 18 + Electric service
├── db/
│   └── init.sql                    # DDL: todos table + replica identity
├── server/
│   └── index.ts                    # Express write API
├── src/
│   ├── main.tsx                    # React root + QueryClientProvider
│   ├── App.tsx                     # Layout, composes all components
│   ├── electric.ts                 # Todo type + Electric shape config
│   ├── api.ts                     # fetch wrappers for the write API
│   ├── store.ts                   # Zustand store (identity + filter)
│   ├── hooks/
│   │   └── useTodos.ts            # Combines Electric + TQ + Zustand
│   └── components/
│       ├── AddTodo.tsx            # Text input + submit
│       ├── TodoList.tsx           # Renders todo items
│       ├── FilterBar.tsx          # All/Active/Completed + Clear all
│       └── ClientInfo.tsx         # Shows current client name + color
├── package.json
├── pnpm-lock.yaml
├── .npmrc
├── tsconfig.json                  # Project references
├── tsconfig.app.json              # Frontend TS config
├── tsconfig.server.json           # Server TS config
└── vite.config.ts
```

## Database Schema

Single table (`db/init.sql`):

```sql
CREATE TABLE IF NOT EXISTS todos (
  id          UUID PRIMARY KEY,
  title       TEXT NOT NULL,
  completed   BOOLEAN NOT NULL DEFAULT false,
  created_by  TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE todos REPLICA IDENTITY FULL;
```

`REPLICA IDENTITY FULL` is required by Electric so that UPDATE and DELETE WAL entries include the full row, not just the primary key.
