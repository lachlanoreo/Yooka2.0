require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid task" do
    task = Task.new(title: "Test task", source: "personal", group: "inbox")
    assert task.valid?
  end

  test "requires title" do
    task = Task.new(source: "personal", group: "inbox")
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "validates source inclusion" do
    task = Task.new(title: "Test", source: "invalid", group: "inbox")
    assert_not task.valid?
    assert_includes task.errors[:source], "is not included in the list"
  end

  test "validates group inclusion" do
    task = Task.new(title: "Test", source: "personal", group: "invalid")
    assert_not task.valid?
    assert_includes task.errors[:group], "is not included in the list"
  end

  test "personal? returns true for personal tasks" do
    task = tasks(:inbox_task)
    assert task.personal?
    assert_not task.basecamp?
  end

  test "basecamp? returns true for basecamp tasks" do
    task = tasks(:basecamp_task)
    assert task.basecamp?
    assert_not task.personal?
  end

  test "completed? returns true when completed_at is set" do
    task = tasks(:completed_task)
    assert task.completed?
  end

  test "complete! sets completed_at" do
    task = tasks(:inbox_task)
    assert_nil task.completed_at
    task.complete!
    assert_not_nil task.completed_at
  end

  test "uncomplete! clears completed_at" do
    task = tasks(:completed_task)
    task.uncomplete!
    assert_nil task.completed_at
  end

  test "archived? returns true when archived_at is set" do
    task = tasks(:archived_task)
    assert task.archived?
  end

  test "archive! sets archived_at" do
    task = tasks(:inbox_task)
    task.archive!
    assert_not_nil task.archived_at
  end

  test "active scope excludes archived tasks" do
    active_tasks = Task.active
    assert_not_includes active_tasks, tasks(:archived_task)
    assert_includes active_tasks, tasks(:inbox_task)
  end

  test "in_group scope filters by group" do
    inbox_tasks = Task.in_group("inbox")
    assert_includes inbox_tasks, tasks(:inbox_task)
    assert_not_includes inbox_tasks, tasks(:today_task)
  end

  test "sets position automatically on create" do
    task = Task.create!(title: "New task", source: "personal", group: "inbox")
    assert task.position >= 0
  end

  test "move_to_group changes group" do
    task = tasks(:inbox_task)
    task.move_to_group("today")
    assert_equal "today", task.reload.group
  end

  test "move_to_group creates time_block when moving to today" do
    task = tasks(:inbox_task)
    assert_nil task.time_block

    task.move_to_group("today")

    assert_not_nil task.reload.time_block
    assert_equal Date.current, task.time_block.date
    assert_equal 30, task.time_block.duration_minutes
  end

  test "move_to_group deletes time_block when moving out of today" do
    task = tasks(:today_task)
    # Ensure time_block exists
    task.create_time_block!(date: Date.current, start_minutes: 420, duration_minutes: 30) unless task.time_block

    task.move_to_group("inbox")

    assert_nil task.reload.time_block
  end

  test "move_to_position reorders tasks within group" do
    task1 = Task.create!(title: "Task 1", source: "personal", group: "computer")
    task2 = Task.create!(title: "Task 2", source: "personal", group: "computer")
    task3 = Task.create!(title: "Task 3", source: "personal", group: "computer")

    assert_equal 0, task1.position
    assert_equal 1, task2.position
    assert_equal 2, task3.position

    task3.move_to_position(0)

    assert_equal 0, task3.reload.position
    assert_equal 1, task1.reload.position
    assert_equal 2, task2.reload.position
  end

  test "basecamp_todo_id must be unique" do
    existing = tasks(:basecamp_task)
    duplicate = Task.new(
      title: "Duplicate",
      source: "basecamp",
      group: "inbox",
      basecamp_todo_id: existing.basecamp_todo_id
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:basecamp_todo_id], "has already been taken"
  end
end
