class DailyGoal < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  def self.for_date(date)
    find_or_create_by(date: date)
  end
end
