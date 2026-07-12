import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useRef } from "react";

import {
  getConversation,
  sendMessage,
  startConversation,
} from "@/lib/api/conversations";
import type { ConversationStatus } from "@/types/conversation";

const isWaiting = (status: ConversationStatus | undefined) =>
  status === "pending" || status === "running";

// status が pending/running の間だけ 2 秒間隔でポーリングし、
// completed/failed になったら停止して project クエリを invalidate する
export const useConversation = (id: number | undefined) => {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ["conversations", id],
    queryFn: () => getConversation(id as number),
    enabled: id !== undefined,
    refetchInterval: (q) => (isWaiting(q.state.data?.status) ? 2000 : false),
  });

  const status = query.data?.status;
  const projectId = query.data?.project_id;
  const prevStatusRef = useRef<ConversationStatus | undefined>(undefined);

  useEffect(() => {
    const prev = prevStatusRef.current;
    prevStatusRef.current = status;
    if (
      isWaiting(prev) &&
      (status === "completed" || status === "failed") &&
      projectId !== undefined
    ) {
      // タスク一覧・合計が更新されるので project 詳細と一覧を再取得
      void queryClient.invalidateQueries({ queryKey: ["projects"] });
    }
  }, [status, projectId, queryClient]);

  return query;
};

export const useStartConversation = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ projectId, message }: { projectId: number; message: string }) =>
      startConversation(projectId, message),
    onSuccess: (conversation) => {
      queryClient.setQueryData(["conversations", conversation.id], conversation);
      // in-flight の古い GET に setQueryData が上書きされてもポーリングが再開するよう invalidate する
      void queryClient.invalidateQueries({
        queryKey: ["conversations", conversation.id],
      });
      // project の conversations に新しい会話が載るように再取得
      void queryClient.invalidateQueries({
        queryKey: ["projects", conversation.project_id],
      });
    },
  });
};

export const useSendMessage = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({
      conversationId,
      content,
    }: {
      conversationId: number;
      content: string;
    }) => sendMessage(conversationId, content),
    onSuccess: (conversation) => {
      queryClient.setQueryData(["conversations", conversation.id], conversation);
      // in-flight の古い GET に setQueryData が上書きされてもポーリングが再開するよう invalidate する
      void queryClient.invalidateQueries({
        queryKey: ["conversations", conversation.id],
      });
    },
  });
};
