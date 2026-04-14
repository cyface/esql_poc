import { create } from "zustand";

export interface Notification {
  id: string;
  type: "error" | "info";
  message: string;
}

interface NotificationState {
  notifications: Notification[];
  addNotification: (type: "error" | "info", message: string) => void;
  dismiss: (id: string) => void;
}

export const useNotifications = create<NotificationState>((set) => ({
  notifications: [],
  addNotification: (type, message) => {
    const id = crypto.randomUUID();
    set((s) => ({ notifications: [...s.notifications, { id, type, message }] }));
    // Auto-dismiss after 6 seconds
    setTimeout(() => {
      set((s) => ({
        notifications: s.notifications.filter((n) => n.id !== id),
      }));
    }, 6000);
  },
  dismiss: (id) =>
    set((s) => ({
      notifications: s.notifications.filter((n) => n.id !== id),
    })),
}));

export function notifyError(message: string) {
  useNotifications.getState().addNotification("error", message);
}
