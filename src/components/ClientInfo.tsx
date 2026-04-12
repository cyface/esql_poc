import { useAppStore } from "../store";

export function ClientInfo() {
  const { clientName, clientColor } = useAppStore();

  return (
    <div className="client-info">
      <span className="dot" style={{ backgroundColor: clientColor }} />
      <span>Connected as <strong>{clientName}</strong></span>
      <span className="hint">Open another tab to see real-time sync</span>
    </div>
  );
}
