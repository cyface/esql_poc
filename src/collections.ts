import { createCollection } from "@tanstack/react-db";
import { electricCollectionOptions } from "@tanstack/electric-db-collection";
import type {
  Ticket,
  TicketLabel,
  Comment,
} from "./types";
import * as api from "./api";
import { notifyError } from "./notifications";

const ELECTRIC_URL =
  import.meta.env.VITE_ELECTRIC_URL ?? "http://localhost:3000";

// Pending partial updates for tickets — mutation functions store the changed
// fields here so the onUpdate handler sends only the diff (not the full 27-field
// object, which causes an Electric sync-back feedback loop).
// Uses Object.assign to merge rapid successive updates for the same ticket.
const pendingTicketUpdates = new Map<string, Record<string, unknown>>();

export function queueTicketUpdate(id: string, changes: Record<string, unknown>) {
  const existing = pendingTicketUpdates.get(id);
  if (existing) {
    Object.assign(existing, changes);
  } else {
    pendingTicketUpdates.set(id, { ...changes });
  }
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
      try {
        const ticket = transaction.mutations[0].modified;
        await api.createTicket(ticket as Record<string, unknown>);
      } catch (err) {
        console.error("Failed to create ticket:", err);
        notifyError("Failed to create ticket. Your change will be reverted.");
        throw err;
      }
    },
    onUpdate: async ({ transaction }) => {
      const ticket = transaction.mutations[0].modified as Ticket;
      const changes = pendingTicketUpdates.get(ticket.id);
      pendingTicketUpdates.delete(ticket.id);
      if (!changes) return;
      try {
        await api.updateTicket(ticket.id, changes);
      } catch (err) {
        console.error("Failed to update ticket:", err);
        notifyError("Failed to save ticket changes. Your edit will be reverted.");
        throw err;
      }
    },
    onDelete: async ({ transaction }) => {
      try {
        const key = transaction.mutations[0].key;
        await api.deleteTicket(key as string);
      } catch (err) {
        console.error("Failed to delete ticket:", err);
        notifyError("Failed to delete ticket. It will reappear.");
        throw err;
      }
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
      try {
        const tl = transaction.mutations[0].modified;
        await api.createTicketLabel(tl as Record<string, unknown>);
      } catch (err) {
        console.error("Failed to add label:", err);
        notifyError("Failed to add label.");
        throw err;
      }
    },
    onDelete: async ({ transaction }) => {
      try {
        const key = transaction.mutations[0].key;
        await api.deleteTicketLabel(key as string);
      } catch (err) {
        console.error("Failed to remove label:", err);
        notifyError("Failed to remove label.");
        throw err;
      }
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
      try {
        const comment = transaction.mutations[0].modified;
        await api.createComment(comment as Record<string, unknown>);
      } catch (err) {
        console.error("Failed to post comment:", err);
        notifyError("Failed to post comment.");
        throw err;
      }
    },
    // Comment editing not currently used
    onUpdate: async () => {},
    onDelete: async ({ transaction }) => {
      try {
        const key = transaction.mutations[0].key;
        await api.deleteComment(key as string);
      } catch (err) {
        console.error("Failed to delete comment:", err);
        notifyError("Failed to delete comment.");
        throw err;
      }
    },
  })
);
