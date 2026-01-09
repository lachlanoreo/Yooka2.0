class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.string :source, null: false, default: "personal"
      t.string :group, null: false, default: "inbox"
      t.integer :position, null: false, default: 0
      t.date :due_date
      t.datetime :completed_at
      t.datetime :archived_at
      t.string :basecamp_todo_id
      t.string :basecamp_project_id
      t.string :basecamp_url

      t.timestamps
    end

    add_index :tasks, [:group, :position]
    add_index :tasks, :basecamp_todo_id, unique: true, where: "basecamp_todo_id IS NOT NULL"
    add_index :tasks, :archived_at
    add_index :tasks, :completed_at
  end
end
