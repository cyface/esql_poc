export const PRIORITIES = ["critical", "high", "medium", "low", "none"] as const;
export const TYPES = ["bug", "feature", "task", "improvement", "epic", "story"] as const;
export const STATUSES = ["open", "in_progress", "in_review", "done", "closed"] as const;

export const PRIORITY_COLORS: Record<string, string> = {
  critical: "#ef4444",
  high: "#f59e0b",
  medium: "#3b82f6",
  low: "#10b981",
  none: "#9ca3af",
};

export const TYPE_ICONS: Record<string, string> = {
  bug: "\u25CF",
  feature: "\u2605",
  task: "\u2713",
  improvement: "\u2191",
  epic: "\u26A1",
  story: "\u25A0",
};
