class CalendarController < ApplicationController
  def events
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    service = GoogleCalendarService.new

    if service.connected?
      @events = service.fetch_events_for_date(date)
      render json: @events
    else
      render json: []
    end
  end
end
