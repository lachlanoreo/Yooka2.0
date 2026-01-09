class CreateBasecampCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :basecamp_credentials do |t|
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at
      t.string :account_id

      t.timestamps
    end
  end
end
