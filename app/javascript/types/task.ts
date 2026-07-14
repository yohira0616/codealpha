import { z } from "zod";

// API契約の Task 型。estimated_days は decimal を Float にして返す(数値)
export const taskSchema = z.object({
  id: z.number(),
  project_id: z.number(),
  conversation_id: z.number().nullable(),
  title: z.string(),
  description: z.string().nullable(),
  category: z.string().nullable(),
  estimated_days: z.number().nullable(),
  estimated_price: z.number().nullable(),
  estimated_by: z.enum(["llm", "user"]),
  position: z.number().nullable(),
  tags: z.array(z.string()),
});

// 予約タグ: 付いたタスクは初期スコープの合計から除外される
export const SCOPE_OUT_TAG = "スコープ外";

export type Task = z.infer<typeof taskSchema>;
