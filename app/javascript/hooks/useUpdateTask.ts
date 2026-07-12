import { useMutation, useQueryClient } from "@tanstack/react-query";

import { updateTask, type UpdateTaskParams } from "@/lib/api/tasks";

export const useUpdateTask = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, params }: { id: number; params: UpdateTaskParams }) =>
      updateTask(id, params),
    onSuccess: (task) => {
      // タスクと合計値が変わるので project 詳細・一覧を再取得
      void queryClient.invalidateQueries({ queryKey: ["projects"] });
      if (task.conversation_id !== null) {
        void queryClient.invalidateQueries({
          queryKey: ["conversations", task.conversation_id],
        });
      }
    },
  });
};
