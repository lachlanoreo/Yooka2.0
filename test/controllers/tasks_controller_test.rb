require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = tasks(:inbox_task)
  end

  test "should create personal task in inbox" do
    assert_difference("Task.count") do
      post tasks_path, params: { title: "New personal task" },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    new_task = Task.last
    assert_equal "New personal task", new_task.title
    assert_equal "personal", new_task.source
    assert_equal "inbox", new_task.group
  end

  test "should complete task" do
    assert_nil @task.completed_at

    patch complete_task_path(@task),
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_not_nil @task.reload.completed_at
  end

  test "should uncomplete task" do
    @task.update!(completed_at: Time.current)

    patch uncomplete_task_path(@task),
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_nil @task.reload.completed_at
  end

  test "should archive task" do
    assert_nil @task.archived_at

    patch archive_task_path(@task),
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_not_nil @task.reload.archived_at
  end

  test "should move task to different group" do
    assert_equal "inbox", @task.group

    patch move_task_path(@task),
      params: { group: "today" },
      headers: { "Accept" => "text/vnd.turbo-stream.html", "Content-Type" => "application/json" },
      as: :json

    assert_response :success
    assert_equal "today", @task.reload.group
  end

  test "should create time block when moving to today" do
    assert_nil @task.time_block
    assert_equal "inbox", @task.group

    patch move_task_path(@task),
      params: { group: "today" },
      headers: { "Accept" => "text/vnd.turbo-stream.html", "Content-Type" => "application/json" },
      as: :json

    assert_response :success
    @task.reload
    assert_equal "today", @task.group
    assert_not_nil @task.time_block
    assert_equal Date.current, @task.time_block.date
  end

  test "should delete time block when moving out of today" do
    today_task = tasks(:today_task)
    # Use existing time_block from fixture or create one if not present
    today_task.time_block || today_task.create_time_block!(date: Date.current, start_minutes: 420, duration_minutes: 30)

    assert_not_nil today_task.time_block

    patch move_task_path(today_task),
      params: { group: "inbox" },
      headers: { "Accept" => "text/vnd.turbo-stream.html", "Content-Type" => "application/json" },
      as: :json

    assert_response :success
    assert_nil today_task.reload.time_block
  end

  test "should reject invalid group" do
    patch move_task_path(@task),
      params: { group: "invalid_group" },
      headers: { "Accept" => "text/vnd.turbo-stream.html", "Content-Type" => "application/json" },
      as: :json

    assert_response :unprocessable_entity
  end

  test "should reorder task" do
    task1 = Task.create!(title: "Task 1", source: "personal", group: "calls")
    task2 = Task.create!(title: "Task 2", source: "personal", group: "calls")
    task3 = Task.create!(title: "Task 3", source: "personal", group: "calls")

    assert_equal 0, task1.position
    assert_equal 1, task2.position
    assert_equal 2, task3.position

    patch reorder_task_path(task3), params: { position: 0 }

    assert_response :success
    assert_equal 0, task3.reload.position
    assert_equal 1, task1.reload.position
    assert_equal 2, task2.reload.position
  end
end
