class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title
      t.string :status, null: false, default: "pending"
      t.string :claude_session_id

      t.timestamps
    end
  end
end
