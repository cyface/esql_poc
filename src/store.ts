import { create } from "zustand";

const NAMES = ["Alice", "Bob", "Charlie", "Diana"];

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

interface AppState {
  clientId: string;
  clientName: string;

  activeBoardId: string | null;
  setActiveBoardId: (id: string) => void;

  activeMemberId: string | null;
  setActiveMemberId: (id: string) => void;

  selectedTicketId: string | null;
  setSelectedTicketId: (id: string | null) => void;

  searchQuery: string;
  setSearchQuery: (q: string) => void;

  filterPriority: string | null;
  setFilterPriority: (p: string | null) => void;

  filterType: string | null;
  setFilterType: (t: string | null) => void;

  filterAssigneeId: string | null;
  setFilterAssigneeId: (id: string | null) => void;

  filterLabelId: string | null;
  setFilterLabelId: (id: string | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  clientId: crypto.randomUUID(),
  clientName: pickRandom(NAMES),

  activeBoardId: null,
  setActiveBoardId: (id) => set({ activeBoardId: id }),

  activeMemberId: null,
  setActiveMemberId: (id) => set({ activeMemberId: id }),

  selectedTicketId: null,
  setSelectedTicketId: (id) => set({ selectedTicketId: id }),

  searchQuery: "",
  setSearchQuery: (q) => set({ searchQuery: q }),

  filterPriority: null,
  setFilterPriority: (p) => set({ filterPriority: p }),

  filterType: null,
  setFilterType: (t) => set({ filterType: t }),

  filterAssigneeId: null,
  setFilterAssigneeId: (id) => set({ filterAssigneeId: id }),

  filterLabelId: null,
  setFilterLabelId: (id) => set({ filterLabelId: id }),
}));
