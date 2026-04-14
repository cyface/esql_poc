import { useMemo, useCallback } from "react";
import { useLiveQuery, eq } from "@tanstack/react-db";
import { v4 as uuidv4 } from "uuid";
import { ticketsCollection, queueTicketUpdate } from "../collections";
import { useAppStore } from "../store";
import type { Ticket } from "../types";

export function useTickets(ticketLabelMap?: Record<string, string[]>) {
  const {
    activeBoardId,
    activeMemberId,
    clientName,
    searchQuery,
    filterPriority,
    filterType,
    filterAssigneeId,
    filterLabelId,
  } = useAppStore();

  const { data, isLoading, isError } = useLiveQuery(
    (q) => {
      const base = q.from({ ticket: ticketsCollection });
      if (activeBoardId) {
        return base.where(({ ticket }) =>
          eq(ticket.board_id, activeBoardId)
        );
      }
      return base;
    },
    [activeBoardId]
  );

  const allTickets = useMemo(() => (data ?? []) as Ticket[], [data]);

  const filtered = useMemo(() =>
    allTickets.filter((t) => {
      if (filterPriority && t.priority !== filterPriority) return false;
      if (filterType && t.type !== filterType) return false;
      if (filterAssigneeId && t.assignee_id !== filterAssigneeId) return false;
      if (filterLabelId && ticketLabelMap) {
        const labelIds = ticketLabelMap[t.id] ?? [];
        if (!labelIds.includes(filterLabelId)) return false;
      }
      if (
        searchQuery &&
        !t.title.toLowerCase().includes(searchQuery.toLowerCase()) &&
        !t.description.toLowerCase().includes(searchQuery.toLowerCase())
      )
        return false;
      return true;
    }),
    [allTickets, filterPriority, filterType, filterAssigneeId, filterLabelId, ticketLabelMap, searchQuery]
  );

  const ticketsByColumn = useMemo(() => {
    const grouped: Record<string, Ticket[]> = {};
    for (const ticket of filtered) {
      const col = ticket.column_id;
      if (!grouped[col]) grouped[col] = [];
      grouped[col].push(ticket);
    }
    for (const col of Object.keys(grouped)) {
      grouped[col].sort((a, b) => a.position - b.position);
    }
    return grouped;
  }, [filtered]);

  const addTicket = useCallback((columnId: string, title: string, position: number) => {
    if (!activeBoardId) return;
    ticketsCollection.insert({
      id: uuidv4(),
      board_id: activeBoardId,
      column_id: columnId,
      title,
      description: "",
      status: "open",
      priority: "medium",
      type: "task",
      assignee_id: activeMemberId,
      reporter_id: activeMemberId,
      story_points: null,
      time_estimate_minutes: null,
      time_spent_minutes: 0,
      due_date: null,
      start_date: null,
      sprint: null,
      environment: null,
      component: null,
      version: null,
      git_branch: null,
      external_url: null,
      position,
      is_blocked: false,
      blocked_reason: null,
      created_by: clientName,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    } as Ticket);
  }, [activeBoardId, activeMemberId, clientName]);

  const updateTicket = useCallback((id: string, updates: Partial<Ticket>) => {
    const updated_at = new Date().toISOString();
    // Queue only the changed fields for the onUpdate handler
    queueTicketUpdate(id, { ...updates, updated_at });
    // Optimistic local update (triggers onUpdate which reads from the queue)
    ticketsCollection.update(id, (draft) => {
      const d = draft as Ticket;
      for (const [key, value] of Object.entries(updates)) {
        (d as Record<string, unknown>)[key] = value;
      }
      d.updated_at = updated_at;
    });
  }, []);

  const moveTicket = useCallback((
    id: string,
    newColumnId: string,
    newPosition: number
  ) => {
    const updated_at = new Date().toISOString();
    // Queue only the changed fields for the onUpdate handler
    queueTicketUpdate(id, { column_id: newColumnId, position: newPosition, updated_at });
    // Optimistic local update (triggers onUpdate which reads from the queue)
    ticketsCollection.update(id, (draft) => {
      const d = draft as Ticket;
      d.column_id = newColumnId;
      d.position = newPosition;
      d.updated_at = updated_at;
    });
  }, []);

  const removeTicket = useCallback((id: string) => {
    ticketsCollection.delete(id);
  }, []);

  return {
    tickets: filtered,
    allTickets,
    ticketsByColumn,
    isLoading,
    isError,
    addTicket,
    updateTicket,
    moveTicket,
    removeTicket,
  };
}
