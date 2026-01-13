class PlanController < ApplicationController
  def show
    @tasks_by_group = Task::GROUPS.index_with do |group|
      Task.active.incomplete.in_group(group).ordered
    end
    @completed_tasks = Task.active.completed.order(completed_at: :desc)

    # Calendar data for today
    @viewed_date = Date.current
    @frozen = false
    load_calendar_data(@viewed_date)

    # Integrations
    google_service = GoogleCalendarService.new
    @google_connected = google_service.connected?
    @basecamp_connected = BasecampCredential.current.present?
  end

  def calendar
    @viewed_date = parse_date(params[:date])
    @frozen = @viewed_date < Date.current
    load_calendar_data(@viewed_date)

    render partial: "plan/calendar_frame", locals: {
      viewed_date: @viewed_date,
      daily_goal: @daily_goal,
      time_blocks: @time_blocks,
      google_events: @google_events,
      frozen: @frozen
    }
  end

  private

  def parse_date(date_param)
    Date.parse(date_param)
  rescue ArgumentError, TypeError
    Date.current
  end

  def load_calendar_data(date)
    @daily_goal = DailyGoal.for_date(date)
    @time_blocks = TimeBlock.for_date(date).includes(:task)

    # Only fetch Google events for current/future dates
    if date >= Date.current
      google_service = GoogleCalendarService.new
      @google_events = google_service.connected? ? google_service.fetch_events_for_date(date) : []
    else
      @google_events = []
    end
  end
end
