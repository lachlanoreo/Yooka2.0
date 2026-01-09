require "test_helper"

class DailyGoalsControllerTest < ActionDispatch::IntegrationTest
  test "should update daily goal" do
    date = Date.current.to_s

    patch daily_goal_path(date),
      params: { content: "My top goal for today" },
      headers: { "Content-Type" => "application/json" },
      as: :json

    assert_response :success

    goal = DailyGoal.find_by(date: Date.current)
    assert_equal "My top goal for today", goal.content
  end

  test "should create daily goal if not exists" do
    future_date = (Date.current + 5).to_s
    assert_nil DailyGoal.find_by(date: future_date)

    patch daily_goal_path(future_date),
      params: { content: "Future goal" },
      headers: { "Content-Type" => "application/json" },
      as: :json

    assert_response :success

    goal = DailyGoal.find_by(date: future_date)
    assert_not_nil goal
    assert_equal "Future goal", goal.content
  end
end
