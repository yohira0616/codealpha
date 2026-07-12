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
});

export type Task = z.infer<typeof taskSchema>;
