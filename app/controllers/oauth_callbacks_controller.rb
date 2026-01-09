class OauthCallbacksController < ApplicationController
  def google
    auth = request.env['omniauth.auth']

    credential = GoogleCredential.first_or_initialize
    credential.update!(
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token || credential.refresh_token,
      expires_at: Time.at(auth.credentials.expires_at)
    )

    redirect_to plan_path, notice: "Google Calendar connected successfully!"
  end

  def basecamp
    # Basecamp OAuth callback - handled via manual OAuth flow
    code = params[:code]
    return redirect_to plan_path, alert: "No authorization code received" unless code

    # Exchange code for token
    response = Faraday.post('https://launchpad.37signals.com/authorization/token') do |req|
      req.params = {
        type: 'web_server',
        code: code,
        client_id: ENV['BASECAMP_CLIENT_ID'],
        client_secret: ENV['BASECAMP_CLIENT_SECRET'],
        redirect_uri: "#{request.base_url}/auth/basecamp/callback"
      }
    end

    unless response.success?
      return redirect_to plan_path, alert: "Failed to exchange authorization code"
    end

    token_data = JSON.parse(response.body)

    # Get account info to find the account ID
    auth_response = Faraday.get('https://launchpad.37signals.com/authorization.json') do |req|
      req.headers['Authorization'] = "Bearer #{token_data['access_token']}"
    end

    unless auth_response.success?
      return redirect_to plan_path, alert: "Failed to get Basecamp account info"
    end

    auth_data = JSON.parse(auth_response.body)
    # Get the first Basecamp 3/4 account
    account = auth_data['accounts'].find { |a| a['product'] == 'bc3' }

    unless account
      return redirect_to plan_path, alert: "No Basecamp 3/4 account found"
    end

    credential = BasecampCredential.first_or_initialize
    credential.update!(
      access_token: token_data['access_token'],
      refresh_token: token_data['refresh_token'],
      expires_at: Time.current + token_data['expires_in'].to_i.seconds,
      account_id: account['id'].to_s
    )

    redirect_to plan_path, notice: "Basecamp connected successfully!"
  end

  def failure
    redirect_to plan_path, alert: "Failed to connect: #{params[:message]}"
  end
end
