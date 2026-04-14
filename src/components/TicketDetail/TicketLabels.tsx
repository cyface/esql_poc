import type { Label } from "../../types";

interface TicketLabelsProps {
  ticketId: string;
  allLabels: Label[];
  activeIds: string[];
  onAdd: (ticketId: string, labelId: string) => void;
  onRemove: (ticketId: string, labelId: string) => void;
}

export function TicketLabels({
  ticketId,
  allLabels,
  activeIds,
  onAdd,
  onRemove,
}: TicketLabelsProps) {
  const activeLabels = allLabels.filter((l) => activeIds.includes(l.id));
  const inactiveLabels = allLabels.filter((l) => !activeIds.includes(l.id));

  return (
    <div className="ticket-labels-section">
      <h4>Labels</h4>
      <div className="active-labels">
        {activeLabels.map((l) => (
          <span
            key={l.id}
            className="label-chip removable"
            style={{ backgroundColor: l.color }}
            onClick={() => onRemove(ticketId, l.id)}
            title="Click to remove"
          >
            {l.name} &times;
          </span>
        ))}
      </div>
      {inactiveLabels.length > 0 && (
        <div className="available-labels">
          {inactiveLabels.map((l) => (
            <span
              key={l.id}
              className="label-chip inactive"
              style={{ borderColor: l.color, color: l.color }}
              onClick={() => onAdd(ticketId, l.id)}
              title="Click to add"
            >
              + {l.name}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
