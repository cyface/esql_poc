# Scaling

## Default Limits

With the docker-compose setup and no configuration changes, a single Electric instance provides:

| Limit | Default |
|---|---|
| Concurrent initial syncs | 300 |
| Concurrent live subscriptions | 10,000 |
| Postgres connections used by Electric | ~22 (pool of 20 + replication + lock) |

These are controlled by the `ELECTRIC_MAX_CONCURRENT_REQUESTS` env var, which defaults to `{"initial": 300, "existing": 10000}`. When exceeded, Electric returns 503. Each live `useShape` subscription holds an HTTP long-poll connection open for up to 20 seconds before reconnecting.

## Connection Architecture

Electric uses a small, fixed number of Postgres connections regardless of how many clients or shapes are active:

| Connection type | Count | Purpose |
|---|---|---|
| Replication | 1 | Streams the WAL via logical replication. Cannot go through a pooler. Requires the `REPLICATION` role. |
| Lock | 1 | Holds a Postgres advisory lock to ensure only one Electric instance actively replicates (enables zero-downtime rolling deploys). |
| Admin pool | 1-4 | Schema inspection, publication management, WAL monitoring. Sized as `min(max(pool_size / 4, 1), 4)`. |
| Snapshot pool | Remainder of pool | Initial shape snapshots (`SELECT` queries for new shapes). This is where `ELECTRIC_DB_POOL_SIZE` matters. |

**Total**: roughly `ELECTRIC_DB_POOL_SIZE + 2`. With the default pool size of 20, that is ~22 connections.

All shapes share a single replication slot and WAL stream. The `ShapeLogCollector` process filters each WAL transaction against all registered shapes and routes matching changes to the appropriate shape logs. Adding more shapes or more clients does not add Postgres connections.

## What Scales Well

- **More clients** — clients connect to Electric via HTTP, not to Postgres. The Erlang/BEAM VM handles many thousands of lightweight concurrent connections natively.
- **More shapes** — shapes share the replication stream. No per-shape Postgres connection.
- **Simple WHERE clauses** — with `field = constant` filters, write latency stays flat at ~6ms even at 10,000 active shapes.

## Bottlenecks (in order of typical impact)

1. **Disk I/O** — Electric writes shape logs to disk. NVMe SSD is the single biggest lever. The v1.1 storage engine (Aug 2025) delivered 102x faster writes and 73x faster reads. Electric's deployment guide recommends optimizing in this order: disk speed, memory, CPU.
2. **Shape filtering with complex WHERE** — `ILIKE` or expression-based filters require evaluating every transaction against every active shape. Latency rises linearly with shape count. Simple equality filters (`field = constant`) stay flat.
3. **Single replication stream** — the `ShapeLogCollector` is a serialization point. Every WAL transaction passes through it.
4. **Postgres WAL growth** — the replication slot prevents WAL cleanup until Electric processes it. Set `max_slot_wal_keep_size` to 10-50GB as a safety cap on high-write workloads.
5. **HTTP connections (without CDN)** — the 20-second long-poll timeout means connections accumulate. Only a concern at scale without a CDN in front.

## Published Benchmarks

From Electric's official benchmarks and production customers:

| Scenario | Result |
|---|---|
| Concurrent clients, initial sync (500 rows) | 2,000 with stable memory |
| Concurrent clients, behind CDN | 100K - 1M |
| Write latency, optimized WHERE, single shape | ~6ms (3ms Postgres + 3ms Electric) |
| Write latency, optimized WHERE, 10K shapes | ~6ms (flat) |
| Write latency, non-optimized WHERE, 10K shapes | ~100ms |
| Write throughput, optimized WHERE | 4,000-6,000 row changes/sec |
| Single client initial sync | Up to 1M rows |
| Trigger.dev (production customer) | 20,000 changes/sec |
| Electric Cloud, sustained write load during 1M client test | 960 txn/min |

## Configuration Reference

Key environment variables for tuning the Electric service (set on the `electric` container in `docker-compose.yml`):

| Env var | Default | Purpose |
|---|---|---|
| `ELECTRIC_DB_POOL_SIZE` | `20` | Postgres connection pool for snapshots and admin. Set PG `max_connections` >= 3x this value. |
| `ELECTRIC_MAX_CONCURRENT_REQUESTS` | `{"initial": 300, "existing": 10000}` | Hard cap on in-flight HTTP requests. Returns 503 when exceeded. |
| `ELECTRIC_MAX_SHAPES` | No limit | Max concurrent shapes. Evicts LRU when exceeded (returns 409 to evicted clients). |
| `ELECTRIC_CONSUMER_PARTITIONS` | Auto (CPU cores) | Parallelism for shape consumer management. |
| `ELECTRIC_STORAGE` | `FAST_FILE` | `MEMORY` for dev/ephemeral; `FAST_FILE` for production (requires persistent filesystem). |
| `ELECTRIC_SHAPE_DB_CACHE_SIZE` | `4096KiB` | SQLite cache size for shape storage. Higher = more memory, faster reads. |
| `ELECTRIC_SHAPE_HIBERNATE_AFTER` | `30s` | Time before idle shape processes hibernate to save memory. |
| `ELECTRIC_SHAPE_SUSPEND_CONSUMER` | `false` | Terminate idle shape consumers entirely. Saves memory, costs CPU on resume. |
| `ELECTRIC_REPLICATION_STREAM_ID` | `default` | Suffix for replication slot/publication names. Change to run multiple Electric instances against the same Postgres. |
| `ELECTRIC_CACHE_MAX_AGE` | `60` | HTTP `Cache-Control` max-age in seconds. |
| `ELECTRIC_CACHE_STALE_AGE` | `300` | HTTP stale-age for cache headers. |
| `ELECTRIC_TCP_SEND_TIMEOUT` | `30s` | Timeout for sending response chunks. Increase for slow clients. |
| `ELECTRIC_REPLICATION_IDLE_TIMEOUT` | `0` (disabled) | Close DB connections after inactivity. Enables scale-to-zero but avoid with frequent writes. |
| `CLEANUP_REPLICATION_SLOTS_ON_SHUTDOWN` | `false` | Use temporary replication slot (dropped on disconnect). Good for dev/ephemeral. |

## Production Scaling Strategy

The primary production scaling strategy is to put a CDN (Cloudflare, Fastly, etc.) in front of Electric. The CDN collapses identical shape requests at the same offset into a single backend request, so Electric only sees deduplicated traffic. This is how the 100K-1M concurrent client numbers are achieved on a single commodity Postgres.

Horizontal read scaling is also possible: multiple Electric instances can serve shape logs in read-only mode from shared storage, while one primary instance holds the replication connection. The advisory lock ensures only one instance replicates at a time, enabling zero-downtime rolling deploys.

For this POC, the defaults are more than sufficient.
