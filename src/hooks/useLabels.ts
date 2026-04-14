import { useState, useEffect } from "react";
import { fetchLabels } from "../api";
import { useAppStore } from "../store";
import type { Label } from "../types";

export function useLabels() {
  const { activeBoardId } = useAppStore();
  const [labels, setLabels] = useState<Label[]>([]);

  useEffect(() => {
    fetchLabels().then(setLabels).catch((err) => console.error("Failed to load labels:", err));
  }, []);

  const filtered = activeBoardId
    ? labels.filter((l) => l.board_id === activeBoardId)
    : labels;

  return { labels: filtered };
}
