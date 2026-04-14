import { useMemo, useCallback } from "react";
import { useLiveQuery, eq } from "@tanstack/react-db";
import { v4 as uuidv4 } from "uuid";
import { commentsCollection } from "../collections";
import { useAppStore } from "../store";
import type { Comment } from "../types";

export function useComments(ticketId: string | null) {
  const { activeMemberId, clientName } = useAppStore();

  const { data } = useLiveQuery(
    (q) => {
      const base = q.from({ comment: commentsCollection });
      if (ticketId) {
        return base.where(({ comment }) =>
          eq(comment.ticket_id, ticketId)
        );
      }
      return base;
    },
    [ticketId]
  );

  const comments = useMemo(
    () =>
      ((data ?? []) as Comment[]).sort(
        (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
      ),
    [data]
  );

  const addComment = useCallback(
    (body: string) => {
      if (!ticketId) return;
      commentsCollection.insert({
        id: uuidv4(),
        ticket_id: ticketId,
        author_id: activeMemberId,
        body,
        created_by: clientName,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      } as Comment);
    },
    [ticketId, activeMemberId, clientName]
  );

  const removeComment = useCallback((id: string) => {
    commentsCollection.delete(id);
  }, []);

  return { comments, addComment, removeComment };
}
