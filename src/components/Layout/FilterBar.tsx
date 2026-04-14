import { useAppStore } from "../../store";
import { PRIORITIES, TYPES } from "../../constants";
import type { Member, Label } from "../../types";

interface FilterBarProps {
  members: Member[];
  labels: Label[];
  totalCount: number;
}

export function FilterBar({ members, labels, totalCount }: FilterBarProps) {
  const {
    filterPriority,
    setFilterPriority,
    filterType,
    setFilterType,
    filterAssigneeId,
    setFilterAssigneeId,
    filterLabelId,
    setFilterLabelId,
  } = useAppStore();

  const hasFilters =
    filterPriority || filterType || filterAssigneeId || filterLabelId;

  return (
    <div className="filter-bar">
      <div className="filter-controls">
        <select
          value={filterPriority ?? ""}
          onChange={(e) => setFilterPriority(e.target.value || null)}
        >
          <option value="">All priorities</option>
          {PRIORITIES.map((p) => (
            <option key={p} value={p}>
              {p.charAt(0).toUpperCase() + p.slice(1)}
            </option>
          ))}
        </select>

        <select
          value={filterType ?? ""}
          onChange={(e) => setFilterType(e.target.value || null)}
        >
          <option value="">All types</option>
          {TYPES.map((t) => (
            <option key={t} value={t}>
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </option>
          ))}
        </select>

        <select
          value={filterAssigneeId ?? ""}
          onChange={(e) => setFilterAssigneeId(e.target.value || null)}
        >
          <option value="">All assignees</option>
          {members.map((m) => (
            <option key={m.id} value={m.id}>
              {m.name}
            </option>
          ))}
        </select>

        <select
          value={filterLabelId ?? ""}
          onChange={(e) => setFilterLabelId(e.target.value || null)}
        >
          <option value="">All labels</option>
          {labels.map((l) => (
            <option key={l.id} value={l.id}>
              {l.name}
            </option>
          ))}
        </select>

        {hasFilters && (
          <button
            className="clear-filters-btn"
            onClick={() => {
              setFilterPriority(null);
              setFilterType(null);
              setFilterAssigneeId(null);
              setFilterLabelId(null);
            }}
          >
            Clear filters
          </button>
        )}
      </div>
      <span className="ticket-count">{totalCount} tickets</span>
    </div>
  );
}
