import { useState } from "react";

import { useUpdateTask } from "@/hooks/useUpdateTask";
import { cn } from "@/lib/utils";
import type { Task } from "@/types/task";

export function TaskTable({
  tasks,
  totalDays,
  totalPrice,
}: {
  tasks: Task[];
  totalDays: number;
  totalPrice: number;
}) {
  const updateTask = useUpdateTask();

  return (
    <div className="space-y-3">
      <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50 text-left text-xs text-gray-500">
              <th className="px-3 py-2 font-medium">タイトル</th>
              <th className="px-3 py-2 font-medium">カテゴリ</th>
              <th className="px-3 py-2 text-right font-medium">人日</th>
              <th className="px-3 py-2 text-right font-medium">価格</th>
              <th className="px-3 py-2 font-medium">推定元</th>
            </tr>
          </thead>
          <tbody>
            {tasks.length === 0 && (
              <tr>
                <td colSpan={5} className="px-3 py-6 text-center text-gray-500">
                  タスクはまだありません。対話でタスクを洗い出してください。
                </td>
              </tr>
            )}
            {tasks.map((task) => (
              <tr key={task.id} className="border-b border-gray-100 last:border-b-0">
                <td className="px-3 py-2">
                  <div className="font-medium text-gray-900">{task.title}</div>
                  {task.description && (
                    <div className="mt-0.5 text-xs text-gray-500">
                      {task.description}
                    </div>
                  )}
                </td>
                <td className="px-3 py-2">
                  {task.category ? (
                    <span className="inline-block rounded-full border border-gray-300 bg-gray-50 px-2 py-0.5 text-xs text-gray-600">
                      {task.category}
                    </span>
                  ) : (
                    <span className="text-gray-400">—</span>
                  )}
                </td>
                <td className="px-1 py-1 text-right">
                  <EditableNumberCell
                    value={task.estimated_days}
                    onSave={(value) =>
                      updateTask.mutate({
                        id: task.id,
                        params: { estimated_days: value },
                      })
                    }
                  />
                </td>
                <td className="px-1 py-1 text-right">
                  <EditableNumberCell
                    value={task.estimated_price}
                    format={(n) => `${n.toLocaleString()}円`}
                    onSave={(value) =>
                      updateTask.mutate({
                        id: task.id,
                        params: { estimated_price: value },
                      })
                    }
                  />
                </td>
                <td className="px-3 py-2">
                  <span
                    className={cn(
                      "inline-block rounded-full px-2 py-0.5 text-xs font-medium",
                      task.estimated_by === "user"
                        ? "bg-amber-100 text-amber-800"
                        : "bg-gray-100 text-gray-500"
                    )}
                  >
                    {task.estimated_by === "user" ? "手動" : "LLM"}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {updateTask.error && (
        <p className="text-sm text-red-600">{updateTask.error.message}</p>
      )}

      <div className="flex justify-end gap-6 rounded-lg border border-gray-200 bg-white px-4 py-3 text-sm">
        <div>
          <span className="text-gray-500">合計人日</span>{" "}
          <span className="font-semibold tabular-nums">
            {totalDays.toLocaleString()} 人日
          </span>
        </div>
        <div>
          <span className="text-gray-500">合計金額</span>{" "}
          <span className="font-semibold tabular-nums">
            {totalPrice.toLocaleString()}円
          </span>
        </div>
      </div>
    </div>
  );
}

// セルクリックで input に切り替え、blur または Enter で保存する数値セル
function EditableNumberCell({
  value,
  format,
  onSave,
}: {
  value: number | null;
  format?: (n: number) => string;
  onSave: (value: number) => void;
}) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState("");

  const startEditing = () => {
    setDraft(value === null ? "" : String(value));
    setEditing(true);
  };

  const commit = () => {
    setEditing(false);
    const trimmed = draft.trim();
    if (trimmed === "") return;
    const parsed = Number(trimmed);
    if (Number.isNaN(parsed) || parsed < 0 || parsed === value) return;
    onSave(parsed);
  };

  if (editing) {
    return (
      <input
        autoFocus
        type="number"
        step="any"
        min="0"
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onBlur={commit}
        onKeyDown={(e) => {
          if (e.key === "Enter") e.currentTarget.blur();
          if (e.key === "Escape") setEditing(false);
        }}
        className="w-24 rounded-md border border-blue-400 px-2 py-1 text-right text-sm tabular-nums focus:outline-none"
      />
    );
  }

  return (
    <button
      type="button"
      onClick={startEditing}
      title="クリックで編集"
      className="w-full cursor-pointer rounded-md px-2 py-1 text-right tabular-nums hover:bg-blue-50"
    >
      {value === null ? (
        <span className="text-gray-400">—</span>
      ) : format ? (
        format(value)
      ) : (
        value
      )}
    </button>
  );
}
