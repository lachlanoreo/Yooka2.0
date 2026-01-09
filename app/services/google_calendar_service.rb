require 'google/apis/calendar_v3'

class GoogleCalendarService
  DAY_START_MINUTES = 420  # 7:00 AM
  DAY_END_MINUTES = 1200   # 8:00 PM

  def initialize
    @credential = GoogleCredential.current
  end

  def connected?
    @credential.present? && @credential.access_token.present?
  end

  def fetch_events_for_date(date)
    return [] unless connected?

    refresh_token_if_needed!

    calendar_service = Google::Apis::CalendarV3::CalendarService.new
    calendar_service.authorization = build_authorization

    time_min = date.beginning_of_day.iso8601
    time_max = date.end_of_day.iso8601

    begin
      result = calendar_service.list_events(
        'primary',
        time_min: time_min,
        time_max: time_max,
        single_events: true,
        order_by: 'startTime'
      )

      result.items.filter_map do |event|
        # Skip all-day events (they have date instead of dateTime)
        next if event.start.date.present?

        start_time = event.start.date_time
        end_time = event.end.date_time

        next unless start_time && end_time

        start_minutes = time_to_minutes(start_time)
        end_minutes = time_to_minutes(end_time)

        # Skip events completely outside our day view range
        next if end_minutes <= DAY_START_MINUTES || start_minutes >= DAY_END_MINUTES

        # Clamp to day view bounds
        start_minutes = [start_minutes, DAY_START_MINUTES].max
        end_minutes = [end_minutes, DAY_END_MINUTES].min

        {
          id: event.id,
          title: event.summary || "(No title)",
          start_minutes: start_minutes,
          end_minutes: end_minutes,
          duration_minutes: end_minutes - start_minutes
        }
      end
    rescue Google::Apis::AuthorizationError
      # Token might be invalid, try refreshing
      refresh_token!
      retry
    rescue => e
      Rails.logger.error "Google Calendar error: #{e.message}"
      []
    end
  end

  private

  def time_to_minutes(time)
    time.hour * 60 + time.min
  end

  def build_authorization
    Signet::OAuth2::Client.new(
      access_token: @credential.access_token
    )
  end

  def refresh_token_if_needed!
    return unless @credential.needs_refresh?
    refresh_token!
  end

  def refresh_token!
    return unless @credential.refresh_token.present?

    client = Signet::OAuth2::Client.new(
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      refresh_token: @credential.refresh_token
    )

    client.fetch_access_token!

    @credential.update!(
      access_token: client.access_token,
      expires_at: Time.current + client.expires_in.seconds
    )
  rescue => e
    Rails.logger.error "Failed to refresh Google token: #{e.message}"
  end
end
