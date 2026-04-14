import { useState } from "react";
import { MemberAvatar } from "../Layout/MemberAvatar";
import { PRIORITIES, TYPES, STATUSES } from "../../constants";
import type { Ticket, Member } from "../../types";

interface InlineEditProps {
  value: string;
  onSave: (val: string) => void;
  type?: "text" | "number" | "date" | "textarea";
}

function InlineEdit({ value, onSave, type = "text" }: InlineEditProps) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(value);

  if (!editing) {
    return (
      <span
        className="inline-edit-value"
        onClick={() => {
          setDraft(value);
          setEditing(true);
        }}
      >
        {value || "\u2014"}
      </span>
    );
  }

  const commit = () => {
    setEditing(false);
    if (draft !== value) onSave(draft);
  };

  if (type === "textarea") {
    return (
      <textarea
        className="inline-edit-input"
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onBlur={commit}
        onKeyDown={(e) => {
          if (e.key === "Escape") setEditing(false);
        }}
        autoFocus
        rows={3}
      />
    );
  }

  return (
    <input
      className="inline-edit-input"
      type={type}
      value={draft}
      onChange={(e) => setDraft(e.target.value)}
      onBlur={commit}
      onKeyDown={(e) => {
        if (e.key === "Enter") commit();
        if (e.key === "Escape") setEditing(false);
      }}
      autoFocus
    />
  );
}

interface TicketFieldsProps {
  ticket: Ticket;
  members: Member[];
  onUpdate: (id: string, updates: Partial<Ticket>) => void;
}

export function TicketFields({
  ticket,
  members,
  onUpdate,
}: TicketFieldsProps) {
  const assignee = members.find((m) => m.id === ticket.assignee_id);
  const reporter = members.find((m) => m.id === ticket.reporter_id);

  const update = (field: string, value: unknown) => {
    onUpdate(ticket.id, { [field]: value });
  };

  return (
    <div className="ticket-fields">
      <div className="field-group">
        <label>Status</label>
        <select
          value={ticket.status}
          onChange={(e) => update("status", e.target.value)}
        >
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s.replace("_", " ")}
            </option>
          ))}
        </select>
      </div>

      <div className="field-group">
        <label>Priority</label>
        <select
          value={ticket.priority}
          onChange={(e) => update("priority", e.target.value)}
        >
          {PRIORITIES.map((p) => (
            <option key={p} value={p}>
              {p}
            </option>
          ))}
        </select>
      </div>

      <div className="field-group">
        <label>Type</label>
        <select
          value={ticket.type}
          onChange={(e) => update("type", e.target.value)}
        >
          {TYPES.map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </select>
      </div>

      <div className="field-group">
        <label>Assignee</label>
        <div className="field-with-avatar">
          <MemberAvatar member={assignee} size={20} />
          <select
            value={ticket.assignee_id ?? ""}
            onChange={(e) => update("assignee_id", e.target.value || null)}
          >
            <option value="">Unassigned</option>
            {members.map((m) => (
              <option key={m.id} value={m.id}>
                {m.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="field-group">
        <label>Reporter</label>
        <div className="field-with-avatar">
          <MemberAvatar member={reporter} size={20} />
          <select
            value={ticket.reporter_id ?? ""}
            onChange={(e) => update("reporter_id", e.target.value || null)}
          >
            <option value="">None</option>
            {members.map((m) => (
              <option key={m.id} value={m.id}>
                {m.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="field-group">
        <label>Story Points</label>
        <InlineEdit
          value={ticket.story_points?.toString() ?? ""}
          type="number"
          onSave={(v) => update("story_points", v ? parseInt(v) : null)}
        />
      </div>

      <div className="field-group">
        <label>Estimate (min)</label>
        <InlineEdit
          value={ticket.time_estimate_minutes?.toString() ?? ""}
          type="number"
          onSave={(v) => update("time_estimate_minutes", v ? parseInt(v) : null)}
        />
      </div>

      <div className="field-group">
        <label>Time Spent (min)</label>
        <InlineEdit
          value={ticket.time_spent_minutes?.toString() ?? ""}
          type="number"
          onSave={(v) => update("time_spent_minutes", v ? parseInt(v) : 0)}
        />
      </div>

      <div className="field-group">
        <label>Due Date</label>
        <InlineEdit
          value={ticket.due_date ?? ""}
          type="date"
          onSave={(v) => update("due_date", v || null)}
        />
      </div>

      <div className="field-group">
        <label>Start Date</label>
        <InlineEdit
          value={ticket.start_date ?? ""}
          type="date"
          onSave={(v) => update("start_date", v || null)}
        />
      </div>

      <div className="field-group">
        <label>Sprint</label>
        <InlineEdit
          value={ticket.sprint ?? ""}
          onSave={(v) => update("sprint", v || null)}
        />
      </div>

      <div className="field-group">
        <label>Environment</label>
        <InlineEdit
          value={ticket.environment ?? ""}
          onSave={(v) => update("environment", v || null)}
        />
      </div>

      <div className="field-group">
        <label>Component</label>
        <InlineEdit
          value={ticket.component ?? ""}
          onSave={(v) => update("component", v || null)}
        />
      </div>

      <div className="field-group">
        <label>Version</label>
        <InlineEdit
          value={ticket.version ?? ""}
          onSave={(v) => update("version", v || null)}
        />
      </div>

      <div className="field-group">
        <label>Git Branch</label>
        <InlineEdit
          value={ticket.git_branch ?? ""}
          onSave={(v) => update("git_branch", v || null)}
        />
      </div>

      <div className="field-group">
        <label>External URL</label>
        <InlineEdit
          value={ticket.external_url ?? ""}
          onSave={(v) => update("external_url", v || null)}
        />
      </div>

      <div className="field-group">
        <label>Blocked</label>
        <div className="blocked-field">
          <input
            type="checkbox"
            checked={ticket.is_blocked}
            onChange={(e) => update("is_blocked", e.target.checked)}
          />
          {ticket.is_blocked && (
            <InlineEdit
              value={ticket.blocked_reason ?? ""}
              onSave={(v) => update("blocked_reason", v || null)}
            />
          )}
        </div>
      </div>

      <div className="field-group field-meta">
        <span>Created by {ticket.created_by}</span>
        <span>{new Date(ticket.created_at).toLocaleDateString()}</span>
      </div>
    </div>
  );
}
