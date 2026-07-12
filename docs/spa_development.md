# React SPA + Rails REST API 開発基盤

reboot プロジェクトの構成を参考にした、同一オリジンの React SPA + Rails REST API 構成。

## 構成概要

```
ブラウザ
  │  GET /(または React Router 管理下のパス)
  ▼
Rails: HomeController#index(空アクション)
  └─ layouts/application.html.erb が vite_javascript_tag "application.tsx" を読み込み
       └─ React が div#root にマウント → 以降の画面遷移は React Router
  │  GET/POST/... /api/*(JSON)
  ▼
Rails: namespace :api のコントローラ(Api::BaseController 継承)
```

- **フロントエンド**: React 19 + TypeScript + React Router v7(`BrowserRouter` + JSX ルート宣言)
- **ビルド**: Vite + `vite_rails` gem(ソースは `app/javascript`、`config/vite.json` で指定)
- **CSS**: Tailwind CSS v4(`@tailwindcss/vite` プラグイン。設定は `entrypoints/application.css` に CSS-first で記述、`tailwind.config.js` は無い)
- **データ取得**: TanStack Query v5 + fetch ラッパー(`lib/api.ts`)+ zod でレスポンス検証
- **バックエンド**: Rails 8.1(通常モード)の REST API。`Api::BaseController` が CSRF スキップと共通エラーハンドリング(`{ error: ... }` 形式)を提供

## 起動

```sh
bin/dev          # foreman で rails server(:3000)と vite dev(:3036)を同時起動
```

`binding.irb` でデバッグしたい場合は別々に起動する:

```sh
bin/vite dev     # ターミナル1
bin/rails server # ターミナル2
```

vite dev server が起動していなくても、`config/vite.json` の `autoBuild: true` により
リクエスト時に自動ビルドされる(HMR は効かない)。

## ディレクトリ構造(フロントエンド)

```
app/javascript/
├── entrypoints/
│   ├── application.tsx   # エントリポイント。Provider ツリーとルート定義を持つ
│   └── application.css   # Tailwind v4 のエントリ(@import "tailwindcss")
├── components/
│   └── layout/Layout.tsx # 共通レイアウト(ヘッダー + <Outlet />)
├── pages/                # ページコンポーネント(HomePage, AboutPage, NotFoundPage)
├── hooks/                # TanStack Query のフック層(useHealth.ts)
├── lib/
│   ├── api.ts            # fetch ラッパー(get/post/put/patch/delete、ApiError)
│   ├── api/              # リソース別 API 層(health.ts)。zod でレスポンス検証
│   └── utils.ts          # cn()(clsx + tailwind-merge)
├── types/                # zod スキーマ + 型(health.ts)
└── helpers/query_client.ts
```

パスエイリアス `@/` → `app/javascript/`(`vite.config.ts` と `tsconfig.json` の両方に定義)。

## 新しい API + 画面を追加する手順

`/api/health` + HomePage の実装がひな形。

1. **ルート**: `config/routes.rb` の `namespace :api` に追加
2. **コントローラ**: `app/controllers/api/` 配下に `Api::BaseController` を継承して作成
3. **型**: `app/javascript/types/xxx.ts` に zod スキーマと型を定義
4. **API 層**: `app/javascript/lib/api/xxx.ts` で `api.get()` 等を呼び、zod で `parse`
5. **フック**: `app/javascript/hooks/useXxx.ts` で `useQuery` / `useMutation` にラップ
6. **ページ**: `app/javascript/pages/XxxPage.tsx` を作り、`entrypoints/application.tsx` の
   `<Routes>` に `<Route>` を追加

React Router に追加したパスは Rails 側の設定不要(routes.rb 末尾の catch-all が
`home#index` に流すため、URL 直打ち・リロードでも SPA が表示される)。

## Rails 側の約束事

- SPA 配信: `HomeController#index` + catch-all ルート(`format: false` 付きなので
  `/users/john.doe` のようなドット入りパスもマッチする)。catch-all は
  `XHR でない / /api/・/rails/ 以外 / HTML を受け入れる(Accept 未指定・*/* 含む)` リクエストのみマッチし、
  JSON など非 HTML を明示するリクエストは 404 になる
- API は `Api::BaseController` を継承する
  - CSRF 検証はスキップ済み(フロントは将来の有効化に備え X-CSRF-Token を送っている)
  - `RecordNotFound` → 404、`RecordInvalid` → 422、`ParameterMissing` → 400 を
    `{ error: ... }` JSON で返す
- 認証は未導入。導入時は reboot(devise_token_auth + AuthContext)を参照

## 検証コマンド

```sh
npm run typecheck   # tsc -b
npm run build       # tsc -b && vite build(本番ビルド確認)
bin/rspec           # RSpec(request/model/job スペック。spec/ 配下、FactoryBot 使用)
bin/rubocop
```

## reboot との主な差分(意図的な簡略化)

| 項目 | reboot | codealpha |
|---|---|---|
| Tailwind ビルド | tailwindcss-rails gem(watch プロセス)+ Propshaft 配信 | `@tailwindcss/vite` で Vite に一本化(HMR が効く) |
| 認証 | devise_token_auth + AuthContext | なし |
| SPA エントリ | application.tsx / admin.tsx の2本 | application.tsx の1本 |
| UI | shadcn/ui + Radix | 素の Tailwind(必要になったら追加) |
| i18n / toast / ErrorBoundary | あり | なし(必要になったら追加) |
| API シリアライズ | active_model_serializers | `render json:` 直書き |
| Hotwire(Turbo/Stimulus/importmap) | gem は残存 | 削除済み |
