-- PostgREST anonymous access role
CREATE ROLE anon NOLOGIN;

-- ============================================================
-- SCHEMA
-- ============================================================

CREATE TABLE boards (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE members (
  id UUID PRIMARY KEY,
  board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  avatar_url TEXT,
  color TEXT NOT NULL DEFAULT '#3498db',
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin','member','viewer')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE columns (
  id UUID PRIMARY KEY,
  board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT,
  position REAL NOT NULL DEFAULT 0,
  wip_limit INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE labels (
  id UUID PRIMARY KEY,
  board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#888888'
);

CREATE TABLE tickets (
  id UUID PRIMARY KEY,
  board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  column_id UUID NOT NULL REFERENCES columns(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','in_progress','in_review','done','closed')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('critical','high','medium','low','none')),
  type TEXT NOT NULL DEFAULT 'task' CHECK (type IN ('bug','feature','task','improvement','epic','story')),
  assignee_id UUID REFERENCES members(id) ON DELETE SET NULL,
  reporter_id UUID REFERENCES members(id) ON DELETE SET NULL,
  story_points INTEGER,
  time_estimate_minutes INTEGER,
  time_spent_minutes INTEGER DEFAULT 0,
  due_date DATE,
  start_date DATE,
  sprint TEXT,
  environment TEXT,
  component TEXT,
  version TEXT,
  git_branch TEXT,
  external_url TEXT,
  position REAL NOT NULL DEFAULT 0,
  is_blocked BOOLEAN NOT NULL DEFAULT false,
  blocked_reason TEXT,
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ticket_labels (
  id UUID PRIMARY KEY,
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  label_id UUID NOT NULL REFERENCES labels(id) ON DELETE CASCADE,
  UNIQUE(ticket_id, label_id)
);

CREATE TABLE comments (
  id UUID PRIMARY KEY,
  ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
  author_id UUID REFERENCES members(id) ON DELETE SET NULL,
  body TEXT NOT NULL,
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Electric requires full row data in WAL for UPDATE/DELETE
ALTER TABLE boards REPLICA IDENTITY FULL;
ALTER TABLE members REPLICA IDENTITY FULL;
ALTER TABLE columns REPLICA IDENTITY FULL;
ALTER TABLE labels REPLICA IDENTITY FULL;
ALTER TABLE tickets REPLICA IDENTITY FULL;
ALTER TABLE ticket_labels REPLICA IDENTITY FULL;
ALTER TABLE comments REPLICA IDENTITY FULL;

-- PostgREST: grant access to the anon role
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon;

-- ============================================================
-- SEED DATA
-- ============================================================

-- Board
INSERT INTO boards (id, name, description) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'Engineering Sprint Board', 'Main engineering team sprint board for Q2 2026');

-- Members
INSERT INTO members (id, board_id, name, color, role) VALUES
  ('a1000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'Alice',   '#e74c3c', 'admin'),
  ('a1000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'Bob',     '#3498db', 'member'),
  ('a1000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 'Charlie', '#2ecc71', 'member'),
  ('a1000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000001', 'Diana',   '#f39c12', 'member');

-- Columns
INSERT INTO columns (id, board_id, name, color, position, wip_limit) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'Backlog',     '#6b7280', 1.0, NULL),
  ('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'To Do',       '#3b82f6', 2.0, 8),
  ('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 'In Progress', '#f59e0b', 3.0, 5),
  ('c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000001', 'In Review',   '#8b5cf6', 4.0, 4),
  ('c0000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000001', 'Done',        '#10b981', 5.0, NULL),
  ('c0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000001', 'Released',    '#6366f1', 6.0, NULL);

-- Labels
INSERT INTO labels (id, board_id, name, color) VALUES
  ('a2000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'bug',           '#ef4444'),
  ('a2000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'feature',       '#3b82f6'),
  ('a2000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 'improvement',   '#f59e0b'),
  ('a2000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000001', 'tech-debt',     '#6b7280'),
  ('a2000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000001', 'documentation', '#10b981'),
  ('a2000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000001', 'design',        '#ec4899'),
  ('a2000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000001', 'testing',       '#8b5cf6'),
  ('a2000000-0000-0000-0000-000000000008', 'b0000000-0000-0000-0000-000000000001', 'security',      '#f97316');

-- Tickets: Backlog (20 tickets)
INSERT INTO tickets (id, board_id, column_id, title, description, status, priority, type, assignee_id, reporter_id, story_points, time_estimate_minutes, time_spent_minutes, due_date, start_date, sprint, environment, component, version, git_branch, external_url, position, is_blocked, blocked_reason, created_by) VALUES
  ('a3000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Implement OAuth2 social login', 'Add Google and GitHub OAuth2 login options to the auth flow. Should support account linking for existing email users.', 'open', 'high', 'feature', NULL, 'a1000000-0000-0000-0000-000000000001', 8, 960, 0, '2026-05-15', NULL, 'Sprint 14', NULL, 'auth', '2.1.0', NULL, NULL, 1.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Database connection pooling', 'Switch from direct connections to PgBouncer for connection pooling. Current setup maxes out at 100 connections under load.', 'open', 'medium', 'improvement', NULL, 'a1000000-0000-0000-0000-000000000002', 5, 480, 0, NULL, NULL, NULL, 'production', 'database', '2.1.0', NULL, NULL, 2.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Migrate to ESM modules', 'Convert remaining CommonJS modules to ESM. Blocked until Node 22 upgrade is complete.', 'open', 'low', 'improvement', NULL, 'a1000000-0000-0000-0000-000000000003', 13, 1920, 0, NULL, NULL, NULL, NULL, 'build', '3.0.0', NULL, NULL, 3.0, true, 'Requires Node 22 upgrade first', 'Charlie'),
  ('a3000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Add WebSocket heartbeat', 'Implement ping/pong heartbeat to detect stale WebSocket connections. Currently dead connections linger for up to 30 minutes.', 'open', 'medium', 'feature', NULL, 'a1000000-0000-0000-0000-000000000001', 3, 240, 0, NULL, NULL, 'Sprint 15', NULL, 'realtime', '2.1.0', NULL, NULL, 4.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Audit trail for admin actions', 'Log all admin panel actions (user bans, config changes, role assignments) to an immutable audit table.', 'open', 'high', 'feature', NULL, 'a1000000-0000-0000-0000-000000000004', 8, 960, 0, '2026-05-30', NULL, 'Sprint 15', NULL, 'admin', '2.2.0', NULL, NULL, 5.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Dark mode support', 'Implement dark mode theme toggle with system preference detection and localStorage persistence.', 'open', 'low', 'feature', NULL, 'a1000000-0000-0000-0000-000000000002', 5, 600, 0, NULL, NULL, NULL, NULL, 'ui', '2.2.0', NULL, NULL, 6.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'CSV export for reports', 'Allow users to export filtered report data as CSV. Include date range, column selection, and encoding options.', 'open', 'medium', 'feature', NULL, 'a1000000-0000-0000-0000-000000000003', 3, 360, 0, NULL, NULL, NULL, NULL, 'reports', '2.1.0', NULL, NULL, 7.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000008', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Rate limiting on public API', 'Add per-IP and per-token rate limiting to all public endpoints. Use sliding window algorithm with Redis backing.', 'open', 'critical', 'feature', NULL, 'a1000000-0000-0000-0000-000000000001', 5, 480, 0, '2026-04-25', NULL, 'Sprint 14', 'production', 'api', '2.1.0', NULL, NULL, 8.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000009', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Refactor notification service', 'Extract notification logic from user service into dedicated microservice. Support email, push, and in-app channels.', 'open', 'medium', 'improvement', NULL, 'a1000000-0000-0000-0000-000000000004', 13, 2400, 0, NULL, NULL, NULL, NULL, 'notifications', '3.0.0', NULL, NULL, 9.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000010', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Image upload size validation', 'Client-side validation shows 5MB limit but server accepts 10MB. Align both to 5MB and add proper error messages.', 'open', 'low', 'bug', NULL, 'a1000000-0000-0000-0000-000000000002', 2, 120, 0, NULL, NULL, NULL, NULL, 'uploads', '2.0.3', NULL, NULL, 10.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000011', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Implement feature flags service', 'Build a feature flag system supporting percentage rollouts, user segment targeting, and A/B testing.', 'open', 'high', 'feature', NULL, 'a1000000-0000-0000-0000-000000000001', 13, 1920, 0, '2026-06-01', NULL, 'Sprint 16', NULL, 'platform', '2.2.0', NULL, NULL, 11.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000012', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Upgrade Postgres to 18', 'Plan and execute Postgres 17 to 18 upgrade. Test logical replication compatibility, run pgbench, verify all extensions.', 'open', 'medium', 'task', NULL, 'a1000000-0000-0000-0000-000000000003', 5, 720, 0, NULL, NULL, NULL, 'staging', 'database', '2.1.0', NULL, NULL, 12.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000013', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Add OpenTelemetry tracing', 'Instrument all HTTP handlers and database calls with OpenTelemetry spans. Export to Grafana Tempo.', 'open', 'medium', 'feature', NULL, 'a1000000-0000-0000-0000-000000000004', 8, 960, 0, NULL, NULL, 'Sprint 15', 'production', 'observability', '2.1.0', NULL, NULL, 13.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000014', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Mobile responsive nav menu', 'Navigation hamburger menu is broken on screens < 768px. Menu items overlap and close button is hidden.', 'open', 'high', 'bug', NULL, 'a1000000-0000-0000-0000-000000000002', 3, 240, 0, '2026-04-20', NULL, 'Sprint 14', NULL, 'ui', '2.0.3', NULL, NULL, 14.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000015', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Implement RBAC permissions', 'Replace simple role checks with fine-grained RBAC. Define permissions matrix for admin, editor, viewer roles.', 'open', 'high', 'feature', NULL, 'a1000000-0000-0000-0000-000000000001', 13, 1920, 0, '2026-06-15', NULL, 'Sprint 16', NULL, 'auth', '2.2.0', NULL, NULL, 15.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000016', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Localization framework setup', 'Set up i18next with React integration. Extract all hardcoded strings. Start with English and Spanish.', 'open', 'low', 'feature', NULL, 'a1000000-0000-0000-0000-000000000003', 8, 1200, 0, NULL, NULL, NULL, NULL, 'ui', '3.0.0', NULL, NULL, 16.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000017', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'API documentation generator', 'Auto-generate OpenAPI 3.1 spec from route definitions. Serve Swagger UI at /docs endpoint.', 'open', 'medium', 'task', NULL, 'a1000000-0000-0000-0000-000000000004', 5, 600, 0, NULL, NULL, NULL, NULL, 'api', '2.1.0', NULL, NULL, 17.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000018', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Stale cache invalidation bug', 'User profile changes not reflected until hard refresh. Suspect stale CDN cache or missing Cache-Control headers.', 'open', 'medium', 'bug', NULL, 'a1000000-0000-0000-0000-000000000002', 3, 360, 0, NULL, NULL, NULL, 'production', 'caching', '2.0.3', NULL, NULL, 18.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000019', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Kubernetes HPA configuration', 'Configure horizontal pod autoscaler for API pods. Target 70% CPU utilization, min 2, max 10 replicas.', 'open', 'medium', 'task', NULL, 'a1000000-0000-0000-0000-000000000001', 3, 240, 0, NULL, NULL, NULL, 'production', 'infrastructure', '2.1.0', NULL, NULL, 19.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000020', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Accessibility audit remediation', 'Fix all WCAG 2.1 AA violations found in latest audit: missing alt text, low contrast ratios, keyboard traps.', 'open', 'high', 'task', NULL, 'a1000000-0000-0000-0000-000000000003', 8, 1200, 0, '2026-05-01', NULL, 'Sprint 15', NULL, 'ui', '2.1.0', NULL, NULL, 20.0, false, NULL, 'Charlie');

-- Tickets: To Do (15 tickets)
INSERT INTO tickets (id, board_id, column_id, title, description, status, priority, type, assignee_id, reporter_id, story_points, time_estimate_minutes, time_spent_minutes, due_date, start_date, sprint, environment, component, version, git_branch, external_url, position, is_blocked, blocked_reason, created_by) VALUES
  ('a3000000-0000-0000-0000-000000000021', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Fix timezone handling in scheduler', 'Scheduled jobs fire at wrong times for users in non-UTC timezones. Store all times as UTC, convert on display.', 'open', 'critical', 'bug', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 5, 480, 0, '2026-04-18', '2026-04-14', 'Sprint 14', 'production', 'scheduler', '2.0.3', 'fix/timezone-scheduler', NULL, 1.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000022', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Search indexing pipeline', 'Build Elasticsearch indexing pipeline for product catalog. Support full-text search with fuzzy matching.', 'open', 'high', 'feature', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', 8, 1200, 0, '2026-04-30', '2026-04-14', 'Sprint 14', NULL, 'search', '2.1.0', 'feat/search-pipeline', NULL, 2.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000023', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Redis cluster migration', 'Migrate from single Redis instance to 3-node cluster for HA. Update all connection strings and test failover.', 'open', 'high', 'task', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000004', 5, 600, 0, '2026-04-25', NULL, 'Sprint 14', 'staging', 'infrastructure', '2.1.0', NULL, NULL, 3.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000024', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'User onboarding wizard', 'Create a 4-step onboarding wizard for new users: profile setup, preferences, team invite, quick tour.', 'open', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000003', 8, 960, 0, '2026-05-10', NULL, 'Sprint 15', NULL, 'ui', '2.1.0', 'feat/onboarding', NULL, 4.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000025', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Memory leak in dashboard', 'Dashboard page leaks ~2MB per minute when left open. Suspect uncleared intervals or detached DOM nodes.', 'open', 'critical', 'bug', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 5, 360, 0, '2026-04-16', '2026-04-13', 'Sprint 14', 'production', 'dashboard', '2.0.3', 'fix/dashboard-leak', NULL, 5.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000026', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'GraphQL schema stitching', 'Merge user and billing GraphQL schemas into unified gateway. Implement field-level authorization.', 'open', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000004', 8, 1200, 0, '2026-05-15', NULL, 'Sprint 15', NULL, 'api', '2.2.0', NULL, NULL, 6.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000027', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'CI pipeline optimization', 'Build times increased from 8 to 22 minutes. Profile pipeline, add caching, parallelize test suites.', 'open', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 5, 480, 0, NULL, NULL, 'Sprint 14', NULL, 'build', '2.1.0', 'chore/ci-speedup', NULL, 7.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000028', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Email template engine', 'Replace hardcoded HTML emails with Handlebars templates. Support preview mode and variable substitution.', 'open', 'low', 'feature', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000003', 5, 600, 0, NULL, NULL, 'Sprint 15', NULL, 'notifications', '2.1.0', NULL, NULL, 8.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000029', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Fix payment webhook retry logic', 'Stripe webhooks fail silently after 3 retries. Need exponential backoff and dead letter queue.', 'open', 'high', 'bug', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 5, 480, 0, '2026-04-20', '2026-04-14', 'Sprint 14', 'production', 'payments', '2.0.3', 'fix/webhook-retry', NULL, 9.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000030', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'S3 multipart upload support', 'Large file uploads (>100MB) timeout. Implement multipart upload with progress tracking and resume.', 'open', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 5, 600, 0, NULL, NULL, 'Sprint 15', NULL, 'uploads', '2.1.0', NULL, NULL, 10.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000031', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Database query analyzer', 'Build dashboard showing slow queries, missing indexes, and table bloat. Pull from pg_stat_statements.', 'open', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000004', 8, 960, 0, NULL, NULL, NULL, 'production', 'database', '2.2.0', NULL, NULL, 11.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000032', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Two-factor authentication', 'Add TOTP-based 2FA with QR code setup, backup codes, and recovery flow.', 'open', 'high', 'feature', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000001', 8, 960, 0, '2026-05-01', NULL, 'Sprint 15', NULL, 'auth', '2.1.0', 'feat/2fa', NULL, 12.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000033', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'Webhook delivery dashboard', 'Build UI showing webhook delivery status, response times, and failure rates per endpoint.', 'open', 'low', 'feature', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000003', 5, 600, 0, NULL, NULL, NULL, NULL, 'admin', '2.2.0', NULL, NULL, 13.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000034', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'E2E test suite for checkout', 'Write Playwright E2E tests covering: add to cart, promo codes, payment methods, order confirmation.', 'open', 'medium', 'task', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 8, 960, 0, NULL, NULL, 'Sprint 15', NULL, 'testing', '2.1.0', NULL, NULL, 14.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000035', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'API versioning strategy', 'Implement URL-based API versioning (v1/v2). Set up automated compatibility testing between versions.', 'open', 'medium', 'task', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000004', 5, 480, 0, NULL, NULL, NULL, NULL, 'api', '2.1.0', NULL, NULL, 15.0, true, 'Waiting on API design doc approval', 'Diana');

-- Tickets: In Progress (15 tickets)
INSERT INTO tickets (id, board_id, column_id, title, description, status, priority, type, assignee_id, reporter_id, story_points, time_estimate_minutes, time_spent_minutes, due_date, start_date, sprint, environment, component, version, git_branch, external_url, position, is_blocked, blocked_reason, created_by) VALUES
  ('a3000000-0000-0000-0000-000000000036', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Real-time notification system', 'Implement WebSocket-based notifications for mentions, assignments, and status changes. Include desktop push support.', 'in_progress', 'high', 'feature', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 8, 960, 420, '2026-04-20', '2026-04-07', 'Sprint 14', NULL, 'realtime', '2.1.0', 'feat/realtime-notifs', NULL, 1.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000037', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Migrate user avatars to CDN', 'Move avatar storage from local disk to CloudFront CDN. Implement on-the-fly resizing with Sharp.', 'in_progress', 'medium', 'task', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 5, 480, 300, '2026-04-18', '2026-04-09', 'Sprint 14', 'staging', 'uploads', '2.1.0', 'chore/avatar-cdn', NULL, 2.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000038', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Form validation library', 'Build reusable form validation with Zod schemas. Support async validation, field-level errors, and i18n messages.', 'in_progress', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000003', 5, 600, 240, '2026-04-22', '2026-04-08', 'Sprint 14', NULL, 'ui', '2.1.0', 'feat/form-validation', NULL, 3.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000039', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Batch API endpoint', 'Allow clients to send up to 20 API requests in a single HTTP call. Implement parallel execution with partial failure handling.', 'in_progress', 'high', 'feature', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000001', 8, 720, 360, '2026-04-20', '2026-04-07', 'Sprint 14', NULL, 'api', '2.1.0', 'feat/batch-api', NULL, 4.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000040', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Fix race condition in order processing', 'Concurrent orders for limited inventory items can both succeed. Need distributed lock or optimistic concurrency.', 'in_progress', 'critical', 'bug', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000004', 5, 480, 180, '2026-04-15', '2026-04-10', 'Sprint 14', 'production', 'orders', '2.0.3', 'fix/order-race', NULL, 5.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000041', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Admin dashboard analytics', 'Build analytics overview: DAU/MAU, revenue charts, top products, conversion funnel. Use Recharts.', 'in_progress', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 8, 1200, 480, '2026-04-25', '2026-04-03', 'Sprint 14', NULL, 'dashboard', '2.1.0', 'feat/admin-analytics', NULL, 6.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000042', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Implement request caching layer', 'Add Redis caching for GET endpoints with configurable TTL. Support cache tags for targeted invalidation.', 'in_progress', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000003', 5, 480, 120, '2026-04-22', '2026-04-10', 'Sprint 14', NULL, 'api', '2.1.0', 'feat/request-cache', NULL, 7.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000043', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Database migration tooling', 'Replace manual SQL scripts with proper migration framework. Support up/down migrations, dry-run mode.', 'in_progress', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000004', 5, 600, 300, '2026-04-20', '2026-04-07', 'Sprint 14', NULL, 'database', '2.1.0', 'chore/migrations', NULL, 8.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000044', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'SSO SAML integration', 'Add SAML 2.0 SSO for enterprise customers. Support IdP-initiated and SP-initiated flows.', 'in_progress', 'high', 'feature', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 13, 1920, 960, '2026-04-28', '2026-03-28', 'Sprint 14', 'staging', 'auth', '2.1.0', 'feat/saml-sso', NULL, 9.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000045', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Performance budget enforcement', 'Set up Lighthouse CI with performance budgets. Block PRs that degrade LCP, FID, or CLS beyond thresholds.', 'in_progress', 'medium', 'task', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 3, 360, 120, NULL, '2026-04-10', 'Sprint 14', NULL, 'build', '2.1.0', 'chore/perf-budget', NULL, 10.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000046', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Multi-tenant data isolation', 'Implement row-level security policies for tenant isolation. Each tenant must only see their own data.', 'in_progress', 'critical', 'feature', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', 13, 1920, 720, '2026-04-22', '2026-04-01', 'Sprint 14', 'staging', 'database', '2.1.0', 'feat/multi-tenant', NULL, 11.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000047', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Drag-and-drop file upload', 'Add drag-and-drop zone to file upload areas. Show preview for images, file size, and upload progress.', 'in_progress', 'low', 'feature', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000003', 3, 360, 180, NULL, '2026-04-09', 'Sprint 14', NULL, 'ui', '2.1.0', 'feat/dnd-upload', NULL, 12.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000048', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Error boundary improvements', 'Add granular error boundaries per route segment. Include retry button, error reporting, and fallback UI.', 'in_progress', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000004', 3, 240, 120, NULL, '2026-04-11', 'Sprint 14', NULL, 'ui', '2.1.0', 'feat/error-boundaries', NULL, 13.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000049', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'API response compression', 'Enable gzip/brotli compression for API responses >1KB. Measure bandwidth savings and latency impact.', 'in_progress', 'low', 'improvement', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 2, 180, 60, NULL, '2026-04-11', 'Sprint 14', NULL, 'api', '2.1.0', 'chore/compression', NULL, 14.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000050', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'Structured logging migration', 'Migrate from console.log to pino structured logging. Add request ID correlation, log levels, and JSON output.', 'in_progress', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000001', 5, 480, 240, '2026-04-18', '2026-04-07', 'Sprint 14', NULL, 'observability', '2.1.0', 'chore/structured-logs', NULL, 15.0, false, NULL, 'Alice');

-- Tickets: In Review (10 tickets)
INSERT INTO tickets (id, board_id, column_id, title, description, status, priority, type, assignee_id, reporter_id, story_points, time_estimate_minutes, time_spent_minutes, due_date, start_date, sprint, environment, component, version, git_branch, external_url, position, is_blocked, blocked_reason, created_by) VALUES
  ('a3000000-0000-0000-0000-000000000051', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'JWT refresh token rotation', 'Implement refresh token rotation with reuse detection. Invalidate entire token family on suspected theft.', 'in_review', 'high', 'feature', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 8, 720, 660, '2026-04-15', '2026-04-01', 'Sprint 14', 'staging', 'auth', '2.1.0', 'feat/token-rotation', NULL, 1.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000052', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Fix N+1 query in user list', 'User list endpoint makes N+1 queries for profile images. Add eager loading with DataLoader pattern.', 'in_review', 'high', 'bug', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000003', 3, 240, 180, '2026-04-14', '2026-04-08', 'Sprint 14', 'production', 'api', '2.0.3', 'fix/user-list-n1', NULL, 2.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000053', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Component library documentation', 'Document all shared React components with Storybook. Include usage examples, prop tables, and accessibility notes.', 'in_review', 'medium', 'task', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000003', 5, 600, 540, '2026-04-16', '2026-04-03', 'Sprint 14', NULL, 'ui', '2.1.0', 'docs/component-library', NULL, 3.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000054', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Implement request deduplication', 'Deduplicate identical in-flight requests. Cache by URL + params + body hash. Clear on mutation.', 'in_review', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 3, 360, 300, NULL, '2026-04-07', 'Sprint 14', NULL, 'api', '2.1.0', 'feat/request-dedup', NULL, 4.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000055', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Fix CSS specificity issues', 'Global styles overriding component styles in production build. Migrate to CSS Modules or refactor selectors.', 'in_review', 'medium', 'bug', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000004', 3, 360, 300, '2026-04-15', '2026-04-08', 'Sprint 14', NULL, 'ui', '2.0.3', 'fix/css-specificity', NULL, 5.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000056', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Graceful shutdown handler', 'Ensure in-flight requests complete before process exit. Drain WebSocket connections and flush logs.', 'in_review', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 3, 240, 210, NULL, '2026-04-09', 'Sprint 14', 'production', 'platform', '2.1.0', 'feat/graceful-shutdown', NULL, 6.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000057', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Table virtualization for large datasets', 'Implement windowed rendering for tables with >1000 rows. Use @tanstack/virtual for row virtualization.', 'in_review', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000003', 5, 480, 420, NULL, '2026-04-05', 'Sprint 14', NULL, 'ui', '2.1.0', 'feat/table-virtual', NULL, 7.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000058', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Health check endpoint improvements', 'Add deep health checks: database connectivity, Redis ping, disk space, memory usage. Return structured JSON.', 'in_review', 'low', 'improvement', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000004', 2, 180, 180, NULL, '2026-04-10', 'Sprint 14', 'production', 'platform', '2.1.0', 'feat/deep-healthcheck', NULL, 8.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000059', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Implement cursor-based pagination', 'Replace offset pagination with cursor-based for all list endpoints. Support forward and backward navigation.', 'in_review', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 5, 480, 420, NULL, '2026-04-04', 'Sprint 14', NULL, 'api', '2.1.0', 'feat/cursor-pagination', NULL, 9.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000060', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'Fix flaky integration tests', 'Three tests randomly fail due to timing issues. Add proper wait conditions and test isolation.', 'in_review', 'high', 'bug', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 3, 360, 300, '2026-04-14', '2026-04-07', 'Sprint 14', NULL, 'testing', '2.0.3', 'fix/flaky-tests', NULL, 10.0, false, NULL, 'Alice');

-- Tickets: Done (10 tickets)
INSERT INTO tickets (id, board_id, column_id, title, description, status, priority, type, assignee_id, reporter_id, story_points, time_estimate_minutes, time_spent_minutes, due_date, start_date, sprint, environment, component, version, git_branch, external_url, position, is_blocked, blocked_reason, created_by) VALUES
  ('a3000000-0000-0000-0000-000000000061', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Add request logging middleware', 'Log all HTTP requests with method, path, status, duration. Mask sensitive headers (Authorization, Cookie).', 'done', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 3, 240, 200, '2026-04-10', '2026-04-03', 'Sprint 13', 'production', 'api', '2.0.2', 'feat/request-logging', NULL, 1.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000062', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Fix duplicate email notifications', 'Users receiving 2-3 copies of each email. Race condition in notification queue consumer.', 'done', 'high', 'bug', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000004', 3, 360, 420, '2026-04-08', '2026-04-03', 'Sprint 13', 'production', 'notifications', '2.0.2', 'fix/dupe-emails', NULL, 2.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000063', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Implement password strength meter', 'Show real-time password strength feedback using zxcvbn. Display entropy score and suggestions.', 'done', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000002', 3, 240, 180, '2026-04-09', '2026-04-04', 'Sprint 13', NULL, 'auth', '2.0.2', 'feat/pwd-strength', NULL, 3.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000064', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Docker image size reduction', 'Reduce production Docker image from 1.2GB to <200MB. Multi-stage build, Alpine base, prune dev deps.', 'done', 'low', 'improvement', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000003', 3, 360, 300, '2026-04-10', '2026-04-05', 'Sprint 13', NULL, 'build', '2.0.2', 'chore/slim-docker', NULL, 4.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000065', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Fix Safari date picker rendering', 'Date picker displays incorrectly in Safari 17. Input type=date fallback not working.', 'done', 'medium', 'bug', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 2, 120, 90, '2026-04-07', '2026-04-05', 'Sprint 13', NULL, 'ui', '2.0.2', 'fix/safari-datepicker', NULL, 5.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000066', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Add bulk delete API endpoint', 'Support deleting multiple resources in a single request. Accept array of IDs, return partial success results.', 'done', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 3, 240, 210, '2026-04-09', '2026-04-04', 'Sprint 13', NULL, 'api', '2.0.2', 'feat/bulk-delete', NULL, 6.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000067', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Set up Sentry error tracking', 'Integrate Sentry SDK, configure source maps, set up alert rules for error rate spikes.', 'done', 'high', 'task', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000004', 3, 240, 180, '2026-04-08', '2026-04-03', 'Sprint 13', 'production', 'observability', '2.0.2', 'chore/sentry', NULL, 7.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000068', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Optimize bundle size', 'Reduce JS bundle from 480KB to under 200KB. Tree-shake unused lodash, lazy-load routes, extract vendor chunk.', 'done', 'medium', 'improvement', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000002', 5, 480, 360, '2026-04-10', '2026-04-02', 'Sprint 13', NULL, 'build', '2.0.2', 'chore/bundle-size', NULL, 8.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000069', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Implement soft delete', 'Add deleted_at column to users and posts. Filter soft-deleted records at query level, add restore endpoint.', 'done', 'medium', 'feature', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 5, 480, 420, '2026-04-10', '2026-04-01', 'Sprint 13', NULL, 'database', '2.0.2', 'feat/soft-delete', NULL, 9.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000070', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'Unit test coverage for auth module', 'Increase auth module test coverage from 45% to 90%. Cover login, registration, password reset, and session management.', 'done', 'high', 'task', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000003', 5, 600, 540, '2026-04-10', '2026-04-01', 'Sprint 13', NULL, 'auth', '2.0.2', 'test/auth-coverage', NULL, 10.0, false, NULL, 'Charlie');

-- Tickets: Released (5 tickets)
INSERT INTO tickets (id, board_id, column_id, title, description, status, priority, type, assignee_id, reporter_id, story_points, time_estimate_minutes, time_spent_minutes, due_date, start_date, sprint, environment, component, version, git_branch, external_url, position, is_blocked, blocked_reason, created_by) VALUES
  ('a3000000-0000-0000-0000-000000000071', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000006', 'CORS configuration fix', 'API rejecting requests from new frontend domain after migration. Updated allowed origins list.', 'closed', 'critical', 'bug', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000004', 1, 60, 30, '2026-03-28', '2026-03-28', 'Sprint 12', 'production', 'api', '2.0.1', 'fix/cors-origins', NULL, 1.0, false, NULL, 'Diana'),
  ('a3000000-0000-0000-0000-000000000072', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000006', 'Add pagination to user list', 'User list page crashes with >500 users. Added server-side pagination with 25 per page default.', 'closed', 'high', 'bug', 'a1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002', 3, 240, 180, '2026-03-30', '2026-03-25', 'Sprint 12', 'production', 'ui', '2.0.1', 'fix/user-pagination', NULL, 2.0, false, NULL, 'Bob'),
  ('a3000000-0000-0000-0000-000000000073', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000006', 'Implement password reset flow', 'End-to-end password reset: request link, validate token, set new password, send confirmation email.', 'closed', 'high', 'feature', 'a1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', 5, 480, 360, '2026-03-31', '2026-03-20', 'Sprint 12', NULL, 'auth', '2.0.0', 'feat/pwd-reset', NULL, 3.0, false, NULL, 'Alice'),
  ('a3000000-0000-0000-0000-000000000074', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000006', 'Set up CI/CD pipeline', 'GitHub Actions pipeline: lint, type-check, test, build, deploy to staging. Manual promotion to prod.', 'closed', 'high', 'task', 'a1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000003', 5, 480, 420, '2026-03-28', '2026-03-18', 'Sprint 12', NULL, 'build', '2.0.0', 'chore/ci-cd', NULL, 4.0, false, NULL, 'Charlie'),
  ('a3000000-0000-0000-0000-000000000075', 'b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000006', 'Database backup automation', 'Automated daily pg_dump to S3 with 30-day retention. Tested restore procedure and documented runbook.', 'closed', 'medium', 'task', 'a1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000004', 3, 360, 300, '2026-03-31', '2026-03-22', 'Sprint 12', 'production', 'database', '2.0.0', 'chore/db-backups', NULL, 5.0, false, NULL, 'Diana');

-- Ticket Labels (assign 1-3 labels per ticket)
INSERT INTO ticket_labels (id, ticket_id, label_id) VALUES
  -- Backlog tickets
  ('a4000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000002', 'a3000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000003', 'a3000000-0000-0000-0000-000000000002', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000004', 'a3000000-0000-0000-0000-000000000003', 'a2000000-0000-0000-0000-000000000004'),
  ('a4000000-0000-0000-0000-000000000005', 'a3000000-0000-0000-0000-000000000004', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000006', 'a3000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000007', 'a3000000-0000-0000-0000-000000000005', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000008', 'a3000000-0000-0000-0000-000000000006', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000009', 'a3000000-0000-0000-0000-000000000006', 'a2000000-0000-0000-0000-000000000006'),
  ('a4000000-0000-0000-0000-000000000010', 'a3000000-0000-0000-0000-000000000007', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000011', 'a3000000-0000-0000-0000-000000000008', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000012', 'a3000000-0000-0000-0000-000000000008', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000013', 'a3000000-0000-0000-0000-000000000009', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000014', 'a3000000-0000-0000-0000-000000000009', 'a2000000-0000-0000-0000-000000000004'),
  ('a4000000-0000-0000-0000-000000000015', 'a3000000-0000-0000-0000-000000000010', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000016', 'a3000000-0000-0000-0000-000000000011', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000017', 'a3000000-0000-0000-0000-000000000012', 'a2000000-0000-0000-0000-000000000004'),
  ('a4000000-0000-0000-0000-000000000018', 'a3000000-0000-0000-0000-000000000013', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000019', 'a3000000-0000-0000-0000-000000000014', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000020', 'a3000000-0000-0000-0000-000000000014', 'a2000000-0000-0000-0000-000000000006'),
  ('a4000000-0000-0000-0000-000000000021', 'a3000000-0000-0000-0000-000000000015', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000022', 'a3000000-0000-0000-0000-000000000015', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000023', 'a3000000-0000-0000-0000-000000000016', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000024', 'a3000000-0000-0000-0000-000000000017', 'a2000000-0000-0000-0000-000000000005'),
  ('a4000000-0000-0000-0000-000000000025', 'a3000000-0000-0000-0000-000000000018', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000026', 'a3000000-0000-0000-0000-000000000019', 'a2000000-0000-0000-0000-000000000004'),
  ('a4000000-0000-0000-0000-000000000027', 'a3000000-0000-0000-0000-000000000020', 'a2000000-0000-0000-0000-000000000006'),
  -- To Do tickets
  ('a4000000-0000-0000-0000-000000000028', 'a3000000-0000-0000-0000-000000000021', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000029', 'a3000000-0000-0000-0000-000000000022', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000030', 'a3000000-0000-0000-0000-000000000023', 'a2000000-0000-0000-0000-000000000004'),
  ('a4000000-0000-0000-0000-000000000031', 'a3000000-0000-0000-0000-000000000024', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000032', 'a3000000-0000-0000-0000-000000000024', 'a2000000-0000-0000-0000-000000000006'),
  ('a4000000-0000-0000-0000-000000000033', 'a3000000-0000-0000-0000-000000000025', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000034', 'a3000000-0000-0000-0000-000000000026', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000035', 'a3000000-0000-0000-0000-000000000027', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000036', 'a3000000-0000-0000-0000-000000000028', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000037', 'a3000000-0000-0000-0000-000000000029', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000038', 'a3000000-0000-0000-0000-000000000029', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000039', 'a3000000-0000-0000-0000-000000000030', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000040', 'a3000000-0000-0000-0000-000000000031', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000041', 'a3000000-0000-0000-0000-000000000032', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000042', 'a3000000-0000-0000-0000-000000000032', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000043', 'a3000000-0000-0000-0000-000000000033', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000044', 'a3000000-0000-0000-0000-000000000034', 'a2000000-0000-0000-0000-000000000007'),
  ('a4000000-0000-0000-0000-000000000045', 'a3000000-0000-0000-0000-000000000035', 'a2000000-0000-0000-0000-000000000005'),
  -- In Progress tickets
  ('a4000000-0000-0000-0000-000000000046', 'a3000000-0000-0000-0000-000000000036', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000047', 'a3000000-0000-0000-0000-000000000037', 'a2000000-0000-0000-0000-000000000004'),
  ('a4000000-0000-0000-0000-000000000048', 'a3000000-0000-0000-0000-000000000038', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000049', 'a3000000-0000-0000-0000-000000000038', 'a2000000-0000-0000-0000-000000000006'),
  ('a4000000-0000-0000-0000-000000000050', 'a3000000-0000-0000-0000-000000000039', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000051', 'a3000000-0000-0000-0000-000000000040', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000052', 'a3000000-0000-0000-0000-000000000040', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000053', 'a3000000-0000-0000-0000-000000000041', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000054', 'a3000000-0000-0000-0000-000000000042', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000055', 'a3000000-0000-0000-0000-000000000043', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000056', 'a3000000-0000-0000-0000-000000000044', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000057', 'a3000000-0000-0000-0000-000000000044', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000058', 'a3000000-0000-0000-0000-000000000045', 'a2000000-0000-0000-0000-000000000007'),
  ('a4000000-0000-0000-0000-000000000059', 'a3000000-0000-0000-0000-000000000046', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000060', 'a3000000-0000-0000-0000-000000000046', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000061', 'a3000000-0000-0000-0000-000000000047', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000062', 'a3000000-0000-0000-0000-000000000047', 'a2000000-0000-0000-0000-000000000006'),
  ('a4000000-0000-0000-0000-000000000063', 'a3000000-0000-0000-0000-000000000048', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000064', 'a3000000-0000-0000-0000-000000000049', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000065', 'a3000000-0000-0000-0000-000000000050', 'a2000000-0000-0000-0000-000000000003'),
  -- In Review tickets
  ('a4000000-0000-0000-0000-000000000066', 'a3000000-0000-0000-0000-000000000051', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000067', 'a3000000-0000-0000-0000-000000000051', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000068', 'a3000000-0000-0000-0000-000000000052', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000069', 'a3000000-0000-0000-0000-000000000053', 'a2000000-0000-0000-0000-000000000005'),
  ('a4000000-0000-0000-0000-000000000070', 'a3000000-0000-0000-0000-000000000054', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000071', 'a3000000-0000-0000-0000-000000000055', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000072', 'a3000000-0000-0000-0000-000000000055', 'a2000000-0000-0000-0000-000000000006'),
  ('a4000000-0000-0000-0000-000000000073', 'a3000000-0000-0000-0000-000000000056', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000074', 'a3000000-0000-0000-0000-000000000057', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000075', 'a3000000-0000-0000-0000-000000000057', 'a2000000-0000-0000-0000-000000000006'),
  ('a4000000-0000-0000-0000-000000000076', 'a3000000-0000-0000-0000-000000000058', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000077', 'a3000000-0000-0000-0000-000000000059', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000078', 'a3000000-0000-0000-0000-000000000060', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000079', 'a3000000-0000-0000-0000-000000000060', 'a2000000-0000-0000-0000-000000000007'),
  -- Done tickets
  ('a4000000-0000-0000-0000-000000000080', 'a3000000-0000-0000-0000-000000000061', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000081', 'a3000000-0000-0000-0000-000000000062', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000082', 'a3000000-0000-0000-0000-000000000063', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000083', 'a3000000-0000-0000-0000-000000000063', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000084', 'a3000000-0000-0000-0000-000000000064', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000085', 'a3000000-0000-0000-0000-000000000065', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000086', 'a3000000-0000-0000-0000-000000000065', 'a2000000-0000-0000-0000-000000000006'),
  ('a4000000-0000-0000-0000-000000000087', 'a3000000-0000-0000-0000-000000000066', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000088', 'a3000000-0000-0000-0000-000000000067', 'a2000000-0000-0000-0000-000000000004'),
  ('a4000000-0000-0000-0000-000000000089', 'a3000000-0000-0000-0000-000000000068', 'a2000000-0000-0000-0000-000000000003'),
  ('a4000000-0000-0000-0000-000000000090', 'a3000000-0000-0000-0000-000000000069', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000091', 'a3000000-0000-0000-0000-000000000070', 'a2000000-0000-0000-0000-000000000007'),
  -- Released tickets
  ('a4000000-0000-0000-0000-000000000092', 'a3000000-0000-0000-0000-000000000071', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000093', 'a3000000-0000-0000-0000-000000000072', 'a2000000-0000-0000-0000-000000000001'),
  ('a4000000-0000-0000-0000-000000000094', 'a3000000-0000-0000-0000-000000000072', 'a2000000-0000-0000-0000-000000000006'),
  ('a4000000-0000-0000-0000-000000000095', 'a3000000-0000-0000-0000-000000000073', 'a2000000-0000-0000-0000-000000000002'),
  ('a4000000-0000-0000-0000-000000000096', 'a3000000-0000-0000-0000-000000000073', 'a2000000-0000-0000-0000-000000000008'),
  ('a4000000-0000-0000-0000-000000000097', 'a3000000-0000-0000-0000-000000000074', 'a2000000-0000-0000-0000-000000000004'),
  ('a4000000-0000-0000-0000-000000000098', 'a3000000-0000-0000-0000-000000000075', 'a2000000-0000-0000-0000-000000000004');

-- Comments
INSERT INTO comments (id, ticket_id, author_id, body, created_by, created_at) VALUES
  ('a5000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'I''ve evaluated passport.js vs custom OAuth implementation. Recommending passport for faster delivery.', 'Alice', '2026-04-02 10:30:00+00'),
  ('a5000000-0000-0000-0000-000000000002', 'a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000002', 'Make sure we handle the case where a user already has an account with the same email from a different provider.', 'Bob', '2026-04-02 11:15:00+00'),
  ('a5000000-0000-0000-0000-000000000003', 'a3000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000001', 'We got hit by a bot flood last week. This needs to be prioritized before the product launch.', 'Alice', '2026-04-05 09:00:00+00'),
  ('a5000000-0000-0000-0000-000000000004', 'a3000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000004', 'Should we also add CAPTCHA for unauthenticated endpoints?', 'Diana', '2026-04-05 09:30:00+00'),
  ('a5000000-0000-0000-0000-000000000005', 'a3000000-0000-0000-0000-000000000021', 'a1000000-0000-0000-0000-000000000002', 'Confirmed: the scheduler stores timestamps without timezone info. Need to migrate existing data too.', 'Bob', '2026-04-13 08:00:00+00'),
  ('a5000000-0000-0000-0000-000000000006', 'a3000000-0000-0000-0000-000000000021', 'a1000000-0000-0000-0000-000000000001', 'I''ll take this one. Going to add a migration script that converts all existing timestamps to UTC.', 'Alice', '2026-04-13 08:30:00+00'),
  ('a5000000-0000-0000-0000-000000000007', 'a3000000-0000-0000-0000-000000000025', 'a1000000-0000-0000-0000-000000000001', 'Found it! The charting library creates new event listeners on every re-render without cleanup. Classic leak.', 'Alice', '2026-04-13 14:00:00+00'),
  ('a5000000-0000-0000-0000-000000000008', 'a3000000-0000-0000-0000-000000000025', 'a1000000-0000-0000-0000-000000000003', 'Check if the WebSocket reconnection timer is also leaking. I noticed multiple reconnections in the network tab.', 'Charlie', '2026-04-13 14:30:00+00'),
  ('a5000000-0000-0000-0000-000000000009', 'a3000000-0000-0000-0000-000000000036', 'a1000000-0000-0000-0000-000000000001', 'WebSocket connection established. Working on the message format and delivery guarantees now.', 'Alice', '2026-04-08 16:00:00+00'),
  ('a5000000-0000-0000-0000-000000000010', 'a3000000-0000-0000-0000-000000000036', 'a1000000-0000-0000-0000-000000000004', 'Should we use a message queue for guaranteed delivery or is at-most-once okay for notifications?', 'Diana', '2026-04-09 09:00:00+00'),
  ('a5000000-0000-0000-0000-000000000011', 'a3000000-0000-0000-0000-000000000036', 'a1000000-0000-0000-0000-000000000001', 'Going with at-least-once via Redis Streams. Client will deduplicate based on message ID.', 'Alice', '2026-04-09 10:00:00+00'),
  ('a5000000-0000-0000-0000-000000000012', 'a3000000-0000-0000-0000-000000000040', 'a1000000-0000-0000-0000-000000000004', 'This is a P0. We had three oversold items last week. Customers are not happy.', 'Diana', '2026-04-10 08:00:00+00'),
  ('a5000000-0000-0000-0000-000000000013', 'a3000000-0000-0000-0000-000000000040', 'a1000000-0000-0000-0000-000000000001', 'Implementing SELECT ... FOR UPDATE with a short lock timeout. Should handle 99% of cases.', 'Alice', '2026-04-10 11:00:00+00'),
  ('a5000000-0000-0000-0000-000000000014', 'a3000000-0000-0000-0000-000000000040', 'a1000000-0000-0000-0000-000000000002', 'Consider using an advisory lock instead. Less contention and we can control the lock scope better.', 'Bob', '2026-04-10 13:00:00+00'),
  ('a5000000-0000-0000-0000-000000000015', 'a3000000-0000-0000-0000-000000000044', 'a1000000-0000-0000-0000-000000000001', 'SAML assertion parsing is done. Working on the SP metadata endpoint and IdP discovery.', 'Alice', '2026-04-07 15:00:00+00'),
  ('a5000000-0000-0000-0000-000000000016', 'a3000000-0000-0000-0000-000000000044', 'a1000000-0000-0000-0000-000000000003', 'Have you tested with Okta and Azure AD? Those are our two biggest enterprise customers.', 'Charlie', '2026-04-08 10:00:00+00'),
  ('a5000000-0000-0000-0000-000000000017', 'a3000000-0000-0000-0000-000000000044', 'a1000000-0000-0000-0000-000000000001', 'Tested with Okta. Azure AD is next. Found some quirks with Okta''s clock skew handling.', 'Alice', '2026-04-10 16:00:00+00'),
  ('a5000000-0000-0000-0000-000000000018', 'a3000000-0000-0000-0000-000000000046', 'a1000000-0000-0000-0000-000000000003', 'RLS policies are in place for all tables. Running the test suite now against multi-tenant data.', 'Charlie', '2026-04-08 14:00:00+00'),
  ('a5000000-0000-0000-0000-000000000019', 'a3000000-0000-0000-0000-000000000046', 'a1000000-0000-0000-0000-000000000001', 'Make sure to test cross-tenant queries via the API too, not just direct SQL. The middleware needs to set the tenant context.', 'Alice', '2026-04-09 09:00:00+00'),
  ('a5000000-0000-0000-0000-000000000020', 'a3000000-0000-0000-0000-000000000051', 'a1000000-0000-0000-0000-000000000002', 'LGTM on the implementation. One concern: the reuse detection window of 30 seconds might be too aggressive.', 'Bob', '2026-04-12 14:00:00+00'),
  ('a5000000-0000-0000-0000-000000000021', 'a3000000-0000-0000-0000-000000000051', 'a1000000-0000-0000-0000-000000000001', 'Good point. Increased to 60 seconds and added a grace period for slow network conditions.', 'Alice', '2026-04-12 15:00:00+00'),
  ('a5000000-0000-0000-0000-000000000022', 'a3000000-0000-0000-0000-000000000052', 'a1000000-0000-0000-0000-000000000003', 'The fix reduced query count from 102 to 3 for a 100-user list. Response time went from 2.1s to 45ms.', 'Charlie', '2026-04-11 16:00:00+00'),
  ('a5000000-0000-0000-0000-000000000023', 'a3000000-0000-0000-0000-000000000052', 'a1000000-0000-0000-0000-000000000002', 'Nice improvement! Can you add a test that fails if the query count exceeds a threshold?', 'Bob', '2026-04-12 09:00:00+00'),
  ('a5000000-0000-0000-0000-000000000024', 'a3000000-0000-0000-0000-000000000055', 'a1000000-0000-0000-0000-000000000004', 'The CSS Modules migration is complete. All component styles are now scoped. Zero visual regressions in screenshots.', 'Diana', '2026-04-11 11:00:00+00'),
  ('a5000000-0000-0000-0000-000000000025', 'a3000000-0000-0000-0000-000000000055', 'a1000000-0000-0000-0000-000000000001', 'Looks great! Can we also set up a lint rule to prevent future global style additions?', 'Alice', '2026-04-11 14:00:00+00'),
  ('a5000000-0000-0000-0000-000000000026', 'a3000000-0000-0000-0000-000000000060', 'a1000000-0000-0000-0000-000000000001', 'Root cause was shared test database state. Added proper teardown and isolated test databases.', 'Alice', '2026-04-11 10:00:00+00'),
  ('a5000000-0000-0000-0000-000000000027', 'a3000000-0000-0000-0000-000000000060', 'a1000000-0000-0000-0000-000000000002', 'Ran the suite 50 times in CI. Zero failures. Merging after one more review.', 'Bob', '2026-04-12 16:00:00+00'),
  ('a5000000-0000-0000-0000-000000000028', 'a3000000-0000-0000-0000-000000000062', 'a1000000-0000-0000-0000-000000000004', 'Users were getting 2-3 copies of every email since the last deploy. This was urgent.', 'Diana', '2026-04-03 11:00:00+00'),
  ('a5000000-0000-0000-0000-000000000029', 'a3000000-0000-0000-0000-000000000062', 'a1000000-0000-0000-0000-000000000002', 'Found the issue: consumer group rebalance was causing duplicate message processing. Added idempotency keys.', 'Bob', '2026-04-04 09:00:00+00'),
  ('a5000000-0000-0000-0000-000000000030', 'a3000000-0000-0000-0000-000000000067', 'a1000000-0000-0000-0000-000000000003', 'Sentry is live in production. Already caught 3 unhandled promise rejections we didn''t know about.', 'Charlie', '2026-04-06 10:00:00+00'),
  ('a5000000-0000-0000-0000-000000000031', 'a3000000-0000-0000-0000-000000000067', 'a1000000-0000-0000-0000-000000000004', 'Added alert rules: >10 errors/min triggers PagerDuty, >100 errors/min pages the on-call.', 'Diana', '2026-04-06 14:00:00+00'),
  ('a5000000-0000-0000-0000-000000000032', 'a3000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000003', 'Node 22 upgrade is scheduled for Sprint 16. This ticket should stay blocked until then.', 'Charlie', '2026-04-05 11:00:00+00'),
  ('a5000000-0000-0000-0000-000000000033', 'a3000000-0000-0000-0000-000000000029', 'a1000000-0000-0000-0000-000000000001', 'Found the bug: the retry count was being reset on each webhook attempt instead of persisting across retries.', 'Alice', '2026-04-13 11:00:00+00'),
  ('a5000000-0000-0000-0000-000000000034', 'a3000000-0000-0000-0000-000000000041', 'a1000000-0000-0000-0000-000000000003', 'DAU/MAU charts are done. Working on the conversion funnel visualization next.', 'Charlie', '2026-04-10 15:00:00+00'),
  ('a5000000-0000-0000-0000-000000000035', 'a3000000-0000-0000-0000-000000000041', 'a1000000-0000-0000-0000-000000000002', 'Can we add a date range picker? The default 30-day view is too limited for quarterly reviews.', 'Bob', '2026-04-11 09:00:00+00'),
  ('a5000000-0000-0000-0000-000000000036', 'a3000000-0000-0000-0000-000000000043', 'a1000000-0000-0000-0000-000000000004', 'Evaluated Flyway, Prisma Migrate, and golang-migrate. Going with golang-migrate for its simplicity.', 'Diana', '2026-04-08 11:00:00+00'),
  ('a5000000-0000-0000-0000-000000000037', 'a3000000-0000-0000-0000-000000000050', 'a1000000-0000-0000-0000-000000000004', 'Pino is configured with request ID correlation. Log output in production is now structured JSON.', 'Diana', '2026-04-10 14:00:00+00'),
  ('a5000000-0000-0000-0000-000000000038', 'a3000000-0000-0000-0000-000000000050', 'a1000000-0000-0000-0000-000000000001', 'Make sure the log level is configurable via environment variable. We want debug logs in staging but info in prod.', 'Alice', '2026-04-10 15:30:00+00'),
  ('a5000000-0000-0000-0000-000000000039', 'a3000000-0000-0000-0000-000000000035', 'a1000000-0000-0000-0000-000000000004', 'The API design doc is still pending review from the platform team. ETA is next Thursday.', 'Diana', '2026-04-11 10:00:00+00'),
  ('a5000000-0000-0000-0000-000000000040', 'a3000000-0000-0000-0000-000000000071', 'a1000000-0000-0000-0000-000000000001', 'Hotfix deployed. Root cause was the frontend domain change wasn''t added to the allowed origins.', 'Alice', '2026-03-28 16:00:00+00'),
  ('a5000000-0000-0000-0000-000000000041', 'a3000000-0000-0000-0000-000000000074', 'a1000000-0000-0000-0000-000000000003', 'Pipeline is green across all environments. Average build time is 8 minutes.', 'Charlie', '2026-03-27 15:00:00+00'),
  ('a5000000-0000-0000-0000-000000000042', 'a3000000-0000-0000-0000-000000000074', 'a1000000-0000-0000-0000-000000000004', 'Added manual approval gate for production deployments. Only team leads can approve.', 'Diana', '2026-03-28 09:00:00+00'),
  ('a5000000-0000-0000-0000-000000000043', 'a3000000-0000-0000-0000-000000000022', 'a1000000-0000-0000-0000-000000000003', 'Started on the Elasticsearch mapping. Do we want to index all product fields or just searchable ones?', 'Charlie', '2026-04-13 10:00:00+00'),
  ('a5000000-0000-0000-0000-000000000044', 'a3000000-0000-0000-0000-000000000022', 'a1000000-0000-0000-0000-000000000001', 'Index name, description, tags, and category. Skip internal fields like cost_price and supplier_id.', 'Alice', '2026-04-13 10:30:00+00'),
  ('a5000000-0000-0000-0000-000000000045', 'a3000000-0000-0000-0000-000000000039', 'a1000000-0000-0000-0000-000000000004', 'Batch endpoint is working. Currently supports GET and POST requests. Should we add PATCH/DELETE support?', 'Diana', '2026-04-10 16:00:00+00'),
  ('a5000000-0000-0000-0000-000000000046', 'a3000000-0000-0000-0000-000000000039', 'a1000000-0000-0000-0000-000000000001', 'Yes, all methods. Also need to handle the case where one request in the batch depends on another''s result.', 'Alice', '2026-04-11 09:00:00+00'),
  ('a5000000-0000-0000-0000-000000000047', 'a3000000-0000-0000-0000-000000000057', 'a1000000-0000-0000-0000-000000000003', 'Virtualization is working for up to 50k rows. Scroll performance is smooth at 60fps.', 'Charlie', '2026-04-11 13:00:00+00'),
  ('a5000000-0000-0000-0000-000000000048', 'a3000000-0000-0000-0000-000000000059', 'a1000000-0000-0000-0000-000000000001', 'All list endpoints now use cursor-based pagination. Backward compatibility with offset pagination is maintained via query param.', 'Alice', '2026-04-10 17:00:00+00'),
  ('a5000000-0000-0000-0000-000000000049', 'a3000000-0000-0000-0000-000000000059', 'a1000000-0000-0000-0000-000000000002', 'Good call on maintaining backward compatibility. We should deprecate offset pagination in v2.2.0.', 'Bob', '2026-04-11 08:00:00+00'),
  ('a5000000-0000-0000-0000-000000000050', 'a3000000-0000-0000-0000-000000000075', 'a1000000-0000-0000-0000-000000000001', 'Backup automation is live. Tested restore procedure successfully. Recovery time is under 15 minutes for the full database.', 'Alice', '2026-03-30 11:00:00+00');
