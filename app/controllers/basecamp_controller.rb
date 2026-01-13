class BasecampController < ApplicationController
  def sync
    credential = BasecampCredential.current

    unless credential.present?
      respond_to do |format|
        format.html { redirect_to plan_path, alert: "Basecamp not connected" }
        format.json { render json: { error: "Basecamp not connected" }, status: :unprocessable_entity }
      end
      return
    end

    # Enqueue background job (returns immediately)
    BasecampSyncJob.perform_later(broadcast_progress: true)

    respond_to do |format|
      format.html { redirect_to plan_path, notice: "Sync started..." }
      format.json { render json: { status: "started", credential_id: credential.id }, status: :ok }
    end
  end
end
