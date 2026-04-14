import { useState } from "react";
import { MemberAvatar } from "../Layout/MemberAvatar";
import type { Comment, Member } from "../../types";

interface TicketCommentsProps {
  comments: Comment[];
  members: Member[];
  onAdd: (body: string) => void;
  onRemove: (id: string) => void;
}

export function TicketComments({
  comments,
  members,
  onAdd,
  onRemove,
}: TicketCommentsProps) {
  const [body, setBody] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = body.trim();
    if (!trimmed) return;
    onAdd(trimmed);
    setBody("");
  };

  return (
    <div className="ticket-comments-section">
      <h4>Comments ({comments.length})</h4>

      <div className="comments-list">
        {comments.map((c) => {
          const author = members.find((m) => m.id === c.author_id);
          return (
            <div key={c.id} className="comment">
              <div className="comment-header">
                <MemberAvatar member={author} size={22} />
                <span className="comment-author">{c.created_by}</span>
                <span className="comment-time">
                  {new Date(c.created_at).toLocaleString()}
                </span>
                <button
                  className="comment-delete"
                  onClick={() => onRemove(c.id)}
                  title="Delete comment"
                >
                  &times;
                </button>
              </div>
              <p className="comment-body">{c.body}</p>
            </div>
          );
        })}
      </div>

      <form className="comment-form" onSubmit={handleSubmit}>
        <textarea
          placeholder="Add a comment..."
          value={body}
          onChange={(e) => setBody(e.target.value)}
          rows={2}
          onKeyDown={(e) => {
            if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
              handleSubmit(e);
            }
          }}
        />
        <button type="submit" disabled={!body.trim()}>
          Comment
        </button>
      </form>
    </div>
  );
}
