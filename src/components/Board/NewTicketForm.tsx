import { useState } from "react";

interface NewTicketFormProps {
  onAdd: (title: string) => void;
}

export function NewTicketForm({ onAdd }: NewTicketFormProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [title, setTitle] = useState("");

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = title.trim();
    if (!trimmed) return;
    onAdd(trimmed);
    setTitle("");
    setIsOpen(false);
  };

  if (!isOpen) {
    return (
      <button className="add-ticket-btn" onClick={() => setIsOpen(true)}>
        + Add ticket
      </button>
    );
  }

  return (
    <form className="new-ticket-form" onSubmit={handleSubmit}>
      <input
        type="text"
        placeholder="Ticket title..."
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        autoFocus
        onKeyDown={(e) => {
          if (e.key === "Escape") {
            setIsOpen(false);
            setTitle("");
          }
        }}
      />
      <div className="new-ticket-actions">
        <button type="submit">Add</button>
        <button
          type="button"
          onClick={() => {
            setIsOpen(false);
            setTitle("");
          }}
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
