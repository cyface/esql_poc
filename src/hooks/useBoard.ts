import { useState, useEffect } from "react";
import { fetchBoards } from "../api";
import { useAppStore } from "../store";
import type { Board } from "../types";

export function useBoard() {
  const { activeBoardId, setActiveBoardId } = useAppStore();
  const [boards, setBoards] = useState<Board[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isError, setIsError] = useState(false);

  useEffect(() => {
    fetchBoards()
      .then((data) => {
        setBoards(data);
        setIsLoading(false);
      })
      .catch(() => {
        setIsError(true);
        setIsLoading(false);
      });
  }, []);

  const board = boards.find((b) => b.id === activeBoardId) ?? boards[0] ?? null;

  useEffect(() => {
    if (board && !activeBoardId) {
      setActiveBoardId(board.id);
    }
  }, [board, activeBoardId, setActiveBoardId]);

  return { board, isLoading, isError };
}
