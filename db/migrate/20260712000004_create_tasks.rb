class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.references :conversation, null: true, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :category
      t.decimal :estimated_days, precision: 6, scale: 1
      t.integer :estimated_price
      t.string :estimated_by, null: false, default: "llm"
      t.integer :position

      t.timestamps
    end
  end
end
