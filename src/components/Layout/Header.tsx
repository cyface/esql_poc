import { useAppStore } from "../../store";
import { MemberAvatar } from "./MemberAvatar";
import type { Board, Member } from "../../types";

interface HeaderProps {
  board: Board | null;
  members: Member[];
}

export function Header({ board, members }: HeaderProps) {
  const { clientName, activeMemberId, searchQuery, setSearchQuery } =
    useAppStore();

  const currentMember = members.find((m) => m.id === activeMemberId);

  return (
    <header className="board-header">
      <div className="header-left">
        <h1>{board?.name ?? "Kanban Board"}</h1>
        {board?.description && (
          <span className="board-description">{board.description}</span>
        )}
      </div>
      <div className="header-center">
        <input
          type="text"
          className="search-input"
          placeholder="Search tickets..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>
      <div className="header-right">
        <div className="member-list">
          {members.map((m) => (
            <MemberAvatar key={m.id} member={m} size={32} />
          ))}
        </div>
        <div className="client-identity">
          <MemberAvatar member={currentMember} size={24} />
          <span>{clientName}</span>
        </div>
      </div>
    </header>
  );
}
