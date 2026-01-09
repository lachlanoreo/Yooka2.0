require "test_helper"

class DailyGoalTest < ActiveSupport::TestCase
  test "valid daily goal" do
    goal = DailyGoal.new(date: Date.current + 1, content: "Test goal")
    assert goal.valid?
  end

  test "requires date" do
    goal = DailyGoal.new(content: "Test goal")
    assert_not goal.valid?
    assert_includes goal.errors[:date], "can't be blank"
  end

  test "date must be unique" do
    existing = daily_goals(:today_goal)
    duplicate = DailyGoal.new(date: existing.date, content: "Another goal")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:date], "has already been taken"
  end

  test "for_date finds existing goal" do
    existing = daily_goals(:today_goal)
    goal = DailyGoal.for_date(Date.current)
    assert_equal existing.id, goal.id
  end

  test "for_date creates goal if not exists" do
    future_date = Date.current + 10
    assert_nil DailyGoal.find_by(date: future_date)

    goal = DailyGoal.for_date(future_date)

    assert_not_nil goal.id
    assert_equal future_date, goal.date
  end

  test "content can be blank" do
    goal = DailyGoal.new(date: Date.current + 2)
    assert goal.valid?
  end
end
