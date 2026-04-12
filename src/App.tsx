import { ClientInfo } from "./components/ClientInfo";
import { AddTodo } from "./components/AddTodo";
import { TodoList } from "./components/TodoList";
import { FilterBar } from "./components/FilterBar";
import { useTodos } from "./hooks/useTodos";
import "./App.css";

function App() {
  const {
    todos,
    totalCount,
    activeCount,
    isLoading,
    isError,
    addTodo,
    toggleTodo,
    deleteTodo,
    clearAll,
  } = useTodos();

  return (
    <div className="app">
      <header>
        <h1>Electric SQL Sync POC</h1>
        <ClientInfo />
      </header>

      <main>
        <AddTodo onAdd={addTodo} />

        {isLoading && <p className="status">Connecting to Electric...</p>}
        {isError && (
          <p className="status error">
            Failed to connect. Is Docker running?
          </p>
        )}

        <FilterBar
          totalCount={totalCount}
          activeCount={activeCount}
          onClearAll={clearAll}
        />
        <TodoList
          todos={todos}
          onToggle={toggleTodo}
          onDelete={deleteTodo}
        />
      </main>

      <footer>
        <p>
          <strong>Stack:</strong> React + Vite + Electric SQL (reads) + TanStack
          Query (writes) + Zustand (UI state)
        </p>
      </footer>
    </div>
  );
}

export default App;
