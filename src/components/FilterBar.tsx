import { useAppStore } from "../store";

interface FilterBarProps {
  totalCount: number;
  activeCount: number;
  onClearAll: () => void;
}

export function FilterBar({ totalCount, activeCount, onClearAll }: FilterBarProps) {
  const { filter, setFilter } = useAppStore();

  const filters = ["all", "active", "completed"] as const;

  return (
    <div className="filter-bar">
      <span className="count">
        {activeCount} of {totalCount} remaining
      </span>
      <div className="filters">
        {filters.map((f) => (
          <button
            key={f}
            className={filter === f ? "active" : ""}
            onClick={() => setFilter(f)}
          >
            {f}
          </button>
        ))}
      </div>
      {totalCount > 0 && (
        <button className="clear" onClick={onClearAll}>
          Clear all
        </button>
      )}
    </div>
  );
}
