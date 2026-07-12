class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.string :client_name
      t.text :requirement_text
      t.integer :daily_rate, null: false, default: 50000
      t.string :status, null: false, default: "draft"

      t.timestamps
    end
  end
end
