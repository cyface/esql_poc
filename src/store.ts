import { create } from "zustand";

const COLORS = [
  "#e74c3c", "#3498db", "#2ecc71", "#f39c12",
  "#9b59b6", "#1abc9c", "#e67e22", "#e91e63",
];

const NAMES = [
  "Alice", "Bob", "Charlie", "Diana",
  "Eve", "Frank", "Grace", "Hank",
];

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

interface AppState {
  clientId: string;
  clientName: string;
  clientColor: string;
  filter: "all" | "active" | "completed";
  setFilter: (filter: "all" | "active" | "completed") => void;
}

export const useAppStore = create<AppState>((set) => ({
  clientId: crypto.randomUUID(),
  clientName: pickRandom(NAMES),
  clientColor: pickRandom(COLORS),
  filter: "all",
  setFilter: (filter) => set({ filter }),
}));
