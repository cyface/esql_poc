import { useMemo, useCallback } from "react";
import { useLiveQuery } from "@tanstack/react-db";
import { v4 as uuidv4 } from "uuid";
import { ticketLabelsCollection } from "../collections";
import type { TicketLabel } from "../types";

export function useTicketLabels() {
  const { data } = useLiveQuery(ticketLabelsCollection);

  const ticketLabels = useMemo(() => (data ?? []) as TicketLabel[], [data]);

  const labelsForTicket = useCallback(
    (ticketId: string) => ticketLabels.filter((tl) => tl.ticket_id === ticketId),
    [ticketLabels]
  );

  const addLabel = useCallback(
    (ticketId: string, labelId: string) => {
      const exists = ticketLabels.some(
        (tl) => tl.ticket_id === ticketId && tl.label_id === labelId
      );
      if (exists) return;
      ticketLabelsCollection.insert({
        id: uuidv4(),
        ticket_id: ticketId,
        label_id: labelId,
      } as TicketLabel);
    },
    [ticketLabels]
  );

  const removeLabel = useCallback(
    (ticketId: string, labelId: string) => {
      const entry = ticketLabels.find(
        (tl) => tl.ticket_id === ticketId && tl.label_id === labelId
      );
      if (entry) {
        ticketLabelsCollection.delete(entry.id);
      }
    },
    [ticketLabels]
  );

  return { ticketLabels, labelsForTicket, addLabel, removeLabel };
}
