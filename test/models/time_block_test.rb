require "test_helper"

class TimeBlockTest < ActiveSupport::TestCase
  test "valid time block" do
    task = tasks(:inbox_task)
    block = TimeBlock.new(task: task, date: Date.current, start_minutes: 420, duration_minutes: 30)
    assert block.valid?
  end

  test "requires task" do
    block = TimeBlock.new(date: Date.current, start_minutes: 420, duration_minutes: 30)
    assert_not block.valid?
    assert_includes block.errors[:task], "must exist"
  end

  test "requires date" do
    task = tasks(:inbox_task)
    block = TimeBlock.new(task: task, start_minutes: 420, duration_minutes: 30)
    assert_not block.valid?
    assert_includes block.errors[:date], "can't be blank"
  end

  test "requires start_minutes" do
    task = tasks(:inbox_task)
    block = TimeBlock.new(task: task, date: Date.current, duration_minutes: 30)
    assert_not block.valid?
    assert_includes block.errors[:start_minutes], "can't be blank"
  end

  test "requires duration_minutes" do
    task = tasks(:inbox_task)
    block = TimeBlock.new(task: task, date: Date.current, start_minutes: 420, duration_minutes: nil)
    assert_not block.valid?
  end

  test "end_minutes calculates correctly" do
    block = time_blocks(:morning_block)
    assert_equal 450, block.end_minutes # 420 + 30
  end

  test "start_time formats correctly" do
    block = time_blocks(:morning_block)
    assert_equal "07:00", block.start_time
  end

  test "end_time formats correctly" do
    block = time_blocks(:morning_block)
    assert_equal "07:30", block.end_time
  end

  test "snaps start_minutes to 5-minute increments" do
    task = tasks(:inbox_task)
    block = TimeBlock.create!(task: task, date: Date.current + 1, start_minutes: 423, duration_minutes: 30)
    assert_equal 425, block.start_minutes
  end

  test "snaps duration_minutes to 5-minute increments" do
    task = tasks(:inbox_task)
    block = TimeBlock.create!(task: task, date: Date.current + 1, start_minutes: 420, duration_minutes: 33)
    assert_equal 35, block.duration_minutes
  end

  test "clamps duration to not exceed day end" do
    task = tasks(:inbox_task)
    # Start at 7:30 PM (1170 minutes), try 60 min duration
    block = TimeBlock.create!(task: task, date: Date.current + 1, start_minutes: 1170, duration_minutes: 60)
    # Should be clamped to 30 minutes (to end at 8:00 PM / 1200)
    assert_equal 30, block.duration_minutes
  end

  test "overlaps_with? detects overlapping blocks" do
    block = time_blocks(:morning_block) # 420-450

    assert block.overlaps_with?(430, 460) # Overlaps start
    assert block.overlaps_with?(400, 440) # Overlaps end
    assert block.overlaps_with?(425, 445) # Inside
    assert block.overlaps_with?(400, 500) # Encompasses

    assert_not block.overlaps_with?(450, 480) # Adjacent after
    assert_not block.overlaps_with?(390, 420) # Adjacent before
    assert_not block.overlaps_with?(500, 530) # No overlap
  end

  test "move_to updates start_minutes with snapping" do
    block = time_blocks(:morning_block)
    block.move_to(483)
    assert_equal 485, block.reload.start_minutes
  end

  test "resize_to updates duration_minutes" do
    block = time_blocks(:morning_block)
    block.resize_to(45)
    assert_equal 45, block.reload.duration_minutes
  end

  test "resize_to enforces minimum duration" do
    block = time_blocks(:morning_block)
    block.resize_to(2)
    assert_equal 5, block.reload.duration_minutes
  end

  test "task can only have one time_block per date" do
    existing = time_blocks(:morning_block)
    duplicate = TimeBlock.new(
      task: existing.task,
      date: existing.date,
      start_minutes: 500,
      duration_minutes: 30
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:task_id], "has already been taken"
  end

  test "for_date scope filters by date" do
    block = time_blocks(:morning_block)
    assert_includes TimeBlock.for_date(Date.current), block
    assert_not_includes TimeBlock.for_date(Date.current + 1), block
  end
end
