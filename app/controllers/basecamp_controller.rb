class BasecampController < ApplicationController
  def sync
    service = BasecampService.new

    if service.connected?
      count = service.sync_todos_assigned_to_me
      redirect_to plan_path, notice: "Synced #{count} tasks from Basecamp"
    else
      redirect_to plan_path, alert: "Basecamp not connected"
    end
  end
end
