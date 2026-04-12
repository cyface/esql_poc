import type { Todo } from "../electric";

interface TodoListProps {
  todos: Todo[];
  onToggle: (id: string, completed: boolean) => void;
  onDelete: (id: string) => void;
}

export function TodoList({ todos, onToggle, onDelete }: TodoListProps) {
  if (todos.length === 0) {
    return <p className="empty">No todos yet. Add one above!</p>;
  }

  return (
    <ul className="todo-list">
      {todos.map((todo) => (
        <li key={todo.id} className={todo.completed ? "completed" : ""}>
          <label>
            <input
              type="checkbox"
              checked={todo.completed}
              onChange={() => onToggle(todo.id, !todo.completed)}
            />
            <span className="title">{todo.title}</span>
          </label>
          <span className="meta">by {todo.created_by}</span>
          <button className="delete" onClick={() => onDelete(todo.id)}>
            &times;
          </button>
        </li>
      ))}
    </ul>
  );
}
