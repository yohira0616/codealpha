# codealpha

AI 駆動開発時代の見積もり・採算管理基盤(プロダクト構想・要件は [docs/](docs/) を参照)。

現在は React SPA + Rails REST API の開発基盤を構築済み。

## アーキテクチャ概要

同一オリジンで Rails が SPA と API の両方を配信する構成。

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

- **SPA 配信**: Rails のルーティングに無いパスは `config/routes.rb` 末尾の catch-all が
  SPA の HTML を返して React Router に委譲する(URL 直打ち・リロード対応)
- **API**: `Api::BaseController` が共通エラーハンドリング(`{ error: ... }` JSON、
  404 / 422 / 400)を提供。`/api/health` + フロントの `useHealth` フックが
  新しい API + 画面を追加するときのひな形
- **データ取得**: fetch ラッパー(`lib/api.ts`)→ zod でレスポンス検証(`lib/api/*.ts`)
  → TanStack Query のフック(`hooks/*.ts`)の 3 層構成

## 技術スタック

| レイヤ | 技術 |
|---|---|
| バックエンド | Ruby 3.4 / Rails 8.1(通常モード)/ SQLite + Solid Cache・Queue・Cable |
| フロントエンド | React 19 / TypeScript / React Router v7 |
| ビルド | Vite + vite_rails(フロントのソースは `app/javascript`) |
| CSS | Tailwind CSS v4(`@tailwindcss/vite`、CSS-first 設定) |
| データ取得 | TanStack Query v5 + zod |
| テスト | RSpec(BDD)+ FactoryBot / tsc / RuboCop |
| デプロイ | Docker + Kamal + Thruster |

## セットアップ

```sh
bin/setup   # bundle install + npm install + DB 準備(完了後そのまま bin/dev が起動)
```

## 開発

```sh
bin/dev     # foreman で rails server(:3000)と vite dev(:3036)を同時起動
```

`binding.irb` でデバッグしたい場合は `bin/vite dev` と `bin/rails server` を別ターミナルで起動する。

## テスト・検証

```sh
bin/rspec           # Rails のテスト(RSpec)
npm run typecheck   # TypeScript 型チェック
npm run build       # 型チェック + 本番ビルド確認
bin/rubocop         # Ruby Lint
bin/ci              # 上記一式 + セキュリティ監査(CI と同等)
```

## ドキュメント

- [docs/spa_development.md](docs/spa_development.md) — 開発基盤の詳細
  (ディレクトリ構造、新しい API + 画面の追加手順、設計上の約束事)
- [docs/](docs/) — プロダクト構想・方針決定議事録
