const API_URL = import.meta.env.VITE_API_URL ?? "http://localhost:4001";

export async function createTodo(id: string, title: string, createdBy: string) {
  const res = await fetch(`${API_URL}/todos`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify({ id, title, created_by: createdBy }),
  });
  if (!res.ok) throw new Error("Failed to create todo");
}

export async function toggleTodo(id: string, completed: boolean) {
  const res = await fetch(`${API_URL}/todos?id=eq.${id}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify({ completed }),
  });
  if (!res.ok) throw new Error("Failed to update todo");
}

export async function deleteTodo(id: string) {
  const res = await fetch(`${API_URL}/todos?id=eq.${id}`, {
    method: "DELETE",
  });
  if (!res.ok) throw new Error("Failed to delete todo");
}

export async function clearAllTodos() {
  const res = await fetch(`${API_URL}/todos`, {
    method: "DELETE",
  });
  if (!res.ok) throw new Error("Failed to clear todos");
}
