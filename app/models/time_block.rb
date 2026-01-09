class TimeBlock < ApplicationRecord
  DAY_START_MINUTES = 420  # 7:00 AM
  DAY_END_MINUTES = 1200   # 8:00 PM
  SNAP_INCREMENT = 5       # 5-minute snapping

  belongs_to :task

  validates :date, presence: true
  validates :start_minutes, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than: 1440
  }
  validates :duration_minutes, presence: true, numericality: {
    only_integer: true,
    greater_than: 0
  }
  validates :task_id, uniqueness: { scope: :date }

  before_validation :snap_to_increment
  before_validation :clamp_to_day_bounds

  scope :for_date, ->(date) { where(date: date) }
  scope :ordered, -> { order(:start_minutes) }

  def end_minutes
    start_minutes + duration_minutes
  end

  def start_time
    hours = start_minutes / 60
    minutes = start_minutes % 60
    format("%02d:%02d", hours, minutes)
  end

  def end_time
    hours = end_minutes / 60
    minutes = end_minutes % 60
    format("%02d:%02d", hours, minutes)
  end

  def overlaps_with?(other_start, other_end)
    start_minutes < other_end && end_minutes > other_start
  end

  def move_to(new_start_minutes, new_duration_minutes = nil)
    new_duration = new_duration_minutes || duration_minutes
    update!(
      start_minutes: snap_value(new_start_minutes),
      duration_minutes: new_duration
    )
  end

  def resize_to(new_duration_minutes)
    update!(duration_minutes: [new_duration_minutes, SNAP_INCREMENT].max)
  end

  private

  def snap_to_increment
    self.start_minutes = snap_value(start_minutes) if start_minutes
    self.duration_minutes = snap_value(duration_minutes) if duration_minutes
  end

  def snap_value(value)
    return value unless value
    (value.to_f / SNAP_INCREMENT).round * SNAP_INCREMENT
  end

  def clamp_to_day_bounds
    return unless start_minutes && duration_minutes

    # Ensure block doesn't extend past day end
    if start_minutes + duration_minutes > DAY_END_MINUTES
      self.duration_minutes = DAY_END_MINUTES - start_minutes
    end

    # Ensure minimum duration
    self.duration_minutes = [duration_minutes, SNAP_INCREMENT].max
  end
end
