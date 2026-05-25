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

ActiveRecord::Schema[8.1].define(version: 2026_05_25_103000) do
  create_table "domains", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "canonical_host"
    t.datetime "created_at", null: false
    t.string "hostname", null: false
    t.string "locale", default: "it", null: false
    t.boolean "primary", default: false, null: false
    t.json "settings"
    t.string "target_action"
    t.string "target_controller"
    t.datetime "updated_at", null: false
    t.index ["hostname"], name: "index_domains_on_hostname", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "active_role", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "demo_access"
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.boolean "superadmin", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "profiles", "users"
  add_foreign_key "sessions", "users"
end
