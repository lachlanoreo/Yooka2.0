class GoogleCredential < ApplicationRecord
  validates :access_token, presence: true
  validates :refresh_token, presence: true

  def self.current
    first
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def needs_refresh?
    expires_at.nil? || expires_at < 5.minutes.from_now
  end
end
