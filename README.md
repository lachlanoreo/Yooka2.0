# Yooka 2.0

A GTD "Plan" application that helps you prioritize Basecamp tasks and personal tasks together, with time-blocking next to your Google Calendar.

## Features

- **Task Management**: Create personal tasks and sync Basecamp tasks assigned to you
- **GTD Groups**: Organize tasks into Inbox, Today, Computer, Calls, Outside, Home, Waiting For, and Someday
- **Time Blocking**: Schedule Today tasks on a day view calendar (7AM-8PM)
- **Google Calendar Integration**: View your calendar events alongside task blocks
- **Basecamp Integration**: Sync tasks assigned to you, complete tasks back to Basecamp
- **Top Goal**: Set a daily focus goal

## Tech Stack

- Ruby on Rails 8
- PostgreSQL
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- Solid Queue (background jobs)

## Setup

### Prerequisites

- Ruby 3.4+
- PostgreSQL
- Node.js (for Tailwind)

### Installation

```bash
# Clone the repository
git clone https://github.com/lachlanoreo/Yooka2.0.git
cd Yooka2.0

# Install dependencies
bundle install

# Setup database
bin/rails db:setup

# Copy environment variables
cp .env.example .env
# Edit .env with your credentials (see below)

# Run the server
bin/dev
```

### API Credentials Setup

#### Google Calendar

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google Calendar API**
4. Go to **Credentials** > **Create Credentials** > **OAuth 2.0 Client ID**
5. Set Application type to "Web application"
6. Add authorized redirect URI: `http://localhost:3000/auth/google_oauth2/callback`
7. Copy the Client ID and Client Secret to your `.env` file

#### Basecamp

1. Go to [Basecamp Integrations](https://launchpad.37signals.com/integrations)
2. Click "Register a new application"
3. Fill in the details:
   - Name: Yooka
   - Company: Your name
   - Redirect URI: `http://localhost:3000/auth/basecamp/callback`
4. Copy the Client ID and Client Secret to your `.env` file

### Running Tests

```bash
bin/rails test
```

## Usage

1. Open `http://localhost:3000`
2. Connect your Google Calendar (optional)
3. Connect your Basecamp account (optional)
4. Create personal tasks in the Inbox
5. Move tasks between groups by clicking the menu on each task
6. Move tasks to "Today" to schedule them as time blocks
7. Drag and resize time blocks on the calendar
8. Set your top goal for the day

## Architecture

### Models

- `Task`: Personal and Basecamp tasks with group, position, and completion tracking
- `TimeBlock`: Scheduled blocks for Today tasks
- `DailyGoal`: Top goal per day
- `GoogleCredential`: OAuth tokens for Google Calendar
- `BasecampCredential`: OAuth tokens for Basecamp

### Key Files

- `app/controllers/plan_controller.rb`: Main Plan page
- `app/controllers/tasks_controller.rb`: Task CRUD and actions
- `app/services/google_calendar_service.rb`: Google Calendar integration
- `app/services/basecamp_service.rb`: Basecamp integration
- `app/javascript/controllers/`: Stimulus controllers for interactivity

## License

MIT
