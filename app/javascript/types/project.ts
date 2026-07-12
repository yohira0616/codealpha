import { z } from "zod";

import { conversationSummarySchema } from "@/types/conversation";
import { taskSchema } from "@/types/task";

// GET /api/projects の一覧行
export const projectListItemSchema = z.object({
  id: z.number(),
  name: z.string(),
  client_name: z.string().nullable(),
  status: z.string(),
  daily_rate: z.number(),
  total_estimated_days: z.number(),
  total_estimated_price: z.number(),
  updated_at: z.string(),
});

export type ProjectListItem = z.infer<typeof projectListItemSchema>;

// GET /api/projects/:id(show)の形。POST / PATCH も同形を返す
export const projectSchema = z.object({
  id: z.number(),
  name: z.string(),
  client_name: z.string().nullable(),
  requirement_text: z.string().nullable(),
  daily_rate: z.number(),
  status: z.string(),
  total_estimated_days: z.number(),
  total_estimated_price: z.number(),
  tasks: z.array(taskSchema),
  conversations: z.array(conversationSummarySchema),
});

export type Project = z.infer<typeof projectSchema>;
