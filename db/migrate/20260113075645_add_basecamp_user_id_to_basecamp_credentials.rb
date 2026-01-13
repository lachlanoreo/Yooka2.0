class AddBasecampUserIdToBasecampCredentials < ActiveRecord::Migration[8.0]
  def change
    add_column :basecamp_credentials, :basecamp_user_id, :string
  end
end
