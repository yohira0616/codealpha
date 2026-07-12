import { z } from "zod";

import { taskSchema } from "@/types/task";

export const conversationStatusSchema = z.enum([
  "pending",
  "running",
  "completed",
  "failed",
]);

export type ConversationStatus = z.infer<typeof conversationStatusSchema>;

// GET /api/projects/:id の conversations 配列で返る形
export const conversationSummarySchema = z.object({
  id: z.number(),
  title: z.string().nullable(),
  status: conversationStatusSchema,
  created_at: z.string(),
});

export type ConversationSummary = z.infer<typeof conversationSummarySchema>;

export const messageSchema = z.object({
  id: z.number(),
  role: z.enum(["user", "assistant"]),
  content: z.string(),
  created_at: z.string(),
});

export type Message = z.infer<typeof messageSchema>;

// GET /api/conversations/:id で返る形(messages, tasks 含む)
export const conversationSchema = z.object({
  id: z.number(),
  project_id: z.number(),
  title: z.string().nullable(),
  status: conversationStatusSchema,
  created_at: z.string(),
  messages: z.array(messageSchema),
  tasks: z.array(taskSchema),
});

export type Conversation = z.infer<typeof conversationSchema>;
