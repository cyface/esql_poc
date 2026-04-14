import { MemberAvatar } from "../Layout/MemberAvatar";
import { PRIORITY_COLORS, TYPE_ICONS } from "../../constants";
import type { Ticket, Member, Label } from "../../types";

interface TicketCardProps {
  ticket: Ticket;
  members: Member[];
  labels: Label[];
  ticketLabelIds: string[];
  onSelect: (id: string) => void;
}

export function TicketCard({
  ticket,
  members,
  labels,
  ticketLabelIds,
  onSelect,
}: TicketCardProps) {
  const assignee = members.find((m) => m.id === ticket.assignee_id);
  const ticketLabels = labels.filter((l) => ticketLabelIds.includes(l.id));
  const isOverdue =
    ticket.due_date && new Date(ticket.due_date) < new Date() && ticket.status !== "done" && ticket.status !== "closed";

  return (
    <div
      className="ticket-card"
      draggable
      onDragStart={(e) => {
        e.dataTransfer.setData("text/plain", ticket.id);
        e.dataTransfer.effectAllowed = "move";
      }}
      onClick={() => onSelect(ticket.id)}
      style={{ borderLeftColor: PRIORITY_COLORS[ticket.priority] ?? "#9ca3af" }}
    >
      <div className="ticket-header">
        <span className="ticket-type" title={ticket.type}>
          {TYPE_ICONS[ticket.type] ?? "?"}
        </span>
        <span className="ticket-title">{ticket.title}</span>
      </div>

      {ticketLabels.length > 0 && (
        <div className="ticket-labels">
          {ticketLabels.map((l) => (
            <span
              key={l.id}
              className="label-chip"
              style={{ backgroundColor: l.color }}
            >
              {l.name}
            </span>
          ))}
        </div>
      )}

      <div className="ticket-footer">
        <div className="ticket-meta">
          <span
            className="priority-badge"
            style={{ color: PRIORITY_COLORS[ticket.priority] }}
          >
            {ticket.priority}
          </span>
          {ticket.story_points != null && (
            <span className="story-points">{ticket.story_points}pt</span>
          )}
          {isOverdue && <span className="overdue-badge">Overdue</span>}
          {ticket.is_blocked && <span className="blocked-badge">Blocked</span>}
        </div>
        <MemberAvatar member={assignee} size={24} />
      </div>
    </div>
  );
}
