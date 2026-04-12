import { useShape } from "@electric-sql/react";
import { useMutation, useMutationState, useQueryClient } from "@tanstack/react-query";
import { v4 as uuidv4 } from "uuid";
import { todosShapeOptions, type Todo } from "../electric";
import { createTodo, toggleTodo, deleteTodo, clearAllTodos } from "../api";
import { useAppStore } from "../store";

export function useTodos() {
  const queryClient = useQueryClient();
  const { clientId, clientName, filter } = useAppStore();

  // Electric SQL: real-time read path from Postgres
  const { data: serverTodos, isLoading, isError } = useShape<Todo>(todosShapeOptions);

  // TanStack Query: optimistic mutation state for pending writes
  const pendingCreates = useMutationState<Todo>({
    filters: { mutationKey: ["createTodo"], status: "pending" },
    select: (mutation) => mutation.state.context as Todo,
  }).filter(Boolean);

  const addMutation = useMutation({
    mutationKey: ["createTodo"],
    mutationFn: ({ id, title }: { id: string; title: string }) =>
      createTodo(id, title, clientName),
    onMutate: ({ id, title }) => {
      // Return optimistic todo as context
      return {
        id,
        title,
        completed: false,
        created_by: clientName,
        created_at: new Date().toISOString(),
      } satisfies Todo;
    },
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ["todos"] });
    },
  });

  const toggleMutation = useMutation({
    mutationKey: ["toggleTodo"],
    mutationFn: ({ id, completed }: { id: string; completed: boolean }) =>
      toggleTodo(id, completed),
  });

  const deleteMutation = useMutation({
    mutationKey: ["deleteTodo"],
    mutationFn: (id: string) => deleteTodo(id),
  });

  const clearMutation = useMutation({
    mutationKey: ["clearTodos"],
    mutationFn: clearAllTodos,
  });

  // Merge server data with optimistic pending creates
  const mergedTodos = (() => {
    const map = new Map<string, Todo>();
    for (const todo of serverTodos) {
      map.set(todo.id, todo);
    }
    for (const todo of pendingCreates) {
      if (!map.has(todo.id)) {
        map.set(todo.id, todo);
      }
    }
    return Array.from(map.values());
  })();

  // Apply local filter (Zustand state)
  const filteredTodos = mergedTodos
    .filter((todo) => {
      if (filter === "active") return !todo.completed;
      if (filter === "completed") return todo.completed;
      return true;
    })
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

  return {
    todos: filteredTodos,
    totalCount: mergedTodos.length,
    activeCount: mergedTodos.filter((t) => !t.completed).length,
    isLoading,
    isError,
    addTodo: (title: string) => {
      const id = uuidv4();
      addMutation.mutate({ id, title });
    },
    toggleTodo: (id: string, completed: boolean) => {
      toggleMutation.mutate({ id, completed });
    },
    deleteTodo: (id: string) => {
      deleteMutation.mutate(id);
    },
    clearAll: () => {
      clearMutation.mutate();
    },
    clientId,
  };
}
