class BasecampService
  BASE_URL = "https://3.basecampapi.com"

  def initialize
    @credential = BasecampCredential.current
  end

  def connected?
    @credential.present? && @credential.access_token.present? && @credential.account_id.present?
  end

  def sync_todos_assigned_to_me
    return 0 unless connected?

    refresh_token_if_needed!

    Rails.logger.info "BasecampSync: Starting sync for user #{@credential.basecamp_user_id}"

    # Get all projects
    projects = fetch_projects
    Rails.logger.info "BasecampSync: Found #{projects.count} projects"

    all_todos = []

    projects.each do |project|
      Rails.logger.info "BasecampSync DEBUG: Processing project '#{project['name']}' (id: #{project['id']})"

      # Get todosets for this project
      todoset = fetch_todoset(project['id'])
      unless todoset
        Rails.logger.info "BasecampSync DEBUG: No todoset found for project #{project['id']}"
        next
      end
      Rails.logger.info "BasecampSync DEBUG: Found todoset #{todoset['id']} for project #{project['id']}"

      # Get all todolists in the todoset
      todolists = fetch_todolists(project['id'], todoset['id'])
      Rails.logger.info "BasecampSync DEBUG: Found #{todolists.count} todolists in project #{project['id']}"

      todolists.each do |todolist|
        Rails.logger.info "BasecampSync DEBUG: Processing todolist '#{todolist['name']}' (id: #{todolist['id']})"
        # Get todos from this list that are assigned to me
        todos = fetch_todos_assigned_to_me(project['id'], todolist['id'])
        todos.each do |todo|
          all_todos << process_todo(todo, project)
        end
      end
    end

    Rails.logger.info "BasecampSync: Found #{all_todos.count} todos assigned to user #{@credential.basecamp_user_id}"

    sync_with_local_tasks(all_todos)
  end

  def complete_todo(basecamp_todo_id, basecamp_project_id)
    return false unless connected?

    refresh_token_if_needed!

    # Basecamp 3/4 API to complete a todo
    response = connection.put("#{BASE_URL}/#{@credential.account_id}/buckets/#{basecamp_project_id}/todos/#{basecamp_todo_id}.json") do |req|
      req.body = { completed: true }.to_json
    end

    response.success?
  rescue => e
    Rails.logger.error "Basecamp complete todo error: #{e.message}"
    false
  end

  private

  def fetch_projects
    fetch_all_pages("#{BASE_URL}/#{@credential.account_id}/projects.json")
  rescue => e
    Rails.logger.error "Basecamp fetch projects error: #{e.message}"
    []
  end

  def fetch_todoset(project_id)
    # Get project details which includes the dock with tool IDs
    response = connection.get("#{BASE_URL}/#{@credential.account_id}/projects/#{project_id}.json")
    return nil unless response.success?

    project = JSON.parse(response.body)
    dock = project['dock'] || []

    # Find the todoset in the dock
    todoset_dock = dock.find { |d| d['name'] == 'todoset' && d['enabled'] }
    return nil unless todoset_dock

    # Return a hash with the ID we need
    { 'id' => todoset_dock['id'], 'url' => todoset_dock['url'] }
  rescue => e
    Rails.logger.error "Basecamp fetch todoset error: #{e.message}"
    nil
  end

  def fetch_todolists(project_id, todoset_id)
    fetch_all_pages("#{BASE_URL}/#{@credential.account_id}/buckets/#{project_id}/todosets/#{todoset_id}/todolists.json")
  rescue => e
    Rails.logger.error "Basecamp fetch todolists error: #{e.message}"
    []
  end

  def fetch_todos_assigned_to_me(project_id, todolist_id)
    url = "#{BASE_URL}/#{@credential.account_id}/buckets/#{project_id}/todolists/#{todolist_id}/todos.json"
    todos = fetch_all_pages(url)

    Rails.logger.info "BasecampSync: Todolist #{todolist_id} has #{todos.count} total todos"

    # Filter to only todos assigned to current user
    current_user_id = @credential.basecamp_user_id.to_s

    todos.select do |todo|
      assignees = todo['assignees'] || []
      assignees.any? { |a| a['id'].to_s == current_user_id }
    end
  rescue => e
    Rails.logger.error "Basecamp fetch todos error: #{e.message}"
    []
  end

  def process_todo(todo, project)
    {
      basecamp_todo_id: todo['id'].to_s,
      basecamp_project_id: project['id'].to_s,
      title: todo['content'],
      due_date: todo['due_on'] ? Date.parse(todo['due_on']) : nil,
      completed: todo['completed'],
      basecamp_url: todo['app_url']
    }
  end

  def sync_with_local_tasks(basecamp_todos)
    synced_ids = []
    created_count = 0
    updated_count = 0

    basecamp_todos.each do |todo_data|
      task = Task.find_or_initialize_by(basecamp_todo_id: todo_data[:basecamp_todo_id])

      if task.new_record?
        # New task - place in inbox
        task.assign_attributes(
          title: todo_data[:title],
          source: "basecamp",
          group: "inbox",
          due_date: todo_data[:due_date],
          basecamp_project_id: todo_data[:basecamp_project_id],
          basecamp_url: todo_data[:basecamp_url]
        )
        task.save!
        created_count += 1
      else
        # Existing task - update title and due date from Basecamp
        task.update!(
          title: todo_data[:title],
          due_date: todo_data[:due_date],
          basecamp_url: todo_data[:basecamp_url]
        )

        # If completed in Basecamp but not locally, mark as completed
        if todo_data[:completed] && !task.completed?
          task.complete!
        end
        updated_count += 1
      end

      synced_ids << todo_data[:basecamp_todo_id]
    end

    # Archive tasks that no longer exist in Basecamp
    archived_count = 0
    Task.basecamp.where.not(basecamp_todo_id: synced_ids).find_each do |task|
      unless task.archived?
        task.archive!
        archived_count += 1
      end
    end

    Rails.logger.info "BasecampSync: Created #{created_count}, Updated #{updated_count}, Archived #{archived_count} tasks"

    synced_ids.count
  end

  def connection
    @connection ||= Faraday.new do |conn|
      conn.headers['Authorization'] = "Bearer #{@credential.access_token}"
      conn.headers['Content-Type'] = 'application/json'
      conn.headers['User-Agent'] = 'Yooka (lachlan@example.com)'
      conn.adapter Faraday.default_adapter
    end
  end

  def refresh_token_if_needed!
    return unless @credential.needs_refresh?
    refresh_token!
  end

  def refresh_token!
    return unless @credential.refresh_token.present?

    response = Faraday.post('https://launchpad.37signals.com/authorization/token') do |req|
      req.params = {
        type: 'refresh',
        refresh_token: @credential.refresh_token,
        client_id: ENV['BASECAMP_CLIENT_ID'],
        client_secret: ENV['BASECAMP_CLIENT_SECRET']
      }
    end

    if response.success?
      data = JSON.parse(response.body)
      @credential.update!(
        access_token: data['access_token'],
        expires_at: Time.current + data['expires_in'].to_i.seconds
      )
    end
  rescue => e
    Rails.logger.error "Failed to refresh Basecamp token: #{e.message}"
  end

  # Pagination helpers for Basecamp API
  # Basecamp uses "geared pagination": 15 results on page 1, 30 on page 2, 50 on page 3, 100 on page 4+
  def fetch_all_pages(initial_url)
    results = []
    url = initial_url

    while url
      response = connection.get(url)
      break unless response.success?

      results.concat(JSON.parse(response.body))
      url = extract_next_page_url(response.headers['Link'])
    end

    results
  rescue => e
    Rails.logger.error "Basecamp pagination error: #{e.message}"
    results
  end

  def extract_next_page_url(link_header)
    return nil unless link_header
    match = link_header.match(/<([^>]+)>;\s*rel="next"/)
    match ? match[1] : nil
  end
end
