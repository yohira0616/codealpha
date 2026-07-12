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