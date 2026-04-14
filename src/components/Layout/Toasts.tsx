import { useNotifications } from "../../notifications";

export function Toasts() {
  const { notifications, dismiss } = useNotifications();

  if (notifications.length === 0) return null;

  return (
    <div className="toast-container">
      {notifications.map((n) => (
        <div key={n.id} className={`toast toast-${n.type}`}>
          <span>{n.message}</span>
          <button className="toast-dismiss" onClick={() => dismiss(n.id)}>
            &times;
          </button>
        </div>
      ))}
    </div>
  );
}
