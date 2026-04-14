import { KanbanColumn } from "./KanbanColumn";
import type { Column, Ticket, Member, Label } from "../../types";

interface KanbanBoardProps {
  columns: Column[];
  ticketsByColumn: Record<string, Ticket[]>;
  members: Member[];
  labels: Label[];
  ticketLabelMap: Record<string, string[]>;
  onMoveTicket: (id: string, columnId: string, position: number) => void;
  onAddTicket: (columnId: string, title: string, position: number) => void;
  onSelectTicket: (id: string) => void;
}

export function KanbanBoard({
  columns,
  ticketsByColumn,
  members,
  labels,
  ticketLabelMap,
  onMoveTicket,
  onAddTicket,
  onSelectTicket,
}: KanbanBoardProps) {
  return (
    <div className="kanban-board">
      {columns.map((col) => (
        <KanbanColumn
          key={col.id}
          column={col}
          tickets={ticketsByColumn[col.id] ?? []}
          members={members}
          labels={labels}
          ticketLabelMap={ticketLabelMap}
          onMoveTicket={onMoveTicket}
          onAddTicket={onAddTicket}
          onSelectTicket={onSelectTicket}
        />
      ))}
    </div>
  );
}
