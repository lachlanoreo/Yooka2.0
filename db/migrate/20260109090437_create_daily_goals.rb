class CreateDailyGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_goals do |t|
      t.date :date
      t.text :content

      t.timestamps
    end
    add_index :daily_goals, :date, unique: true
  end
end
