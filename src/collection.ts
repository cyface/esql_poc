import { createCollection } from "@tanstack/react-db";
import { electricCollectionOptions } from "@tanstack/electric-db-collection";
import type { Todo } from "./electric";
import { createTodo, toggleTodo, deleteTodo } from "./api";

const ELECTRIC_URL =
  import.meta.env.VITE_ELECTRIC_URL ?? "http://localhost:3000";

export const todosCollection = createCollection(
  electricCollectionOptions<Todo>({
    id: "todos",
    shapeOptions: {
      url: `${ELECTRIC_URL}/v1/shape`,
      params: { table: "todos" },
    },
    getKey: (todo) => todo.id,
    onInsert: async ({ transaction }) => {
      const todo = transaction.mutations[0].modified;
      await createTodo(todo.id, todo.title, todo.created_by);
    },
    onUpdate: async ({ transaction }) => {
      const todo = transaction.mutations[0].modified;
      await toggleTodo(todo.id, todo.completed);
    },
    onDelete: async ({ transaction }) => {
      const key = transaction.mutations[0].key;
      await deleteTodo(key as string);
    },
  })
);
