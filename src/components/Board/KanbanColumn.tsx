import { useState, useCallback, useRef } from "react";
import { TicketCard } from "./TicketCard";
import { NewTicketForm } from "./NewTicketForm";
import type { Column, Ticket, Member, Label } from "../../types";

function getDropIndex(
  e: React.DragEvent,
  containerRef: React.RefObject<HTMLDivElement | null>
): number {
  const container = containerRef.current;
  if (!container) return -1;

  const cards = container.querySelectorAll(".ticket-card");
  const mouseY = e.clientY;

  for (let i = 0; i < cards.length; i++) {
    const rect = cards[i].getBoundingClientRect();
    const midY = rect.top + rect.height / 2;
    if (mouseY < midY) return i;
  }
  return cards.length;
}

function calcPosition(tickets: Ticket[], dropIndex: number, draggedId: string): number {
  // Filter out the dragged ticket to get clean positions
  const others = tickets.filter((t) => t.id !== draggedId);

  if (others.length === 0) return 1.0;
  if (dropIndex <= 0) return others[0].position - 1.0;
  if (dropIndex >= others.length) return others[others.length - 1].position + 1.0;

  return (others[dropIndex - 1].position + others[dropIndex].position) / 2;
}

interface KanbanColumnProps {
  column: Column;
  tickets: Ticket[];
  members: Member[];
  labels: Label[];
  ticketLabelMap: Record<string, string[]>;
  onMoveTicket: (id: string, columnId: string, position: number) => void;
  onAddTicket: (columnId: string, title: string, position: number) => void;
  onSelectTicket: (id: string) => void;
}

export function KanbanColumn({
  column,
  tickets,
  members,
  labels,
  ticketLabelMap,
  onMoveTicket,
  onAddTicket,
  onSelectTicket,
}: KanbanColumnProps) {
  const ticketsRef = useRef<HTMLDivElement | null>(null);
  const [dropIndex, setDropIndex] = useState<number | null>(null);

  const handleDragOver = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = "move";
      const idx = getDropIndex(e, ticketsRef);
      setDropIndex(idx);
    },
    []
  );

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    // Only clear if leaving the column entirely, not moving between children
    const related = e.relatedTarget as Node | null;
    if (!e.currentTarget.contains(related)) {
      setDropIndex(null);
    }
  }, []);

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setDropIndex(null);

      const ticketId = e.dataTransfer.getData("text/plain");
      if (!ticketId) return;

      const idx = getDropIndex(e, ticketsRef);
      const position = calcPosition(tickets, idx, ticketId);
      onMoveTicket(ticketId, column.id, position);
    },
    [column.id, tickets, onMoveTicket]
  );

  const handleAddTicket = (title: string) => {
    const position =
      tickets.length > 0
        ? tickets[tickets.length - 1].position + 1.0
        : 1.0;
    onAddTicket(column.id, title, position);
  };

  const isOverWip =
    column.wip_limit != null && tickets.length > column.wip_limit;

  return (
    <div
      className={`kanban-column ${isOverWip ? "over-wip" : ""}`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      <div
        className="column-header"
        style={{ borderTopColor: column.color ?? "#6b7280" }}
      >
        <div className="column-title">
          <span className="column-name">{column.name}</span>
          <span className="column-count">{tickets.length}</span>
          {column.wip_limit != null && (
            <span className={`wip-limit ${isOverWip ? "exceeded" : ""}`}>
              / {column.wip_limit}
            </span>
          )}
        </div>
      </div>

      <div className="column-tickets" ref={ticketsRef}>
        {tickets.map((ticket, i) => (
          <div key={ticket.id}>
            {dropIndex === i && (
              <div className="drop-indicator" />
            )}
            <TicketCard
              ticket={ticket}
              members={members}
              labels={labels}
              ticketLabelIds={ticketLabelMap[ticket.id] ?? []}
              onSelect={onSelectTicket}
            />
          </div>
        ))}
        {dropIndex === tickets.length && (
          <div className="drop-indicator" />
        )}
      </div>

      <NewTicketForm onAdd={handleAddTicket} />
    </div>
  );
}
