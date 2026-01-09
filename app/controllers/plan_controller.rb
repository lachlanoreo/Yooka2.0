class PlanController < ApplicationController
  def show
    @tasks_by_group = Task::GROUPS.index_with do |group|
      Task.active.incomplete.in_group(group).ordered
    end
    @completed_tasks = Task.active.completed.order(completed_at: :desc)
    @daily_goal = DailyGoal.for_date(Date.current)
    @time_blocks = TimeBlock.for_date(Date.current).includes(:task)

    # Google Calendar integration
    google_service = GoogleCalendarService.new
    @google_connected = google_service.connected?
    @google_events = @google_connected ? google_service.fetch_events_for_date(Date.current) : []

    # Basecamp integration
    @basecamp_connected = BasecampCredential.current.present?
  end
end
