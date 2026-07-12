import { Link } from "react-router-dom";

export function NotFoundPage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 bg-gray-50">
      <h1 className="text-4xl font-bold text-gray-900">404</h1>
      <p className="text-gray-600">ページが見つかりません</p>
      <Link to="/" className="text-blue-600 underline hover:text-blue-800">
        ホームへ戻る
      </Link>
    </div>
  );
}
