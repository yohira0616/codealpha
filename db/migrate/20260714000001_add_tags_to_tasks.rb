class AddTagsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :tags, :json, null: false, default: []
  end
end
