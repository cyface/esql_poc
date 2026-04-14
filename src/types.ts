export interface Board {
  [key: string]: unknown;
  id: string;
  name: string;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export interface Member {
  [key: string]: unknown;
  id: string;
  board_id: string;
  name: string;
  avatar_url: string | null;
  color: string;
  role: string;
  created_at: string;
}

export interface Column {
  [key: string]: unknown;
  id: string;
  board_id: string;
  name: string;
  color: string | null;
  position: number;
  wip_limit: number | null;
  created_at: string;
}

export interface Label {
  [key: string]: unknown;
  id: string;
  board_id: string;
  name: string;
  color: string;
}

export interface Ticket {
  [key: string]: unknown;
  id: string;
  board_id: string;
  column_id: string;
  title: string;
  description: string;
  status: string;
  priority: string;
  type: string;
  assignee_id: string | null;
  reporter_id: string | null;
  story_points: number | null;
  time_estimate_minutes: number | null;
  time_spent_minutes: number;
  due_date: string | null;
  start_date: string | null;
  sprint: string | null;
  environment: string | null;
  component: string | null;
  version: string | null;
  git_branch: string | null;
  external_url: string | null;
  position: number;
  is_blocked: boolean;
  blocked_reason: string | null;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface TicketLabel {
  [key: string]: unknown;
  id: string;
  ticket_id: string;
  label_id: string;
}

export interface Comment {
  [key: string]: unknown;
  id: string;
  ticket_id: string;
  author_id: string | null;
  body: string;
  created_by: string;
  created_at: string;
  updated_at: string;
}
