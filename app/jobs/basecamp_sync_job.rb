class BasecampSyncJob < ApplicationJob
  queue_as :default

  def perform
    return unless BasecampCredential.current.present?

    Rails.logger.info "BasecampSyncJob: Starting automatic sync"
    service = BasecampService.new
    count = service.sync_todos_assigned_to_me
    Rails.logger.info "BasecampSyncJob: Synced #{count} tasks"
  rescue => e
    Rails.logger.error "BasecampSyncJob failed: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
  end
end
