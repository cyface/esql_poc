import { useState, useEffect } from "react";
import { fetchColumns } from "../api";
import { useAppStore } from "../store";
import type { Column } from "../types";

export function useColumns() {
  const { activeBoardId } = useAppStore();
  const [columns, setColumns] = useState<Column[]>([]);
  const [isError, setIsError] = useState(false);

  useEffect(() => {
    fetchColumns()
      .then(setColumns)
      .catch((err) => {
        console.error("Failed to load columns:", err);
        setIsError(true);
      });
  }, []);

  const filtered = activeBoardId
    ? columns.filter((c) => c.board_id === activeBoardId)
    : columns;

  return { columns: filtered, isError };
}
