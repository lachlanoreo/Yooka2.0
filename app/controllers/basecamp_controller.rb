class BasecampController < ApplicationController
  def sync
    service = BasecampService.new

    if service.connected?
      count = service.sync_todos_assigned_to_me

      if count > 0
        redirect_to plan_path, notice: "Synced #{count} tasks from Basecamp"
      else
        redirect_to plan_path, notice: "No tasks assigned to you found in Basecamp"
      end
    else
      redirect_to plan_path, alert: "Basecamp not connected"
    end
  rescue => e
    Rails.logger.error "Basecamp sync error: #{e.message}"
    redirect_to plan_path, alert: "Failed to sync: #{e.message}"
  end
end
