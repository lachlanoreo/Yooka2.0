class BasecampSyncChannel < ApplicationCable::Channel
  def subscribed
    stream_from "basecamp_sync:#{credential_id}"
  end

  def unsubscribed
    # Cleanup if needed
  end
end
