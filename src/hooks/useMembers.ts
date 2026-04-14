import { useState, useEffect } from "react";
import { fetchMembers } from "../api";
import { useAppStore } from "../store";
import type { Member } from "../types";

export function useMembers() {
  const { activeBoardId, clientName, activeMemberId, setActiveMemberId } =
    useAppStore();
  const [members, setMembers] = useState<Member[]>([]);

  useEffect(() => {
    fetchMembers().then(setMembers).catch((err) => console.error("Failed to load members:", err));
  }, []);

  const filtered = activeBoardId
    ? members.filter((m) => m.board_id === activeBoardId)
    : members;

  useEffect(() => {
    if (filtered.length > 0 && !activeMemberId) {
      const match = filtered.find((m) => m.name === clientName);
      setActiveMemberId(match?.id ?? filtered[0].id);
    }
  }, [filtered, activeMemberId, clientName, setActiveMemberId]);

  return { members: filtered };
}
