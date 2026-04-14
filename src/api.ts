import type { Board, Member, Column, Label } from "./types";

const API_URL = import.meta.env.VITE_API_URL ?? "http://localhost:4001";

const JSON_HEADERS = {
  "Content-Type": "application/json",
  Prefer: "return=minimal",
};

async function postgrest(
  path: string,
  init?: RequestInit
): Promise<Response> {
  const res = await fetch(`${API_URL}${path}`, init);
  if (!res.ok) {
    let detail = "";
    try {
      const body = await res.json();
      detail = ` - ${body.message ?? JSON.stringify(body)}`;
    } catch {
      // Response body wasn't JSON
    }
    throw new Error(`PostgREST ${init?.method ?? "GET"} ${path} failed: ${res.status}${detail}`);
  }
  return res;
}

function postJson(path: string, body: Record<string, unknown>): Promise<Response> {
  return postgrest(path, { method: "POST", headers: JSON_HEADERS, body: JSON.stringify(body) });
}

function patchJson(table: string, id: string, body: Record<string, unknown>): Promise<Response> {
  return postgrest(`/${table}?id=eq.${id}`, { method: "PATCH", headers: JSON_HEADERS, body: JSON.stringify(body) });
}

function deleteById(table: string, id: string): Promise<Response> {
  return postgrest(`/${table}?id=eq.${id}`, { method: "DELETE" });
}

// --- Static data (loaded once, no Electric sync needed) ---

export async function fetchBoards(): Promise<Board[]> {
  const res = await postgrest("/boards");
  return res.json();
}

export async function fetchMembers(): Promise<Member[]> {
  const res = await postgrest("/members");
  return res.json();
}

export async function fetchColumns(): Promise<Column[]> {
  const res = await postgrest("/columns?order=position.asc");
  return res.json();
}

export async function fetchLabels(): Promise<Label[]> {
  const res = await postgrest("/labels");
  return res.json();
}

// --- Columns ---

export function createColumn(col: Record<string, unknown>): Promise<Response> { return postJson("/columns", col); }
export function updateColumn(id: string, data: Record<string, unknown>): Promise<Response> { return patchJson("columns", id, data); }
export function deleteColumn(id: string): Promise<Response> { return deleteById("columns", id); }

// --- Labels ---

export function createLabel(label: Record<string, unknown>): Promise<Response> { return postJson("/labels", label); }
export function updateLabel(id: string, data: Record<string, unknown>): Promise<Response> { return patchJson("labels", id, data); }
export function deleteLabel(id: string): Promise<Response> { return deleteById("labels", id); }

// --- Tickets ---

export function createTicket(ticket: Record<string, unknown>): Promise<Response> { return postJson("/tickets", ticket); }
export function updateTicket(id: string, data: Record<string, unknown>): Promise<Response> { return patchJson("tickets", id, data); }
export function deleteTicket(id: string): Promise<Response> { return deleteById("tickets", id); }

// --- Ticket Labels ---

export function createTicketLabel(tl: Record<string, unknown>): Promise<Response> { return postJson("/ticket_labels", tl); }
export function deleteTicketLabel(id: string): Promise<Response> { return deleteById("ticket_labels", id); }

// --- Comments ---

export function createComment(comment: Record<string, unknown>): Promise<Response> { return postJson("/comments", comment); }
export function updateComment(id: string, data: Record<string, unknown>): Promise<Response> { return patchJson("comments", id, data); }
export function deleteComment(id: string): Promise<Response> { return deleteById("comments", id); }
