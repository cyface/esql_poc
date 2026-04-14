import { useMemo } from "react";
import { Header } from "./components/Layout/Header";
import { FilterBar } from "./components/Layout/FilterBar";
import { KanbanBoard } from "./components/Board/KanbanBoard";
import { TicketDetailPanel } from "./components/TicketDetail/TicketDetailPanel";
import { Toasts } from "./components/Layout/Toasts";
import { useBoard } from "./hooks/useBoard";
import { useColumns } from "./hooks/useColumns";
import { useTickets } from "./hooks/useTickets";
import { useMembers } from "./hooks/useMembers";
import { useLabels } from "./hooks/useLabels";
import { useTicketLabels } from "./hooks/useTicketLabels";
import { useAppStore } from "./store";
import "./App.css";

function App() {
  const { board, isLoading, isError } = useBoard();
  const { columns, isError: columnsError } = useColumns();
  const { members, isError: membersError } = useMembers();
  const { labels, isError: labelsError } = useLabels();
  const dataError = columnsError || membersError || labelsError;
  const { ticketLabels } = useTicketLabels();
  const { selectedTicketId, setSelectedTicketId } = useAppStore();

  const ticketLabelMap = useMemo(() => {
    const map: Record<string, string[]> = {};
    for (const tl of ticketLabels) {
      if (!map[tl.ticket_id]) map[tl.ticket_id] = [];
      map[tl.ticket_id].push(tl.label_id);
    }
    return map;
  }, [ticketLabels]);

  const { tickets, ticketsByColumn, addTicket, updateTicket, moveTicket, removeTicket } =
    useTickets(ticketLabelMap);

  if (isLoading) {
    return (
      <div className="app loading-screen">
        <p>Connecting to Electric...</p>
      </div>
    );
  }

  if (isError || dataError) {
    return (
      <div className="app loading-screen">
        <p className="error">
          Failed to load board data. {isError ? "Is Docker running?" : "Some data failed to load — try refreshing."}
        </p>
      </div>
    );
  }

  return (
    <div className="app">
      <Header board={board} members={members} />
      <FilterBar
        members={members}
        labels={labels}
        totalCount={tickets.length}
      />
      <KanbanBoard
        columns={columns}
        ticketsByColumn={ticketsByColumn}
        members={members}
        labels={labels}
        ticketLabelMap={ticketLabelMap}
        onMoveTicket={moveTicket}
        onAddTicket={addTicket}
        onSelectTicket={setSelectedTicketId}
      />
      {selectedTicketId && (
        <TicketDetailPanel
          ticketId={selectedTicketId}
          members={members}
          onClose={() => setSelectedTicketId(null)}
          onUpdate={updateTicket}
          onDelete={removeTicket}
        />
      )}
      <Toasts />
    </div>
  );
}

export default App;
