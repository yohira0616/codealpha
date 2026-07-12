import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";

import { useCreateProject, useProjects } from "@/hooks/useProjects";

export function ProjectsPage() {
  const { data: projects, isPending, error } = useProjects();
  const createProject = useCreateProject();
  const navigate = useNavigate();

  const [name, setName] = useState("");
  const [clientName, setClientName] = useState("");

  const handleCreate = (e: FormEvent) => {
    e.preventDefault();
    const trimmedName = name.trim();
    if (!trimmedName || createProject.isPending) return;
    createProject.mutate(
      {
        name: trimmedName,
        client_name: clientName.trim() || undefined,
      },
      {
        onSuccess: (project) => {
          setName("");
          setClientName("");
          navigate(`/projects/${project.id}`);
        },
      }
    );
  };

  return (
    <section className="space-y-6">
      <h1 className="text-2xl font-bold">プロジェクト一覧</h1>

      <form
        onSubmit={handleCreate}
        className="flex flex-wrap items-end gap-3 rounded-lg border border-gray-200 bg-white p-4"
      >
        <div>
          <label htmlFor="new-project-name" className="mb-1 block text-xs text-gray-500">
            プロジェクト名
          </label>
          <input
            id="new-project-name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="例: 受発注管理システム"
            className="w-64 rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-gray-500 focus:outline-none"
          />
        </div>
        <div>
          <label htmlFor="new-project-client" className="mb-1 block text-xs text-gray-500">
            顧客名(任意)
          </label>
          <input
            id="new-project-client"
            value={clientName}
            onChange={(e) => setClientName(e.target.value)}
            placeholder="例: A社"
            className="w-48 rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-gray-500 focus:outline-none"
          />
        </div>
        <button
          type="submit"
          disabled={createProject.isPending || !name.trim()}
          className="rounded-md bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-700 disabled:opacity-50"
        >
          {createProject.isPending ? "作成中..." : "新規プロジェクト"}
        </button>
        {createProject.error && (
          <p className="w-full text-sm text-red-600">
            {createProject.error.message}
          </p>
        )}
      </form>

      {isPending && <p className="text-gray-500">読み込み中...</p>}
      {error && <p className="text-red-600">{error.message}</p>}

      {projects && (
        <div className="overflow-x-auto rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-200 bg-gray-50 text-left text-xs text-gray-500">
                <th className="px-4 py-2 font-medium">名前</th>
                <th className="px-4 py-2 font-medium">顧客</th>
                <th className="px-4 py-2 font-medium">状態</th>
                <th className="px-4 py-2 text-right font-medium">合計人日</th>
                <th className="px-4 py-2 text-right font-medium">合計金額</th>
                <th className="px-4 py-2 font-medium">更新日</th>
              </tr>
            </thead>
            <tbody>
              {projects.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-4 py-6 text-center text-gray-500">
                    プロジェクトはまだありません。上のフォームから作成してください。
                  </td>
                </tr>
              )}
              {projects.map((project) => (
                <tr
                  key={project.id}
                  onClick={() => navigate(`/projects/${project.id}`)}
                  className="cursor-pointer border-b border-gray-100 last:border-b-0 hover:bg-gray-50"
                >
                  <td className="px-4 py-2 font-medium text-gray-900">
                    {project.name}
                  </td>
                  <td className="px-4 py-2">{project.client_name ?? "—"}</td>
                  <td className="px-4 py-2">
                    <span className="inline-block rounded-full border border-gray-300 bg-gray-50 px-2 py-0.5 text-xs text-gray-600">
                      {project.status}
                    </span>
                  </td>
                  <td className="px-4 py-2 text-right tabular-nums">
                    {project.total_estimated_days.toLocaleString()}
                  </td>
                  <td className="px-4 py-2 text-right tabular-nums">
                    {project.total_estimated_price.toLocaleString()}円
                  </td>
                  <td className="px-4 py-2 tabular-nums text-gray-600">
                    {new Date(project.updated_at).toLocaleDateString("ja-JP")}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  );
}
