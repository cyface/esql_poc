import { useLiveQuery } from "@tanstack/react-db";
import { TicketFields } from "./TicketFields";
import { TicketLabels } from "./TicketLabels";
import { TicketComments } from "./TicketComments";
import { useComments } from "../../hooks/useComments";
import { useTicketLabels } from "../../hooks/useTicketLabels";
import { useLabels } from "../../hooks/useLabels";
import { ticketsCollection } from "../../collections";
import type { Ticket, Member } from "../../types";

interface TicketDetailPanelProps {
  ticketId: string;
  members: Member[];
  onClose: () => void;
  onUpdate: (id: string, updates: Partial<Ticket>) => void;
  onDelete: (id: string) => void;
}

export function TicketDetailPanel({
  ticketId,
  members,
  onClose,
  onUpdate,
  onDelete,
}: TicketDetailPanelProps) {
  // Subscribe to entire collection for reliable reactivity
  const { data } = useLiveQuery(ticketsCollection);
  const ticket = ((data ?? []) as Ticket[]).find((t) => t.id === ticketId);
  const { comments, addComment, removeComment } = useComments(ticketId);
  const { labelsForTicket, addLabel, removeLabel } = useTicketLabels();
  const { labels } = useLabels();
  const activeIds = labelsForTicket(ticketId).map((tl) => tl.label_id);

  if (!ticket) return null;

  return (
    <div className="ticket-detail-overlay" onClick={onClose}>
      <div className="ticket-detail-panel" onClick={(e) => e.stopPropagation()}>
        <div className="panel-header">
          <div className="panel-title-area">
            <input
              className="panel-title-input"
              value={ticket.title}
              onChange={(e) => onUpdate(ticket.id, { title: e.target.value })}
            />
          </div>
          <div className="panel-actions">
            <button
              className="delete-ticket-btn"
              onClick={() => {
                onDelete(ticket.id);
                onClose();
              }}
            >
              Delete
            </button>
            <button className="close-panel-btn" onClick={onClose}>
              &times;
            </button>
          </div>
        </div>

        <div className="panel-body">
          <div className="panel-main">
            <div className="description-section">
              <h4>Description</h4>
              <textarea
                className="description-textarea"
                value={ticket.description}
                onChange={(e) =>
                  onUpdate(ticket.id, { description: e.target.value })
                }
                placeholder="Add a description..."
                rows={4}
              />
            </div>

            <TicketLabels
              ticketId={ticket.id}
              allLabels={labels}
              activeIds={activeIds}
              onAdd={addLabel}
              onRemove={removeLabel}
            />

            <TicketComments
              comments={comments}
              members={members}
              onAdd={addComment}
              onRemove={removeComment}
            />
          </div>

          <div className="panel-sidebar">
            <TicketFields
              ticket={ticket}
              members={members}
              onUpdate={onUpdate}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
