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

ActiveRecord::Schema[8.1].define(version: 2026_06_22_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "domains", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "canonical_host"
    t.datetime "created_at", null: false
    t.string "hostname", null: false
    t.string "locale", default: "it", null: false
    t.bigint "node_id"
    t.boolean "primary", default: false, null: false
    t.bigint "role_assignment_id"
    t.json "settings"
    t.string "target_action"
    t.string "target_controller"
    t.datetime "updated_at", null: false
    t.index ["hostname"], name: "index_domains_on_hostname", unique: true
    t.index ["node_id"], name: "index_domains_on_node_id"
    t.index ["role_assignment_id"], name: "index_domains_on_role_assignment_id"
  end

  create_table "node_contents", force: :cascade do |t|
    t.text "body_html"
    t.jsonb "body_json", default: {}, null: false
    t.text "body_md"
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.string "editor", default: "markdown", null: false
    t.string "format", default: "markdown", null: false
    t.bigint "node_id", null: false
    t.string "source_checksum"
    t.string "source_path"
    t.datetime "updated_at", null: false
    t.index ["editor"], name: "index_node_contents_on_editor"
    t.index ["format"], name: "index_node_contents_on_format"
    t.index ["node_id"], name: "index_node_contents_on_node_id", unique: true
    t.index ["source_checksum"], name: "index_node_contents_on_source_checksum"
  end

  create_table "node_hierarchies", id: false, force: :cascade do |t|
    t.integer "ancestor_id", null: false
    t.integer "descendant_id", null: false
    t.integer "generations", null: false
    t.index ["ancestor_id", "descendant_id", "generations"], name: "node_anc_desc_idx", unique: true
    t.index ["descendant_id"], name: "node_desc_idx"
  end

  create_table "nodes", force: :cascade do |t|
    t.string "content_type"
    t.datetime "created_at", null: false
    t.integer "depth"
    t.text "description"
    t.bigint "link_node_id"
    t.string "node_type", default: "node", null: false
    t.bigint "parent_id"
    t.integer "position"
    t.bigint "role_assignment_id", null: false
    t.string "slug"
    t.string "status", default: "draft", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "view_type", default: "default", null: false
    t.string "visibility", default: "public", null: false
    t.index ["link_node_id"], name: "index_nodes_on_link_node_id"
    t.index ["node_type"], name: "index_nodes_on_node_type"
    t.index ["parent_id"], name: "index_nodes_on_parent_id"
    t.index ["role_assignment_id"], name: "index_nodes_on_role_assignment_id"
    t.index ["status"], name: "index_nodes_on_status"
    t.index ["view_type"], name: "index_nodes_on_view_type"
    t.index ["visibility"], name: "index_nodes_on_visibility"
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

  create_table "role_assignments", force: :cascade do |t|
    t.bigint "context_id"
    t.string "context_type"
    t.datetime "created_at", null: false
    t.bigint "parent_id"
    t.bigint "profile_id", null: false
    t.integer "role", null: false
    t.datetime "updated_at", null: false
    t.index ["context_type", "context_id"], name: "index_role_assignments_on_context_type_and_context_id"
    t.index ["parent_id"], name: "index_role_assignments_on_parent_id"
    t.index ["profile_id", "role", "context_type", "context_id"], name: "index_role_assignments_on_context_role", unique: true, where: "((context_type IS NOT NULL) AND (context_id IS NOT NULL))"
    t.index ["profile_id", "role"], name: "index_role_assignments_on_global_role", unique: true, where: "((context_type IS NULL) AND (context_id IS NULL))"
    t.index ["profile_id"], name: "index_role_assignments_on_profile_id"
    t.index ["role"], name: "index_role_assignments_on_role"
    t.check_constraint "context_type IS NULL AND context_id IS NULL OR context_type IS NOT NULL AND context_id IS NOT NULL", name: "role_assignments_context_presence"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "traveler_subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "domain_id", null: false
    t.bigint "node_id", null: false
    t.bigint "profile_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "subscribed_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_traveler_subscriptions_on_domain_id"
    t.index ["node_id"], name: "index_traveler_subscriptions_on_node_id"
    t.index ["profile_id", "domain_id"], name: "index_traveler_subscriptions_on_profile_id_and_domain_id", unique: true
    t.index ["profile_id", "node_id"], name: "index_traveler_subscriptions_on_profile_id_and_node_id"
    t.index ["profile_id"], name: "index_traveler_subscriptions_on_profile_id"
    t.index ["status"], name: "index_traveler_subscriptions_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.integer "active_role", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "current_role_assignment_id"
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.boolean "superadmin", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["current_role_assignment_id"], name: "index_users_on_current_role_assignment_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "domains", "nodes"
  add_foreign_key "domains", "role_assignments"
  add_foreign_key "node_contents", "nodes"
  add_foreign_key "nodes", "nodes", column: "link_node_id"
  add_foreign_key "nodes", "nodes", column: "parent_id"
  add_foreign_key "nodes", "role_assignments"
  add_foreign_key "profiles", "users"
  add_foreign_key "role_assignments", "profiles"
  add_foreign_key "role_assignments", "role_assignments", column: "parent_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "traveler_subscriptions", "domains"
  add_foreign_key "traveler_subscriptions", "nodes"
  add_foreign_key "traveler_subscriptions", "profiles"
  add_foreign_key "users", "role_assignments", column: "current_role_assignment_id"
end
