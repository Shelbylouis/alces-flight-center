# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180220124843) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "additional_contacts", force: :cascade do |t|
    t.string "email", null: false
    t.integer "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id"], name: "index_additional_contacts_on_site_id"
  end

  create_table "asset_record_field_definitions", force: :cascade do |t|
    t.string "field_name", null: false
    t.string "level", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "data_type"
  end

  create_table "asset_record_field_definitions_component_types", id: false, force: :cascade do |t|
    t.integer "asset_record_field_definition_id", null: false
    t.integer "component_type_id", null: false
    t.index ["asset_record_field_definition_id"], name: "index_arfd_ct_on_asset_record_field_definition_id"
    t.index ["component_type_id"], name: "index_arfd_ct_on_component_type_id"
  end

  create_table "asset_record_fields", force: :cascade do |t|
    t.string "value", null: false
    t.integer "component_id"
    t.integer "component_group_id"
    t.integer "asset_record_field_definition_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_record_field_definition_id"], name: "index_asset_record_fields_on_asset_record_field_definition_id"
    t.index ["component_group_id"], name: "index_asset_record_fields_on_component_group_id"
    t.index ["component_id"], name: "index_asset_record_fields_on_component_id"
  end

  create_table "cases", force: :cascade do |t|
    t.string "details", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cluster_id", null: false
    t.integer "component_id"
    t.integer "user_id", null: false
    t.bigint "rt_ticket_id", null: false
    t.boolean "archived", default: false, null: false
    t.integer "issue_id", null: false
    t.bigint "service_id"
    t.string "last_known_ticket_status", default: "new", null: false
    t.text "token", null: false
    t.text "subject", null: false
    t.index ["cluster_id"], name: "index_cases_on_cluster_id"
    t.index ["component_id"], name: "index_cases_on_component_id"
    t.index ["issue_id"], name: "index_cases_on_issue_id"
    t.index ["rt_ticket_id"], name: "index_cases_on_rt_ticket_id", unique: true
    t.index ["service_id"], name: "index_cases_on_service_id"
    t.index ["user_id"], name: "index_cases_on_user_id"
  end

  create_table "cases_cluster_logs", id: false, force: :cascade do |t|
    t.bigint "case_id", null: false
    t.bigint "cluster_log_id", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cluster_logs", force: :cascade do |t|
    t.text "details", null: false
    t.bigint "cluster_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cluster_id"], name: "index_cluster_logs_on_cluster_id"
    t.index ["user_id"], name: "index_cluster_logs_on_user_id"
  end

  create_table "clusters", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "support_type", null: false
    t.integer "site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "canonical_name", null: false
    t.string "charging_info"
    t.index ["site_id"], name: "index_clusters_on_site_id"
  end

  create_table "component_groups", force: :cascade do |t|
    t.string "name", null: false
    t.integer "cluster_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "component_make_id", null: false
    t.index ["cluster_id"], name: "index_component_groups_on_cluster_id"
    t.index ["component_make_id"], name: "index_component_groups_on_component_make_id"
  end

  create_table "component_makes", force: :cascade do |t|
    t.string "manufacturer", null: false
    t.string "model", null: false
    t.string "knowledgebase_url", null: false
    t.bigint "component_type_id", null: false
    t.index ["component_type_id"], name: "index_component_makes_on_component_type_id"
  end

  create_table "component_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ordering", null: false
  end

  create_table "components", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "component_group_id", null: false
    t.string "support_type", default: "inherit", null: false
    t.boolean "internal", default: false
    t.index ["component_group_id"], name: "index_components_on_component_group_id"
  end

  create_table "credit_charges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "case_id", null: false
    t.bigint "user_id", null: false
    t.integer "amount", null: false
    t.index ["case_id"], name: "index_credit_charges_on_case_id"
    t.index ["user_id"], name: "index_credit_charges_on_user_id"
  end

  create_table "credit_deposits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "cluster_id", null: false
    t.bigint "user_id", null: false
    t.integer "amount", null: false
    t.index ["cluster_id"], name: "index_credit_deposits_on_cluster_id"
    t.index ["user_id"], name: "index_credit_deposits_on_user_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "expansion_types", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "expansions", force: :cascade do |t|
    t.string "slot", null: false
    t.integer "ports", null: false
    t.bigint "expansion_type_id", null: false
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "component_make_id"
    t.bigint "component_id"
    t.index ["component_id"], name: "index_expansions_on_component_id"
    t.index ["component_make_id"], name: "index_expansions_on_component_make_id"
    t.index ["expansion_type_id"], name: "index_expansions_on_expansion_type_id"
  end

  create_table "issues", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "requires_component", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "details_template", null: false
    t.string "support_type", null: false
    t.string "identifier"
    t.boolean "requires_service", default: false, null: false
    t.bigint "service_type_id"
    t.boolean "chargeable", default: false, null: false
    t.bigint "category_id"
    t.index ["category_id"], name: "index_issues_on_category_id"
    t.index ["service_type_id"], name: "index_issues_on_service_type_id"
  end

  create_table "maintenance_window_state_transitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "maintenance_window_id", null: false
    t.string "namespace"
    t.string "event"
    t.string "from"
    t.string "to", null: false
    t.bigint "user_id"
    t.index ["maintenance_window_id"], name: "index_mwst_on_mw_id"
    t.index ["user_id"], name: "index_maintenance_window_state_transitions_on_user_id"
  end

  create_table "maintenance_windows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "ended_at_legacy"
    t.integer "requested_by_id_legacy"
    t.bigint "case_id", null: false
    t.bigint "confirmed_by_id_legacy"
    t.bigint "cluster_id"
    t.bigint "component_id"
    t.bigint "service_id"
    t.text "state", default: "new", null: false
    t.datetime "requested_start"
    t.datetime "requested_end"
    t.index ["case_id"], name: "index_maintenance_windows_on_case_id"
    t.index ["cluster_id"], name: "index_maintenance_windows_on_cluster_id"
    t.index ["component_id"], name: "index_maintenance_windows_on_component_id"
    t.index ["confirmed_by_id_legacy"], name: "index_maintenance_windows_on_confirmed_by_id_legacy"
    t.index ["requested_by_id_legacy"], name: "index_maintenance_windows_on_requested_by_id_legacy"
    t.index ["service_id"], name: "index_maintenance_windows_on_service_id"
  end

  create_table "service_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.boolean "automatic", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.string "support_type", default: "inherit", null: false
    t.bigint "service_type_id", null: false
    t.bigint "cluster_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "internal", default: false
    t.index ["cluster_id"], name: "index_services_on_cluster_id"
    t.index ["service_type_id"], name: "index_services_on_service_type_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "canonical_name", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.string "encrypted_password", limit: 128, null: false
    t.string "remember_token", limit: 128, null: false
    t.integer "site_id"
    t.boolean "admin", default: false, null: false
    t.string "confirmation_token", limit: 128
    t.boolean "primary_contact", default: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["site_id"], name: "index_users_on_site_id"
  end

  add_foreign_key "additional_contacts", "sites"
  add_foreign_key "asset_record_field_definitions_component_types", "asset_record_field_definitions"
  add_foreign_key "asset_record_field_definitions_component_types", "component_types"
  add_foreign_key "asset_record_fields", "asset_record_field_definitions"
  add_foreign_key "asset_record_fields", "component_groups"
  add_foreign_key "asset_record_fields", "components"
  add_foreign_key "cases", "clusters"
  add_foreign_key "cases", "components"
  add_foreign_key "cases", "issues"
  add_foreign_key "cases", "services"
  add_foreign_key "cases", "users"
  add_foreign_key "clusters", "sites"
  add_foreign_key "component_groups", "clusters"
  add_foreign_key "component_groups", "component_makes"
  add_foreign_key "component_makes", "component_types"
  add_foreign_key "components", "component_groups"
  add_foreign_key "credit_charges", "cases"
  add_foreign_key "credit_charges", "users"
  add_foreign_key "credit_deposits", "clusters"
  add_foreign_key "credit_deposits", "users"
  add_foreign_key "expansions", "component_makes"
  add_foreign_key "expansions", "components"
  add_foreign_key "expansions", "expansion_types"
  add_foreign_key "issues", "categories"
  add_foreign_key "issues", "service_types"
  add_foreign_key "maintenance_window_state_transitions", "maintenance_windows"
  add_foreign_key "maintenance_window_state_transitions", "users"
  add_foreign_key "maintenance_windows", "cases"
  add_foreign_key "maintenance_windows", "clusters"
  add_foreign_key "maintenance_windows", "components"
  add_foreign_key "maintenance_windows", "services"
  add_foreign_key "maintenance_windows", "users", column: "confirmed_by_id_legacy"
  add_foreign_key "maintenance_windows", "users", column: "requested_by_id_legacy"
  add_foreign_key "services", "clusters"
  add_foreign_key "services", "service_types"
  add_foreign_key "users", "sites"
end
