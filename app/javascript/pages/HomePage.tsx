import { useHealth } from "@/hooks/useHealth";

export function HomePage() {
  const { data, isPending, error } = useHealth();

  return (
    <section className="space-y-4">
      <h1 className="text-2xl font-bold">Home</h1>
      <p className="text-gray-600">
        React SPA + Rails REST API の開発基盤です。下のカードは
        TanStack Query 経由で Rails の API を呼んだ結果を表示しています。
      </p>
      <div className="rounded-lg border border-gray-200 bg-white p-4">
        <h2 className="mb-2 font-semibold">GET /api/health</h2>
        {isPending && <p className="text-gray-500">Loading...</p>}
        {error && <p className="text-red-600">{error.message}</p>}
        {data && (
          <dl className="grid grid-cols-[8rem_1fr] gap-y-1 text-sm">
            <dt className="text-gray-500">status</dt>
            <dd>{data.status}</dd>
            <dt className="text-gray-500">rails_env</dt>
            <dd>{data.rails_env}</dd>
            <dt className="text-gray-500">time</dt>
            <dd>{data.time}</dd>
          </dl>
        )}
      </div>
    </section>
  );
}
