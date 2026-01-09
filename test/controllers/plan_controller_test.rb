require "test_helper"

class PlanControllerTest < ActionDispatch::IntegrationTest
  test "should get plan page" do
    get plan_path
    assert_response :success
  end

  test "plan page shows all task groups" do
    get plan_path
    assert_response :success

    Task::GROUPS.each do |group|
      assert_select "#task-group-#{group}"
    end
  end

  test "plan page shows inbox as visually distinct" do
    get plan_path
    assert_response :success

    # Inbox should have special styling
    assert_select "#task-group-inbox.task-group--inbox"
  end

  test "plan page shows today group as visually distinct" do
    get plan_path
    assert_response :success

    # Today should have special styling
    assert_select "#task-group-today.task-group--today"
  end

  test "plan page shows completed tasks section" do
    get plan_path
    assert_response :success

    assert_select "#completed-section"
  end

  test "plan page shows daily goal" do
    get plan_path
    assert_response :success

    assert_select "[data-controller='daily-goal']"
  end

  test "plan page shows day view calendar" do
    get plan_path
    assert_response :success

    assert_select "[data-controller='day-view']"
  end
end
