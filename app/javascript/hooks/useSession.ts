import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { getSession, login, logout, type LoginParams } from "@/lib/api/session";

// data は User(ログイン中)/ null(未ログイン)/ undefined(確認中)
export const useSession = () =>
  useQuery({
    queryKey: ["session"],
    queryFn: getSession,
    staleTime: Infinity,
  });

export const useLogin = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (params: LoginParams) => login(params),
    onSuccess: (user) => {
      queryClient.setQueryData(["session"], user);
    },
  });
};

export const useLogout = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: logout,
    onSuccess: () => {
      // 先にセッションを null にして RequireAuth に /login へ遷移させる
      // (clear() はアクティブな observer に通知されず遷移しない)。
      // 遷移でページが unmount された後、前のユーザーのキャッシュを破棄する
      queryClient.setQueryData(["session"], null);
      queryClient.removeQueries({
        predicate: (query) => query.queryKey[0] !== "session",
      });
    },
  });
};
