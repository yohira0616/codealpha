import { useState, type FormEvent } from "react";

import {
  useConversation,
  useSendMessage,
  useStartConversation,
} from "@/hooks/useConversation";
import { cn } from "@/lib/utils";
import type { Conversation } from "@/types/conversation";

// PoC では 1 プロジェクト 1 会話運用。
// 会話が無ければ開始フォーム、あればチャット表示を出す。
export function ConversationPanel({
  projectId,
  conversationId,
}: {
  projectId: number;
  conversationId: number | undefined;
}) {
  // 開始成功〜project 再取得完了までの間も mutation の結果で即チャットに切り替え、
  // フォームの再表示による会話の二重作成を防ぐ
  const startConversation = useStartConversation();
  const effectiveId = conversationId ?? startConversation.data?.id;

  if (effectiveId === undefined) {
    return (
      <StartConversationForm
        projectId={projectId}
        startConversation={startConversation}
      />
    );
  }
  return <ChatPanel conversationId={effectiveId} />;
}

function StartConversationForm({
  projectId,
  startConversation,
}: {
  projectId: number;
  startConversation: ReturnType<typeof useStartConversation>;
}) {
  const [message, setMessage] = useState("");

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const trimmed = message.trim();
    if (!trimmed || startConversation.isPending) return;
    startConversation.mutate({ projectId, message: trimmed });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-2">
      <p className="text-sm text-gray-600">
        まだ対話がありません。最初のメッセージを送ってタスクを洗い出しましょう。
      </p>
      <textarea
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        rows={3}
        placeholder="例: この要件からタスクを洗い出してください"
        className="w-full rounded-md border border-gray-300 bg-white p-2 text-sm focus:border-gray-500 focus:outline-none"
      />
      {startConversation.error && (
        <p className="text-sm text-red-600">{startConversation.error.message}</p>
      )}
      <button
        type="submit"
        disabled={startConversation.isPending || !message.trim()}
        className="rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700 disabled:opacity-50"
      >
        {startConversation.isPending ? "開始中..." : "タスクを洗い出す"}
      </button>
    </form>
  );
}

function ChatPanel({ conversationId }: { conversationId: number }) {
  const { data: conversation, isPending, error } = useConversation(conversationId);
  const sendMessage = useSendMessage();
  const [input, setInput] = useState("");

  if (isPending) {
    return <p className="text-sm text-gray-500">対話を読み込み中...</p>;
  }
  if (error) {
    return <p className="text-sm text-red-600">{error.message}</p>;
  }

  const waiting =
    conversation.status === "pending" || conversation.status === "running";
  const disabled = waiting || sendMessage.isPending;

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const trimmed = input.trim();
    if (!trimmed || disabled) return;
    sendMessage.mutate(
      { conversationId, content: trimmed },
      { onSuccess: () => setInput("") }
    );
  };

  const lastUserMessage = [...conversation.messages]
    .reverse()
    .find((m) => m.role === "user");

  const handleResend = () => {
    if (!lastUserMessage || disabled) return;
    sendMessage.mutate({ conversationId, content: lastUserMessage.content });
  };

  return (
    <div className="space-y-3">
      <MessageList conversation={conversation} />

      {waiting && (
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <span className="inline-block size-4 animate-spin rounded-full border-2 border-gray-300 border-t-gray-600" />
          応答を生成中...
        </div>
      )}

      {conversation.status === "failed" && (
        <div className="flex items-center justify-between gap-2 rounded-md border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700">
          <span>応答の生成に失敗しました。</span>
          {lastUserMessage && (
            <button
              type="button"
              onClick={handleResend}
              disabled={disabled}
              className="shrink-0 rounded-md border border-red-300 bg-white px-2 py-1 text-xs font-medium text-red-700 hover:bg-red-100 disabled:opacity-50"
            >
              再送
            </button>
          )}
        </div>
      )}

      {sendMessage.error && (
        <p className="text-sm text-red-600">{sendMessage.error.message}</p>
      )}

      <form onSubmit={handleSubmit} className="flex items-end gap-2">
        <textarea
          value={input}
          onChange={(e) => setInput(e.target.value)}
          rows={2}
          disabled={disabled}
          placeholder="追加の指示や修正依頼を入力..."
          className="w-full rounded-md border border-gray-300 bg-white p-2 text-sm focus:border-gray-500 focus:outline-none disabled:bg-gray-100 disabled:text-gray-400"
        />
        <button
          type="submit"
          disabled={disabled || !input.trim()}
          className="shrink-0 rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700 disabled:opacity-50"
        >
          送信
        </button>
      </form>
    </div>
  );
}

function MessageList({ conversation }: { conversation: Conversation }) {
  return (
    <div className="max-h-96 space-y-2 overflow-y-auto rounded-md border border-gray-200 bg-gray-50 p-3">
      {conversation.messages.length === 0 && (
        <p className="text-sm text-gray-500">メッセージはまだありません。</p>
      )}
      {conversation.messages.map((message) => (
        <div
          key={message.id}
          className={cn(
            "flex",
            message.role === "user" ? "justify-end" : "justify-start"
          )}
        >
          <div
            className={cn(
              "max-w-[85%] whitespace-pre-wrap rounded-lg px-3 py-2 text-sm",
              message.role === "user"
                ? "bg-blue-600 text-white"
                : "border border-gray-200 bg-white text-gray-800"
            )}
          >
            {message.content}
          </div>
        </div>
      ))}
    </div>
  );
}
