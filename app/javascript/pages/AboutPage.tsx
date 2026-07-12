export function AboutPage() {
  return (
    <section className="space-y-4">
      <h1 className="text-2xl font-bold">About</h1>
      <p className="text-gray-600">
        このページは React Router のクライアントサイドルーティングで表示されています。
        URL 直打ちやリロードでも、Rails 側の catch-all ルート(config/routes.rb)が
        SPA の HTML を返すため同じ画面が表示されます。
      </p>
    </section>
  );
}
