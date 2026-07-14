import { z } from "zod";

import { api } from "@/lib/api";
import { taskSchema, type Task } from "@/types/task";

const taskResponseSchema = z.object({
  task: taskSchema,
});

export interface UpdateTaskParams {
  title?: string;
  description?: string;
  category?: string;
  estimated_days?: number;
  estimated_price?: number;
  tags?: string[];
}

// estimated_days か estimated_price を変更するとサーバー側で estimated_by が "user" になる
export const updateTask = async (
  id: number,
  params: UpdateTaskParams
): Promise<Task> =>
  taskResponseSchema.parse(await api.patch(`/tasks/${id}`, { task: params }))
    .task;
