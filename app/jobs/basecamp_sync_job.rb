class BasecampSyncJob < ApplicationJob
  queue_as :default

  def perform
    service = BasecampService.new
    return unless service.connected?

    service.sync_todos_assigned_to_me
  end
end
