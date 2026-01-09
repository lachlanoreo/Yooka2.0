class AddCompletedFromGroupToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :completed_from_group, :string
  end
end
