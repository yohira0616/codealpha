import { Navigate, Outlet } from "react-router-dom";

import { useSession } from "@/hooks/useSession";

// ログイン必須ルートのガード。未ログインなら /login へ逃がす
export function RequireAuth() {
  const { data: user, isPending } = useSession();

  if (isPending) {
    return <p className="p-8 text-center text-gray-500">読み込み中...</p>;
  }
  if (!user) {
    return <Navigate to="/login" replace />;
  }
  return <Outlet />;
}
