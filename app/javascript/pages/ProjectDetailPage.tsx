import { useState } from "react";
import { Link, useParams } from "react-router-dom";

import { ConversationPanel } from "@/components/conversations/ConversationPanel";
import { TaskTable } from "@/components/tasks/TaskTable";
import { useProject, useUpdateProject } from "@/hooks/useProjects";
import type { Project } from "@/types/project";

export function ProjectDetailPage() {
  const { id } = useParams();
  const projectId = Number(id);
  const validId = Number.isInteger(projectId) && projectId > 0;
  // useProject 側も Number.isInteger で enabled 判定するため NaN でも fetch は走らない
  const { data: project, isPending, error } = useProject(projectId);

  if (!validId) {
    return (
      <section className="space-y-4">
        <p className="text-red-600">プロジェクトが見つかりません。</p>
        <Link to="/" className="text-sm text-blue-600 hover:underline">
          ← プロジェクト一覧
        </Link>
      </section>
    );
  }

  return (
    <section className="space-y-6">
      <div className="flex items-center gap-3">
        <Link to="/" className="text-sm text-blue-600 hover:underline">
          ← プロジェクト一覧
        </Link>
      </div>

      {isPending && <p className="text-gray-500">読み込み中...</p>}
      {error && <p className="text-red-600">{error.message}</p>}

      {project && <ProjectDetail project={project} />}
    </section>
  );
}

function ProjectDetail({ project }: { project: Project }) {
  // PoC では 1 プロジェクト 1 会話運用(conversations[0] を使う)
  const conversation = project.conversations[0];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{project.name}</h1>
        <p className="mt-1 text-sm text-gray-500">
          {project.client_name ?? "顧客未設定"} / 単価{" "}
          <span className="tabular-nums">
            {project.daily_rate.toLocaleString()}円
          </span>
          /人日
        </p>
      </div>

      <div className="grid grid-cols-1 items-start gap-6 lg:grid-cols-2">
        {/* 左カラム: 要件テキスト + 対話 */}
        <div className="space-y-6">
          <div className="rounded-lg border border-gray-200 bg-white p-4">
            <h2 className="mb-2 font-semibold">要件テキスト</h2>
            {/* key でプロジェクト切替時に編集中テキストをリセットする */}
            <RequirementForm key={project.id} project={project} />
          </div>

          <div className="rounded-lg border border-gray-200 bg-white p-4">
            <h2 className="mb-2 font-semibold">対話</h2>
            <ConversationPanel
              projectId={project.id}
              conversationId={conversation?.id}
            />
          </div>
        </div>

        {/* 右カラム: タスクテーブル + 合計 */}
        <div>
          <h2 className="mb-2 font-semibold">タスク見積もり</h2>
          <TaskTable
            tasks={project.tasks}
            totalDays={project.total_estimated_days}
            totalPrice={project.total_estimated_price}
          />
        </div>
      </div>
    </div>
  );
}

function RequirementForm({ project }: { project: Project }) {
  const updateProject = useUpdateProject();
  const [requirement, setRequirement] = useState(project.requirement_text ?? "");

  const handleSave = () => {
    if (updateProject.isPending) return;
    updateProject.mutate({
      id: project.id,
      params: { requirement_text: requirement },
    });
  };

  return (
    <div className="space-y-2">
      <textarea
        value={requirement}
        onChange={(e) => setRequirement(e.target.value)}
        rows={8}
        placeholder="提案書・議事録・ヒアリングメモなどを貼り付けてください"
        className="w-full rounded-md border border-gray-300 bg-white p-2 text-sm focus:border-gray-500 focus:outline-none"
      />
      {updateProject.error && (
        <p className="text-sm text-red-600">{updateProject.error.message}</p>
      )}
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={handleSave}
          disabled={updateProject.isPending}
          className="rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700 disabled:opacity-50"
        >
          {updateProject.isPending ? "保存中..." : "保存"}
        </button>
        {updateProject.isSuccess && !updateProject.isPending && (
          <span className="text-sm text-green-700">保存しました</span>
        )}
      </div>
    </div>
  );
}
