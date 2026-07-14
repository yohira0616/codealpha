import { NavLink, Outlet } from "react-router-dom";

import { useLogout, useSession } from "@/hooks/useSession";
import { cn } from "@/lib/utils";

const navLinkClass = ({ isActive }: { isActive: boolean }) =>
  cn(
    "rounded-md px-3 py-2 text-sm font-medium",
    isActive ? "bg-gray-900 text-white" : "text-gray-700 hover:bg-gray-200"
  );

export function Layout() {
  const { data: user } = useSession();
  const logoutMutation = useLogout();

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="border-b border-gray-200 bg-white">
        <nav className="mx-auto flex max-w-6xl items-center gap-2 px-4 py-3">
          <span className="mr-4 text-lg font-bold">Codealpha</span>
          <NavLink to="/" end className={navLinkClass}>
            プロジェクト
          </NavLink>
          <div className="ml-auto flex items-center gap-3">
            <span className="text-sm text-gray-500">{user?.email_address}</span>
            <button
              type="button"
              onClick={() => logoutMutation.mutate()}
              disabled={logoutMutation.isPending}
              className="rounded-md px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200 disabled:opacity-50"
            >
              ログアウト
            </button>
          </div>
        </nav>
      </header>
      <main className="mx-auto max-w-6xl px-4 py-8">
        <Outlet />
      </main>
    </div>
  );
}
