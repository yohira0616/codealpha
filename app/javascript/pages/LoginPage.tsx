import { useState, type FormEvent } from "react";
import { Navigate } from "react-router-dom";

import { useLogin, useSession } from "@/hooks/useSession";

export function LoginPage() {
  const { data: user } = useSession();
  const loginMutation = useLogin();

  const [emailAddress, setEmailAddress] = useState("");
  const [password, setPassword] = useState("");

  // ログイン済み(直接アクセス or ログイン成功直後)はトップへ
  if (user) {
    return <Navigate to="/" replace />;
  }

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (loginMutation.isPending) return;
    loginMutation.mutate({ email_address: emailAddress.trim(), password });
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-sm space-y-6">
        <h1 className="text-center text-2xl font-bold">Codealpha</h1>
        <form
          onSubmit={handleSubmit}
          className="space-y-4 rounded-lg border border-gray-200 bg-white p-6"
        >
          <div>
            <label htmlFor="login-email" className="mb-1 block text-xs text-gray-500">
              メールアドレス
            </label>
            <input
              id="login-email"
              type="email"
              autoComplete="email"
              required
              value={emailAddress}
              onChange={(e) => setEmailAddress(e.target.value)}
              className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-gray-500 focus:outline-none"
            />
          </div>
          <div>
            <label htmlFor="login-password" className="mb-1 block text-xs text-gray-500">
              パスワード
            </label>
            <input
              id="login-password"
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-gray-500 focus:outline-none"
            />
          </div>
          {loginMutation.error && (
            <p className="text-sm text-red-600">{loginMutation.error.message}</p>
          )}
          <button
            type="submit"
            disabled={loginMutation.isPending}
            className="w-full rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700 disabled:opacity-50"
          >
            {loginMutation.isPending ? "ログイン中..." : "ログイン"}
          </button>
        </form>
      </div>
    </div>
  );
}
