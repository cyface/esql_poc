export interface Todo {
  [key: string]: unknown;
  id: string;
  title: string;
  completed: boolean;
  created_by: string;
  created_at: string;
}
