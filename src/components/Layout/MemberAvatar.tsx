import type { Member } from "../../types";

interface MemberAvatarProps {
  member: Member | undefined;
  size?: number;
}

export function MemberAvatar({ member, size = 28 }: MemberAvatarProps) {
  if (!member) return null;
  const initials = member.name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase();

  return (
    <span
      className="member-avatar"
      title={member.name}
      style={{
        width: size,
        height: size,
        fontSize: size * 0.4,
        backgroundColor: member.color,
      }}
    >
      {initials}
    </span>
  );
}
