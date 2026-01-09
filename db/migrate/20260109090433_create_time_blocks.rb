class CreateTimeBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :time_blocks do |t|
      t.references :task, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :start_minutes, null: false
      t.integer :duration_minutes, null: false, default: 30

      t.timestamps
    end

    add_index :time_blocks, [:date, :start_minutes]
    add_index :time_blocks, [:task_id, :date], unique: true
  end
end
