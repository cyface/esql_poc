import express from "express";
import cors from "cors";
import pg from "pg";

const app = express();
app.use(cors());
app.use(express.json());

const pool = new pg.Pool({
  connectionString:
    process.env.DATABASE_URL ??
    "postgresql://postgres:password@localhost:54321/electric",
});

app.post("/api/todos", async (req, res) => {
  const { id, title, created_by } = req.body;
  await pool.query(
    "INSERT INTO todos (id, title, created_by) VALUES ($1, $2, $3)",
    [id, title, created_by]
  );
  res.json({ ok: true });
});

app.patch("/api/todos/:id", async (req, res) => {
  const { id } = req.params;
  const { completed } = req.body;
  await pool.query("UPDATE todos SET completed = $1 WHERE id = $2", [
    completed,
    id,
  ]);
  res.json({ ok: true });
});

app.delete("/api/todos/:id", async (req, res) => {
  const { id } = req.params;
  await pool.query("DELETE FROM todos WHERE id = $1", [id]);
  res.json({ ok: true });
});

app.delete("/api/todos", async (_req, res) => {
  await pool.query("DELETE FROM todos");
  res.json({ ok: true });
});

const port = process.env.API_PORT ?? 4001;
app.listen(port, () => {
  console.log(`API server running on http://localhost:${port}`);
});
