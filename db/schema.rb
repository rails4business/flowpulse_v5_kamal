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

ActiveRecord::Schema[8.1].define(version: 2026_09_25_090000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "brand_processes", force: :cascade do |t|
    t.bigint "node_id", null: false
    t.bigint "created_by_user_id", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.text "description"
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_brand_processes_on_created_by_user_id"
    t.index ["node_id", "slug"], name: "index_brand_processes_on_node_id_and_slug", unique: true
    t.index ["node_id", "status"], name: "index_brand_processes_on_node_id_and_status"
    t.index ["node_id"], name: "index_brand_processes_on_node_id"
  end

  create_table "data_commitment_imports", force: :cascade do |t|
    t.bigint "uploaded_by_user_id", null: false
    t.string "status", default: "pending", null: false
    t.string "source_name", null: false
    t.jsonb "payload", default: {}, null: false
    t.jsonb "summary", default: {}, null: false
    t.datetime "applied_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "target_profile_id"
    t.string "source_type", default: "manual", null: false
    t.string "source_fingerprint"
    t.index ["source_fingerprint"], name: "index_data_commitment_imports_on_source_fingerprint", unique: true
    t.index ["target_profile_id"], name: "index_data_commitment_imports_on_target_profile_id"
    t.index ["uploaded_by_user_id"], name: "index_data_commitment_imports_on_uploaded_by_user_id"
  end

  create_table "data_commitments", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "created_by_profile_id", null: false
    t.bigint "domain_id", null: false
    t.string "subject_type"
    t.bigint "subject_id"
    t.string "title", null: false
    t.text "description"
    t.string "kind", default: "work", null: false
    t.string "status", default: "completed", null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.boolean "all_day", default: false, null: false
    t.string "location_name"
    t.string "location_address"
    t.string "online_url"
    t.string "pricing_type", default: "hourly", null: false
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.decimal "total_price", precision: 12, scale: 2
    t.string "contribution_type", default: "time_investment", null: false
    t.jsonb "genera_impresa", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "actual_started_at"
    t.datetime "actual_ended_at"
    t.string "calendar_key", null: false
    t.string "calendar_label", null: false
    t.boolean "blocks_calendar", default: true, null: false
    t.bigint "assignee_profile_id"
    t.bigint "responsible_profile_id"
    t.uuid "sync_key", default: -> { "gen_random_uuid()" }, null: false
    t.bigint "parent_id"
    t.string "participation_role"
    t.integer "agreed_price_cents"
    t.string "agreed_currency"
    t.integer "agreed_duration_minutes"
    t.jsonb "agreement_snapshot", default: {}, null: false
    t.bigint "participant_contact_id"
    t.bigint "data_slot_id"
    t.bigint "data_experience_id"
    t.bigint "data_session_id"
    t.integer "position", default: 0, null: false
    t.index ["actual_started_at"], name: "index_data_commitments_on_actual_started_at"
    t.index ["assignee_profile_id"], name: "index_data_commitments_on_assignee_profile_id"
    t.index ["created_by_profile_id"], name: "index_data_commitments_on_created_by_profile_id"
    t.index ["data_experience_id", "position"], name: "index_data_commitments_on_data_experience_id_and_position"
    t.index ["data_experience_id", "starts_at"], name: "index_data_commitments_on_data_experience_id_and_starts_at"
    t.index ["data_experience_id"], name: "index_data_commitments_on_data_experience_id"
    t.index ["data_session_id", "position"], name: "index_data_commitments_on_data_session_id_and_position"
    t.index ["data_session_id", "starts_at"], name: "index_data_commitments_on_data_session_id_and_starts_at"
    t.index ["data_session_id"], name: "index_data_commitments_on_data_session_id"
    t.index ["data_slot_id", "position"], name: "index_data_commitments_on_data_slot_id_and_position"
    t.index ["data_slot_id", "status"], name: "index_data_commitments_on_data_slot_id_and_status"
    t.index ["data_slot_id"], name: "index_data_commitments_on_data_slot_id"
    t.index ["domain_id"], name: "index_data_commitments_on_domain_id"
    t.index ["genera_impresa"], name: "index_data_commitments_on_genera_impresa", using: :gin
    t.index ["kind"], name: "index_data_commitments_on_kind"
    t.index ["parent_id"], name: "index_data_commitments_on_parent_id"
    t.index ["participant_contact_id"], name: "index_data_commitments_on_participant_contact_id"
    t.index ["profile_id", "calendar_key", "starts_at"], name: "index_commitments_on_owner_calendar_start"
    t.index ["profile_id", "calendar_key"], name: "index_one_active_timer_per_calendar", unique: true, where: "(((status)::text = 'in_progress'::text) AND (actual_ended_at IS NULL))"
    t.index ["profile_id"], name: "index_data_commitments_on_profile_id"
    t.index ["responsible_profile_id"], name: "index_data_commitments_on_responsible_profile_id"
    t.index ["starts_at"], name: "index_data_commitments_on_starts_at"
    t.index ["status"], name: "index_data_commitments_on_status"
    t.index ["subject_type", "subject_id"], name: "index_data_commitments_on_subject"
    t.index ["sync_key"], name: "index_data_commitments_on_sync_key", unique: true
  end

  create_table "data_experiences", force: :cascade do |t|
    t.bigint "created_by_user_id", null: false
    t.string "title", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "brand_process_id"
    t.index ["brand_process_id"], name: "index_data_experiences_on_brand_process_id"
    t.index ["created_by_user_id"], name: "index_data_experiences_on_created_by_user_id"
  end

  create_table "data_sessions", force: :cascade do |t|
    t.bigint "data_experience_id", null: false
    t.string "title", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.bigint "professional_calendar_id"
    t.string "visibility", default: "private", null: false
    t.bigint "service_id"
    t.index ["data_experience_id", "position"], name: "index_data_sessions_on_data_experience_id_and_position"
    t.index ["data_experience_id", "starts_at"], name: "index_data_sessions_on_data_experience_id_and_starts_at"
    t.index ["data_experience_id"], name: "index_data_sessions_on_data_experience_id"
    t.index ["professional_calendar_id", "starts_at"], name: "index_data_sessions_on_calendar_and_start"
    t.index ["service_id"], name: "index_data_sessions_on_service_id"
  end

  create_table "data_slots", force: :cascade do |t|
    t.bigint "data_session_id"
    t.string "title", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "data_experience_id", null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.index ["data_experience_id", "starts_at"], name: "index_data_slots_on_data_experience_id_and_starts_at"
    t.index ["data_experience_id"], name: "index_data_slots_on_data_experience_id"
    t.index ["data_session_id", "position"], name: "index_data_slots_on_data_session_id_and_position"
    t.index ["data_session_id"], name: "index_data_slots_on_data_session_id"
  end

  create_table "domain_memberships", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "domain_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "joined_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_domain_memberships_on_domain_id"
    t.index ["profile_id", "domain_id"], name: "index_domain_memberships_on_profile_id_and_domain_id", unique: true
    t.index ["profile_id"], name: "index_domain_memberships_on_profile_id"
    t.index ["status"], name: "index_domain_memberships_on_status"
  end

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
    t.bigint "node_id"
    t.bigint "role_assignment_id"
    t.index ["hostname"], name: "index_domains_on_hostname", unique: true
    t.index ["node_id"], name: "index_domains_on_node_id"
    t.index ["role_assignment_id"], name: "index_domains_on_role_assignment_id"
  end

  create_table "impegno_contacts", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.string "name", null: false
    t.string "kind", default: "person", null: false
    t.string "email"
    t.string "phone"
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id", "name"], name: "index_impegno_contacts_on_profile_id_and_name"
    t.index ["profile_id"], name: "index_impegno_contacts_on_profile_id"
  end

  create_table "impegno_places", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.string "name", null: false
    t.string "kind", default: "other", null: false
    t.string "address"
    t.string "online_url"
    t.text "notes"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "domain_id"
    t.string "scope", default: "private", null: false
    t.string "approval_status", default: "draft", null: false
    t.index ["domain_id", "scope", "approval_status"], name: "index_impegno_places_on_domain_scope_approval"
    t.index ["domain_id"], name: "index_impegno_places_on_domain_id"
    t.index ["profile_id", "name"], name: "index_impegno_places_on_profile_id_and_name"
    t.index ["profile_id"], name: "index_impegno_places_on_profile_id"
  end

  create_table "node_contents", force: :cascade do |t|
    t.bigint "node_id", null: false
    t.text "body_html"
    t.jsonb "body_json", default: {}, null: false
    t.text "body_md"
    t.jsonb "data", default: {}, null: false
    t.string "editor", default: "markdown", null: false
    t.string "format", default: "markdown", null: false
    t.string "source_checksum"
    t.string "source_path"
    t.datetime "created_at", null: false
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
    t.string "title"
    t.string "slug"
    t.bigint "parent_id"
    t.integer "position"
    t.bigint "link_node_id"
    t.string "visibility", default: "public", null: false
    t.string "status", default: "draft", null: false
    t.string "view_type", default: "default", null: false
    t.text "description"
    t.integer "depth"
    t.string "content_type"
    t.bigint "role_assignment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "operator_roles", default: [], null: false
    t.bigint "professional_owner_node_id"
    t.integer "node_type", default: 1, null: false
    t.index ["link_node_id"], name: "index_nodes_on_link_node_id"
    t.index ["node_type"], name: "index_nodes_on_node_type"
    t.index ["parent_id"], name: "index_nodes_on_parent_id"
    t.index ["professional_owner_node_id"], name: "index_nodes_on_professional_owner_node_id"
    t.index ["role_assignment_id"], name: "index_nodes_on_role_assignment_id"
    t.index ["status"], name: "index_nodes_on_status"
    t.index ["view_type"], name: "index_nodes_on_view_type"
    t.index ["visibility"], name: "index_nodes_on_visibility"
  end

  create_table "password_reset_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "requested_at", null: false
    t.datetime "fulfilled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "fulfilled_at"], name: "index_password_reset_requests_on_user_id_and_fulfilled_at"
    t.index ["user_id"], name: "index_password_reset_requests_on_user_id"
  end

  create_table "posturacorretta_directory_people", force: :cascade do |t|
    t.bigint "domain_id", null: false
    t.bigint "profile_id"
    t.string "name", null: false
    t.string "slug", null: false
    t.string "role"
    t.string "city"
    t.text "summary"
    t.string "visibility", default: "draft", null: false
    t.jsonb "listing_sections", default: [], null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id", "slug"], name: "index_posturacorretta_directory_people_on_domain_id_and_slug", unique: true
    t.index ["domain_id"], name: "index_posturacorretta_directory_people_on_domain_id"
    t.index ["profile_id"], name: "index_posturacorretta_directory_people_on_profile_id"
  end

  create_table "posturacorretta_directory_places", force: :cascade do |t|
    t.bigint "domain_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "kind", default: "other", null: false
    t.string "city"
    t.string "address"
    t.text "summary"
    t.string "visibility", default: "draft", null: false
    t.jsonb "listing_sections", default: [], null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id", "slug"], name: "index_posturacorretta_directory_places_on_domain_id_and_slug", unique: true
    t.index ["domain_id"], name: "index_posturacorretta_directory_places_on_domain_id"
  end

  create_table "professional_calendars", force: :cascade do |t|
    t.bigint "context_node_id", null: false
    t.bigint "created_by_user_id", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.string "short_label"
    t.text "description"
    t.string "color", default: "slate", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "professional_node_id"
    t.index ["context_node_id", "title"], name: "index_professional_calendars_on_context_node_id_and_title"
    t.index ["context_node_id"], name: "index_professional_calendars_on_context_node_id"
    t.index ["created_by_user_id"], name: "index_professional_calendars_on_created_by_user_id"
    t.index ["professional_node_id", "active"], name: "index_professional_calendars_on_owner_and_active"
    t.index ["professional_node_id"], name: "index_professional_calendars_on_professional_node_id"
    t.index ["slug"], name: "index_professional_calendars_on_slug", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "first_name"
    t.string "last_name"
    t.string "role"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "username", null: false
    t.bigint "primary_node_id"
    t.index ["primary_node_id"], name: "index_profiles_on_primary_node_id", unique: true
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
    t.index ["username"], name: "index_profiles_on_username", unique: true
  end

  create_table "role_assignments", force: :cascade do |t|
    t.integer "role", null: false
    t.string "context_type"
    t.bigint "context_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_id"
    t.bigint "profile_id", null: false
    t.string "role_operator"
    t.index ["context_type", "context_id"], name: "index_role_assignments_on_context_type_and_context_id"
    t.index ["parent_id"], name: "index_role_assignments_on_parent_id"
    t.index ["profile_id", "role", "context_type", "context_id"], name: "index_role_assignments_on_context_role", unique: true, where: "((context_type IS NOT NULL) AND (context_id IS NOT NULL) AND (role <> 11))"
    t.index ["profile_id", "role", "role_operator", "context_type", "context_id"], name: "index_role_assignments_on_operator_function", unique: true, where: "((context_type IS NOT NULL) AND (context_id IS NOT NULL) AND (role = 11))"
    t.index ["profile_id", "role"], name: "index_role_assignments_on_global_role", unique: true, where: "((context_type IS NULL) AND (context_id IS NULL))"
    t.index ["profile_id"], name: "index_role_assignments_on_profile_id"
    t.index ["role"], name: "index_role_assignments_on_role"
    t.check_constraint "context_type IS NULL AND context_id IS NULL OR context_type IS NOT NULL AND context_id IS NOT NULL", name: "role_assignments_context_presence"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "node_id", null: false
    t.bigint "created_by_user_id", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_services_on_created_by_user_id"
    t.index ["node_id", "slug"], name: "index_services_on_node_id_and_slug", unique: true
    t.index ["node_id", "title"], name: "index_services_on_node_id_and_title"
    t.index ["node_id"], name: "index_services_on_node_id"
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
    t.bigint "profile_id", null: false
    t.bigint "domain_id", null: false
    t.bigint "node_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "subscribed_at", null: false
    t.datetime "created_at", null: false
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
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.boolean "superadmin", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "current_role_assignment_id"
    t.datetime "email_change_authorized_at"
    t.index ["current_role_assignment_id"], name: "index_users_on_current_role_assignment_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "brand_processes", "nodes"
  add_foreign_key "brand_processes", "users", column: "created_by_user_id"
  add_foreign_key "data_commitment_imports", "profiles", column: "target_profile_id"
  add_foreign_key "data_commitment_imports", "users", column: "uploaded_by_user_id"
  add_foreign_key "data_commitments", "data_commitments", column: "parent_id"
  add_foreign_key "data_commitments", "data_experiences"
  add_foreign_key "data_commitments", "data_sessions"
  add_foreign_key "data_commitments", "data_slots"
  add_foreign_key "data_commitments", "domains"
  add_foreign_key "data_commitments", "impegno_contacts", column: "participant_contact_id"
  add_foreign_key "data_commitments", "profiles"
  add_foreign_key "data_commitments", "profiles", column: "assignee_profile_id"
  add_foreign_key "data_commitments", "profiles", column: "created_by_profile_id"
  add_foreign_key "data_commitments", "profiles", column: "responsible_profile_id"
  add_foreign_key "data_experiences", "brand_processes"
  add_foreign_key "data_experiences", "users", column: "created_by_user_id"
  add_foreign_key "data_sessions", "data_experiences"
  add_foreign_key "data_sessions", "professional_calendars"
  add_foreign_key "data_sessions", "services", name: "fk_data_sessions_service"
  add_foreign_key "data_slots", "data_experiences"
  add_foreign_key "data_slots", "data_sessions"
  add_foreign_key "domain_memberships", "domains"
  add_foreign_key "domain_memberships", "profiles"
  add_foreign_key "domains", "nodes"
  add_foreign_key "domains", "role_assignments"
  add_foreign_key "impegno_contacts", "profiles"
  add_foreign_key "impegno_places", "domains"
  add_foreign_key "impegno_places", "profiles"
  add_foreign_key "node_contents", "nodes"
  add_foreign_key "nodes", "nodes", column: "link_node_id"
  add_foreign_key "nodes", "nodes", column: "parent_id"
  add_foreign_key "nodes", "nodes", column: "professional_owner_node_id"
  add_foreign_key "nodes", "role_assignments"
  add_foreign_key "password_reset_requests", "users"
  add_foreign_key "posturacorretta_directory_people", "domains"
  add_foreign_key "posturacorretta_directory_people", "profiles"
  add_foreign_key "posturacorretta_directory_places", "domains"
  add_foreign_key "professional_calendars", "nodes", column: "context_node_id"
  add_foreign_key "professional_calendars", "nodes", column: "professional_node_id"
  add_foreign_key "professional_calendars", "users", column: "created_by_user_id"
  add_foreign_key "profiles", "nodes", column: "primary_node_id"
  add_foreign_key "profiles", "users"
  add_foreign_key "role_assignments", "profiles"
  add_foreign_key "role_assignments", "role_assignments", column: "parent_id"
  add_foreign_key "services", "nodes"
  add_foreign_key "services", "users", column: "created_by_user_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "traveler_subscriptions", "domains"
  add_foreign_key "traveler_subscriptions", "nodes"
  add_foreign_key "traveler_subscriptions", "profiles"
  add_foreign_key "users", "role_assignments", column: "current_role_assignment_id"
end
