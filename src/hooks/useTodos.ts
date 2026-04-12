import { useLiveQuery, eq } from "@tanstack/react-db";
import { v4 as uuidv4 } from "uuid";
import { todosCollection } from "../collection";
import { clearAllTodos } from "../api";
import { useAppStore } from "../store";
import type { Todo } from "../electric";

export function useTodos() {
  const { clientName, filter } = useAppStore();

  // All todos (for counts) — direct collection query, always unfiltered
  const { data: allTodos } = useLiveQuery(todosCollection);

  // Filtered + sorted todos for display
  const {
    data: filteredTodos,
    isLoading,
    isError,
  } = useLiveQuery(
    (q) => {
      const base = q.from({ todo: todosCollection });
      if (filter === "active")
        return base.where(({ todo }) => eq(todo.completed, false));
      if (filter === "completed")
        return base.where(({ todo }) => eq(todo.completed, true));
      return base;
    },
    [filter]
  );

  const todos = (filteredTodos ?? []) as Todo[];
  const all = (allTodos ?? []) as Todo[];

  return {
    todos,
    totalCount: all.length,
    activeCount: all.filter((t) => !t.completed).length,
    isLoading,
    isError,
    addTodo: (title: string) => {
      todosCollection.insert({
        id: uuidv4(),
        title,
        completed: false,
        created_by: clientName,
        created_at: new Date().toISOString(),
      } as Todo);
    },
    toggleTodo: (id: string, completed: boolean) => {
      todosCollection.update(id, (draft) => {
        (draft as Todo).completed = completed;
      });
    },
    deleteTodo: (id: string) => {
      todosCollection.delete(id);
    },
    clearAll: () => {
      clearAllTodos();
    },
  };
}
