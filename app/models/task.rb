class Task < ApplicationRecord
  GROUPS = %w[inbox today computer calls outside home waiting_for someday].freeze
  SOURCES = %w[personal basecamp].freeze

  has_one :time_block, dependent: :destroy

  validates :title, presence: true
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :group, presence: true, inclusion: { in: GROUPS }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :basecamp_todo_id, uniqueness: true, allow_nil: true

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :incomplete, -> { where(completed_at: nil) }
  scope :in_group, ->(group) { where(group: group) }
  scope :ordered, -> { order(:position) }
  scope :personal, -> { where(source: "personal") }
  scope :basecamp, -> { where(source: "basecamp") }

  before_create :set_position

  def personal?
    source == "personal"
  end

  def basecamp?
    source == "basecamp"
  end

  def completed?
    completed_at.present?
  end

  def archived?
    archived_at.present?
  end

  def complete!
    update!(completed_at: Time.current, completed_from_group: group)
  end

  def uncomplete!
    original_group = completed_from_group || "inbox"
    transaction do
      update!(completed_at: nil, completed_from_group: nil)
      move_to_group(original_group) unless group == original_group
    end
  end

  def archive!
    update!(archived_at: Time.current)
    time_block&.destroy
  end

  def move_to_group(new_group)
    return if new_group == group

    old_group = group
    transaction do
      # Remove time block if moving out of today
      if old_group == "today" && new_group != "today"
        time_block&.destroy
      end

      # Set position to end of new group
      max_position = Task.active.in_group(new_group).maximum(:position) || -1
      update!(group: new_group, position: max_position + 1)

      # Create time block if moving to today
      if new_group == "today" && old_group != "today"
        create_time_block_for_today
      end

      # Reorder old group to fill gaps
      reorder_group(old_group)
    end
  end

  def move_to_position(new_position)
    return if new_position == position

    transaction do
      tasks_in_group = Task.active.in_group(group).where.not(id: id).ordered.to_a
      tasks_in_group.insert(new_position, self)
      tasks_in_group.each_with_index do |task, index|
        Task.where(id: task.id).update_all(position: index)
      end
    end
  end

  private

  def set_position
    return if position_changed? && position != 0
    self.position = (Task.active.in_group(group).maximum(:position) || -1) + 1
  end

  def reorder_group(group_name)
    Task.active.in_group(group_name).ordered.each_with_index do |task, index|
      task.update_column(:position, index) if task.position != index
    end
  end

  def create_time_block_for_today
    # Find earliest available slot starting from 07:00 (420 minutes)
    start_of_day = 420 # 7:00 AM in minutes
    end_of_day = 1200  # 8:00 PM in minutes
    duration = 30

    # Get existing time blocks for today
    existing_blocks = TimeBlock.where(date: Date.current).order(:start_minutes)

    # Get Google Calendar events for today (placeholder - will be implemented later)
    google_events = fetch_google_events_for_today

    # Find first available slot
    current_time = start_of_day
    available_start = nil

    while current_time + duration <= end_of_day
      slot_end = current_time + duration

      # Check if slot conflicts with any existing block
      conflict = existing_blocks.any? do |block|
        block_end = block.start_minutes + block.duration_minutes
        current_time < block_end && slot_end > block.start_minutes
      end

      # Check if slot conflicts with any Google Calendar event
      conflict ||= google_events.any? do |event|
        current_time < event[:end_minutes] && slot_end > event[:start_minutes]
      end

      unless conflict
        available_start = current_time
        break
      end

      current_time += 5 # Move by 5-minute increments
    end

    # Default to start of day if no slot found
    available_start ||= start_of_day

    create_time_block!(
      date: Date.current,
      start_minutes: available_start,
      duration_minutes: duration
    )
  end

  def fetch_google_events_for_today
    service = GoogleCalendarService.new
    return [] unless service.connected?

    service.fetch_events_for_date(Date.current).map do |event|
      { start_minutes: event[:start_minutes], end_minutes: event[:end_minutes] }
    end
  rescue => e
    Rails.logger.error "Error fetching Google events: #{e.message}"
    []
  end
end
