require "test_helper"

class TimeBlocksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @time_block = time_blocks(:morning_block)
  end

  test "should update time block position" do
    patch time_block_path(@time_block),
      params: { start_minutes: 480, duration_minutes: 45 },
      headers: { "Content-Type" => "application/json" },
      as: :json

    assert_response :success
    @time_block.reload
    assert_equal 480, @time_block.start_minutes
    assert_equal 45, @time_block.duration_minutes
  end

  test "should snap time block to 5-minute increments" do
    patch time_block_path(@time_block),
      params: { start_minutes: 483, duration_minutes: 47 },
      headers: { "Content-Type" => "application/json" },
      as: :json

    assert_response :success
    @time_block.reload
    assert_equal 485, @time_block.start_minutes
    assert_equal 45, @time_block.duration_minutes
  end

  test "should clamp time block to day end" do
    # Try to set a block at 7:30 PM (1170 min) with 60 min duration
    # Should be clamped to 30 min to end at 8:00 PM
    patch time_block_path(@time_block),
      params: { start_minutes: 1170, duration_minutes: 60 },
      headers: { "Content-Type" => "application/json" },
      as: :json

    assert_response :success
    @time_block.reload
    assert_equal 1170, @time_block.start_minutes
    assert_equal 30, @time_block.duration_minutes
  end
end
