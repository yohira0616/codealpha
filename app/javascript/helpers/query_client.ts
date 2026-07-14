import { MutationCache, QueryCache, QueryClient } from "@tanstack/react-query";

import { ApiError } from "@/lib/api";

// 操作中にセッションが失効(401)したらログイン状態を破棄し、
// RequireAuth に /login への遷移を任せる
const handleUnauthorized = (error: unknown) => {
  if (error instanceof ApiError && error.status === 401) {
    queryClient.setQueryData(["session"], null);
  }
};

const queryClient = new QueryClient({
  queryCache: new QueryCache({ onError: handleUnauthorized }),
  mutationCache: new MutationCache({ onError: handleUnauthorized }),
  defaultOptions: {
    queries: {
      retry: false,
      throwOnError: false,
    },
  },
});

export default queryClient;
