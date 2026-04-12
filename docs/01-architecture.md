# Architecture

## Overview

This is a proof-of-concept for real-time multi-client synchronization using Electric SQL. The app is a collaborative todo list where changes made in one browser tab appear instantly in all other connected tabs.

The two client-side libraries each own a distinct concern:

| Library | Concern | Scope |
|---|---|---|
| **TanStack DB + Electric SQL** | Read + write path | Syncs Postgres rows to a reactive client-side collection; handles optimistic mutations |
| **Zustand** | Client-local UI state | Per-tab identity, filter selection |

## Data Flow

```
  Browser Tab A                              Browser Tab B
  ┌─────────────────────┐                    ┌─────────────────────┐
  │  Zustand             │                    │  Zustand             │
  │  (filter, identity)  │                    │  (filter, identity)  │
  │         │            │                    │         │            │
  │  TanStack DB         │                    │  TanStack DB         │
  │  (Electric collection)│                    │  (Electric collection)│
  │  insert/update/delete ──── POST /todos ────────►              │
  │  useLiveQuery ◄───── shape stream ─────────── useLiveQuery    │
  └─────────────────────┘                    └─────────────────────┘
              │                                         ▲
              ▼                                         │
  ┌──────────────────────────────────────────────────────┐
  │  PostgREST (port 4001)                               │
  │  Auto-generated REST API from Postgres schema        │
  │  POST/PATCH/DELETE /todos  ──►  Postgres DML         │
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

1. Component calls `todosCollection.insert()`, `.update()`, or `.delete()`.
2. TanStack DB applies the change **optimistically** — the UI updates immediately.
3. The collection's persistence handler (`onInsert`, `onUpdate`, `onDelete`) fires asynchronously, sending a `fetch` request to PostgREST on port 4001.
4. PostgREST translates the HTTP request into a Postgres DML statement and executes it.
5. If the handler throws, TanStack DB **rolls back** the optimistic change automatically.

### Read path (Postgres -> all clients)

1. Postgres commits the row change.
2. Electric's sync service reads the change from the WAL (logical replication).
3. Electric pushes the change over HTTP to all clients subscribed to the `todos` shape.
4. The Electric collection in TanStack DB absorbs the update, reconciling it with any pending optimistic state.
5. All `useLiveQuery` hooks that reference the collection re-render with the new data.

### Optimistic state

TanStack DB handles optimistic state internally. When a mutation is made:

- The change appears in the collection immediately (before the API call completes).
- `useLiveQuery` results reflect the optimistic state.
- If the persistence handler succeeds, the optimistic state is eventually replaced by the confirmed server data arriving via the Electric shape stream.
- If the handler fails, the optimistic state is rolled back automatically.

No manual merge logic is needed — this is handled by TanStack DB's collection internals.

## Library Responsibilities

### TanStack DB + Electric SQL (`@tanstack/react-db` + `@tanstack/electric-db-collection`)

- Owns **both the read and write paths** through a single collection.
- `electricCollectionOptions` connects a TanStack DB collection to an Electric shape stream, syncing the `todos` table in real time.
- `useLiveQuery` provides reactive, SQL-like queries with filtering and sorting — results update automatically when the underlying collection changes.
- Collection mutation methods (`.insert()`, `.update()`, `.delete()`) are optimistic by default with auto-rollback.
- Persistence handlers (`onInsert`, `onUpdate`, `onDelete`) define how mutations are sent to PostgREST.

The collection is defined in `src/collection.ts`:

```ts
export const todosCollection = createCollection(
  electricCollectionOptions<Todo>({
    id: "todos",
    shapeOptions: {
      url: `${ELECTRIC_URL}/v1/shape`,
      params: { table: "todos" },
    },
    getKey: (todo) => todo.id,
    onInsert: async ({ transaction }) => {
      const todo = transaction.mutations[0].modified;
      await createTodo(todo.id, todo.title, todo.created_by);
    },
    // ...
  })
);
```

Reactive queries are used in `src/hooks/useTodos.ts`:

```ts
const { data: filteredTodos } = useLiveQuery(
  (q) => {
    const base = q.from({ todo: todosCollection });
    if (filter === "active")
      return base.where(({ todo }) => eq(todo.completed, false));
    if (filter === "completed")
      return base.where(({ todo }) => eq(todo.completed, true));
    return base;
  },
  [filter]
);
```

### Zustand

- Owns **client-local state** that does not belong in Postgres.
- `clientId`, `clientName`, `clientColor`: randomly generated per tab on load. Used to tag which client created a todo.
- `filter`: the current todo filter (all / active / completed). Pure UI state that parameterizes the `useLiveQuery` call.

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

Three services, defined in `docker-compose.yml`:

- **postgres** (`postgres:18-alpine`): The source of truth. Runs with `wal_level=logical` to enable Electric's logical replication. The `db/init.sql` script creates the `todos` table, sets `REPLICA IDENTITY FULL`, and creates the `anon` role for PostgREST.
- **electric** (`electricsql/electric:latest`): The sync service. Connects to Postgres, reads the WAL, and serves shape streams over HTTP on port 3000.
- **postgrest** (`postgrest/postgrest`): Auto-generated REST API from the Postgres schema. Exposes the `public` schema via the `anon` role on port 4001. Replaces the previous hand-written Express server.

### PostgREST API Conventions

PostgREST uses a different URL convention than a typical REST API:

| Operation | Method + URL |
|---|---|
| Create | `POST /todos` with JSON body |
| Update | `PATCH /todos?id=eq.{uuid}` with JSON body |
| Delete one | `DELETE /todos?id=eq.{uuid}` |
| Delete all | `DELETE /todos` |

The `Prefer: return=minimal` header suppresses response bodies on writes.

### Deployment

- **Frontend**: Cloudflare Pages. Configured via `wrangler.toml`. Deploy with `pnpm deploy`.
- **Backend**: Docker Compose for local dev. For production, the Postgres + Electric + PostgREST stack runs on a VPS or managed services. Cloudflare's CDN can be placed in front of Electric to cache shape streams (recommended for scaling).

### Ports

| Service | Port |
|---|---|
| Vite dev server | 5173 |
| PostgREST | 4001 |
| Electric sync | 3000 |
| Postgres | 54321 |

## File Map

```
esql_poc/
├── docker-compose.yml              # Postgres 18 + Electric + PostgREST
├── db/
│   └── init.sql                    # DDL + PostgREST role grants
├── src/
│   ├── main.tsx                    # React root
│   ├── App.tsx                     # Layout, composes all components
│   ├── electric.ts                 # Todo type definition
│   ├── collection.ts              # TanStack DB Electric collection
│   ├── api.ts                     # PostgREST fetch wrappers (used by collection handlers)
│   ├── store.ts                   # Zustand store (identity + filter)
│   ├── hooks/
│   │   └── useTodos.ts            # useLiveQuery + collection mutations
│   └── components/
│       ├── AddTodo.tsx            # Text input + submit
│       ├── TodoList.tsx           # Renders todo items
│       ├── FilterBar.tsx          # All/Active/Completed + Clear all
│       └── ClientInfo.tsx         # Shows current client name + color
├── package.json
├── pnpm-lock.yaml
├── .npmrc
├── wrangler.toml                  # Cloudflare Pages config
├── tsconfig.json                  # Project references
├── tsconfig.app.json              # Frontend TS config
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

PostgREST accesses this table via the `anon` role, which is granted `SELECT, INSERT, UPDATE, DELETE` on all tables in the `public` schema.
