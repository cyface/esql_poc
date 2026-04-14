import { createCollection } from "@tanstack/react-db";
import { electricCollectionOptions } from "@tanstack/electric-db-collection";
import type {
  Ticket,
  TicketLabel,
  Comment,
} from "./types";
import * as api from "./api";

const ELECTRIC_URL =
  import.meta.env.VITE_ELECTRIC_URL ?? "http://localhost:3000";

// Pending partial updates for tickets — mutation functions store the changed
// fields here so the onUpdate handler sends only the diff (not the full 27-field
// object, which causes an Electric sync-back feedback loop).
const pendingTicketUpdates = new Map<string, Record<string, unknown>>();

export function queueTicketUpdate(id: string, changes: Record<string, unknown>) {
  pendingTicketUpdates.set(id, changes);
}

export const ticketsCollection = createCollection(
  electricCollectionOptions<Ticket>({
    id: "tickets",
    shapeOptions: {
      url: `${ELECTRIC_URL}/v1/shape`,
      params: { table: "tickets" },
    },
    getKey: (t) => t.id,
    onInsert: async ({ transaction }) => {
      const ticket = transaction.mutations[0].modified;
      await api.createTicket(ticket as Record<string, unknown>);
    },
    onUpdate: async ({ transaction }) => {
      const ticket = transaction.mutations[0].modified as Ticket;
      const changes = pendingTicketUpdates.get(ticket.id);
      pendingTicketUpdates.delete(ticket.id);
      if (changes) {
        await api.updateTicket(ticket.id, changes);
      }
    },
    onDelete: async ({ transaction }) => {
      const key = transaction.mutations[0].key;
      await api.deleteTicket(key as string);
    },
  })
);

export const ticketLabelsCollection = createCollection(
  electricCollectionOptions<TicketLabel>({
    id: "ticket_labels",
    shapeOptions: {
      url: `${ELECTRIC_URL}/v1/shape`,
      params: { table: "ticket_labels" },
    },
    getKey: (tl) => tl.id,
    onInsert: async ({ transaction }) => {
      const tl = transaction.mutations[0].modified;
      await api.createTicketLabel(tl as Record<string, unknown>);
    },
    onDelete: async ({ transaction }) => {
      const key = transaction.mutations[0].key;
      await api.deleteTicketLabel(key as string);
    },
  })
);

export const commentsCollection = createCollection(
  electricCollectionOptions<Comment>({
    id: "comments",
    shapeOptions: {
      url: `${ELECTRIC_URL}/v1/shape`,
      params: { table: "comments" },
    },
    getKey: (c) => c.id,
    onInsert: async ({ transaction }) => {
      const comment = transaction.mutations[0].modified;
      await api.createComment(comment as Record<string, unknown>);
    },
    onUpdate: async ({ transaction }) => {
      const comment = transaction.mutations[0].modified as Comment;
      await api.updateComment(comment.id, comment as Record<string, unknown>);
    },
    onDelete: async ({ transaction }) => {
      const key = transaction.mutations[0].key;
      await api.deleteComment(key as string);
    },
  })
);
