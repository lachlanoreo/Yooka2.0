module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :credential_id

    def connect
      self.credential_id = BasecampCredential.current&.id || reject_unauthorized_connection
    end
  end
end
