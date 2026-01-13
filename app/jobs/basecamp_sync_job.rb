class BasecampSyncJob < ApplicationJob
  queue_as :default

  def perform(broadcast_progress: true)
    credential = BasecampCredential.current
    return unless credential.present?

    Rails.logger.info "BasecampSyncJob: Starting sync"

    service = BasecampService.new
    count = service.sync_todos_assigned_to_me(broadcast_progress: broadcast_progress)
    Rails.logger.info "BasecampSyncJob: Synced #{count} tasks"
  rescue => e
    Rails.logger.error "BasecampSyncJob failed: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")

    # Broadcast failure to UI
    if broadcast_progress && credential
      ActionCable.server.broadcast(
        "basecamp_sync:#{credential.id}",
        { type: "sync_failed", message: e.message }
      )
    end
  end
end
