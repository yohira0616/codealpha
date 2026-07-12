# 見積もりコアロジック

## phase 1(見積もりの作成・保存とLLMとの対話)

* プロジェクト(Project)

* 与えられた要件定義・テキストから作成すべき機能、やるべきタスクを詳細に洗い出す。
* ベースプロンプトを /prompts に作成。プロンプトはmd形式でこのディレクトリで管理。
* まずはPoCとして、claude -p でローカルで動かすようにする。
* 見積もりに対して、LLMとの対話内容を Conversation として保存する。
* Conversation の結果を前提に、下の「標準見積もりの作成」で見積もりを作成できるようにする。
* Project has many conversation, Project has many task, conversation has many task
* 将来的にはプロジェクトごとにwikiなどを作成できるようにするが後で良い

## 標準見積もりの作成

* タスクから、標準的なエンジニアの人日・価格で見積もりを作成する。一旦テーブルは分けずにTaskにプロパティ入れる方針で。
* eslimated_by で 人日や価格を変更したのがユーザーかLLMかわかるようにする。
* 特に要件に指定がなければ、 React SPA + バックエンドRailsでの構成を基本とする。

---

## PoC設計 v0.1(2026-07-12 決定)

### 決定事項

| 論点 | 決定 |
|---|---|
| claude -p の実行方式 | Solid Queue で非同期実行。フロントは TanStack Query のポーリングで結果取得 |
| 対話ログ | Message テーブル(Conversation has_many :messages) |
| スコープ | UI込みの3画面(一覧 / 詳細+対話 / タスク見積もり編集) |

### データモデル

```text
Project        name, client_name, requirement_text, daily_rate(円/人日, 既定50,000), status
  ├── has_many :conversations
  └── has_many :tasks

Conversation   project_id, title,
               status: pending / running / completed / failed,
               claude_session_id(claude -p --resume 用)
  ├── has_many :messages
  └── has_many :tasks

Message        conversation_id, role(user / assistant), content

Task           project_id, conversation_id,
               title, description, category(認証/CRUD/外部API連携/決済/管理画面/バッチ/帳票/その他),
               estimated_days(decimal), estimated_price(integer),
               estimated_by(enum: llm / user), position
```

* 価格は `estimated_days × project.daily_rate` を既定とし、ユーザーが上書きしたら `estimated_by: user`
* 単価の既定 50,000円/人日 は議事録の相場(90〜120万円/人月 ÷ 20営業日)の下限に置いた仮値

### claude -p 実行フロー

```text
POST /api/conversations/:id/messages
  1. Message(role: user) を保存、Conversation.status = pending
  2. ConversationReplyJob を enqueue して即レスポンス
  3. ジョブ内:
     - prompts/*.md + 要件テキスト + 対話履歴からプロンプトを組み立て
     - claude -p --output-format json を Open3 で実行
       (2回目以降は --resume <claude_session_id>)
     - 応答全文を Message(role: assistant) として保存
     - 応答中のJSONブロック(タスク配列)をパースして Task を洗い替え
     - status = completed(パース不能・プロセス失敗時は failed)
フロント: status が pending/running の間 refetchInterval でポーリング
```

* claude はツール実行不要のため、ファイル操作等を許可しないフラグ構成で起動する
* JSON出力形式(例): `{"tasks": [{"title", "description", "category", "estimated_days"}]}`
  をプロンプト側で指示。パースに失敗しても対話自体は Message に残るので壊れない

### prompts/

```text
prompts/
├── task_breakdown.md   # 要件テキスト → 機能・タスク洗い出し(JSON出力指示を含む)
└── estimate.md         # タスク一覧 → 標準エンジニア(実務3年)の人日付け
```

* プレースホルダ(%{requirement} 等)の単純置換で開始。テンプレートエンジンは入れない
* %{references} プレースホルダに references/ 直下の *.md(IPA基準値などの参照データ)を連結して注入する。人日設定は参照データ優先・中央値ベースをプロンプトで指示

### API

```text
GET  /api/projects                        一覧
POST /api/projects                        作成
GET  /api/projects/:id                    詳細(tasks, conversations 含む)
PATCH /api/projects/:id                   要件テキスト等の更新
POST /api/projects/:id/conversations      対話開始(初回メッセージ付き)
GET  /api/conversations/:id               メッセージ+status(ポーリング先)
POST /api/conversations/:id/messages      発言追加 → ジョブ投入
PATCH /api/tasks/:id                      人日・価格の手動編集(estimated_by: user に)
```

### 画面(ワイヤー SCREEN 01〜03 対応)

1. **ProjectsPage** — プロジェクト一覧+新規作成
2. **ProjectDetailPage** — 要件テキスト編集+対話(チャット表示、実行中インジケータ)
3. タスク見積もりテーブル(詳細ページ内タブでも可)— カテゴリ・人日・価格の編集、合計人日・合計金額の常時表示

### PoC完了条件

* 要件テキストを投入 → 対話でタスクが洗い出され Task として保存される
* 対話を重ねるとタスクが更新される(--resume で文脈維持)
* タスクの人日・価格を手で直せて、LLM推定と区別され、合計が出る

### 実装順

1. マイグレーション+モデル(Project / Conversation / Message / Task)
2. claude -p ラッパー(lib/)+ prompts/ — rails console で単体検証
3. ConversationReplyJob + タスクJSONパース
4. API コントローラ
5. フロント3画面
