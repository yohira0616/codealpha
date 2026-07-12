import { z } from "zod";

import { api } from "@/lib/api";
import { conversationSchema, type Conversation } from "@/types/conversation";

const conversationResponseSchema = z.object({
  conversation: conversationSchema,
});

export const getConversation = async (id: number): Promise<Conversation> =>
  conversationResponseSchema.parse(await api.get(`/conversations/${id}`))
    .conversation;

// 対話開始(最初の user メッセージ付きで Conversation を作成し、ジョブを enqueue)
export const startConversation = async (
  projectId: number,
  message: string
): Promise<Conversation> =>
  conversationResponseSchema.parse(
    await api.post(`/projects/${projectId}/conversations`, { message })
  ).conversation;

// 発言追加。status が pending/running 中は 422 { error: "応答待ちです" }
export const sendMessage = async (
  conversationId: number,
  content: string
): Promise<Conversation> =>
  conversationResponseSchema.parse(
    await api.post(`/conversations/${conversationId}/messages`, { content })
  ).conversation;
