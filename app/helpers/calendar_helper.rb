module CalendarHelper
  # Calculate column positions for overlapping events
  # Returns events with :column and :total_columns added
  def calculate_event_columns(events)
    return events if events.empty?

    # Sort by start time, then by duration (longer events first for tie-breaking)
    sorted = events.sort_by { |e| [e[:start_minutes], -e[:duration_minutes]] }

    # Track end times for each column to find available slots
    columns = []

    sorted.each do |event|
      # Find first column where this event fits (no overlap with existing)
      column_index = columns.index { |col_end| col_end <= event[:start_minutes] }

      if column_index
        # Reuse this column
        columns[column_index] = event[:end_minutes]
      else
        # Need a new column
        column_index = columns.size
        columns << event[:end_minutes]
      end

      event[:column] = column_index
    end

    # Second pass: calculate MAX concurrent events at any point during each event
    sorted.each do |event|
      # Collect all time points within this event's duration
      time_points = [event[:start_minutes]]

      sorted.each do |e|
        # Add start times that fall within this event
        if e[:start_minutes] > event[:start_minutes] && e[:start_minutes] < event[:end_minutes]
          time_points << e[:start_minutes]
        end
        # Add end times that fall within this event
        if e[:end_minutes] > event[:start_minutes] && e[:end_minutes] < event[:end_minutes]
          time_points << e[:end_minutes]
        end
      end

      time_points = time_points.uniq.sort

      # Find max concurrent events at any of these time points
      max_concurrent = time_points.map do |t|
        # Count events active at time t (start <= t < end)
        sorted.count { |e| e[:start_minutes] <= t && e[:end_minutes] > t }
      end.max

      event[:total_columns] = [max_concurrent || 1, 1].max
    end

    sorted
  end
end
