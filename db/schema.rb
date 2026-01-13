# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_01_13_075645) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "basecamp_credentials", force: :cascade do |t|
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.string "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "basecamp_user_id"
  end

  create_table "daily_goals", force: :cascade do |t|
    t.date "date"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_daily_goals_on_date", unique: true
  end

  create_table "google_credentials", force: :cascade do |t|
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.string "source", default: "personal", null: false
    t.string "group", default: "inbox", null: false
    t.integer "position", default: 0, null: false
    t.date "due_date"
    t.datetime "completed_at"
    t.datetime "archived_at"
    t.string "basecamp_todo_id"
    t.string "basecamp_project_id"
    t.string "basecamp_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "completed_from_group"
    t.index ["archived_at"], name: "index_tasks_on_archived_at"
    t.index ["basecamp_todo_id"], name: "index_tasks_on_basecamp_todo_id", unique: true, where: "(basecamp_todo_id IS NOT NULL)"
    t.index ["completed_at"], name: "index_tasks_on_completed_at"
    t.index ["group", "position"], name: "index_tasks_on_group_and_position"
  end

  create_table "time_blocks", force: :cascade do |t|
    t.bigint "task_id", null: false
    t.date "date", null: false
    t.integer "start_minutes", null: false
    t.integer "duration_minutes", default: 30, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "start_minutes"], name: "index_time_blocks_on_date_and_start_minutes"
    t.index ["task_id", "date"], name: "index_time_blocks_on_task_id_and_date", unique: true
    t.index ["task_id"], name: "index_time_blocks_on_task_id"
  end

  add_foreign_key "time_blocks", "tasks"
end
