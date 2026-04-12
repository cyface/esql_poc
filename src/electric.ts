const ELECTRIC_URL = import.meta.env.VITE_ELECTRIC_URL ?? "http://localhost:3000";

export interface Todo {
  [key: string]: unknown;
  id: string;
  title: string;
  completed: boolean;
  created_by: string;
  created_at: string;
}

export const todosShapeOptions = {
  url: `${ELECTRIC_URL}/v1/shape`,
  params: {
    table: "todos",
  },
} as const;
