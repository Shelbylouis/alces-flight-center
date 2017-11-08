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

ActiveRecord::Schema.define(version: 20171108124629) do

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
    t.integer "asset_record_field_definition_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_record_field_definition_id"], name: "index_asset_record_fields_on_asset_record_field_definition_id"
    t.index ["component_group_id"], name: "index_asset_record_fields_on_component_group_id"
    t.index ["component_id"], name: "index_asset_record_fields_on_component_id"
  end

  create_table "case_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cases", force: :cascade do |t|
    t.string "details", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "cluster_id"
    t.integer "component_id"
    t.integer "user_id"
    t.bigint "rt_ticket_id"
    t.boolean "archived", default: false, null: false
    t.integer "issue_id"
    t.bigint "service_id"
    t.index ["cluster_id"], name: "index_cases_on_cluster_id"
    t.index ["component_id"], name: "index_cases_on_component_id"
    t.index ["issue_id"], name: "index_cases_on_issue_id"
    t.index ["rt_ticket_id"], name: "index_cases_on_rt_ticket_id", unique: true
    t.index ["service_id"], name: "index_cases_on_service_id"
    t.index ["user_id"], name: "index_cases_on_user_id"
  end

  create_table "clusters", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "support_type"
    t.integer "site_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "canonical_name"
    t.index ["site_id"], name: "index_clusters_on_site_id"
  end

  create_table "component_groups", force: :cascade do |t|
    t.string "name", null: false
    t.integer "cluster_id", null: false
    t.integer "component_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cluster_id"], name: "index_component_groups_on_cluster_id"
    t.index ["component_type_id"], name: "index_component_groups_on_component_type_id"
  end

  create_table "component_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "components", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "component_group_id"
    t.string "support_type", default: "inherit", null: false
    t.index ["component_group_id"], name: "index_components_on_component_group_id"
  end

  create_table "issues", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "requires_component", default: false, null: false
    t.integer "case_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "details_template"
    t.string "support_type"
    t.string "identifier"
    t.boolean "requires_service", default: false, null: false
    t.bigint "service_type_id"
    t.index ["case_category_id"], name: "index_issues_on_case_category_id"
    t.index ["service_type_id"], name: "index_issues_on_service_type_id"
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
    t.bigint "service_type_id"
    t.bigint "cluster_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cluster_id"], name: "index_services_on_cluster_id"
    t.index ["service_type_id"], name: "index_services_on_service_type_id"
  end

  create_table "sites", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "canonical_name"
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
    t.index ["email"], name: "index_users_on_email"
    t.index ["remember_token"], name: "index_users_on_remember_token"
    t.index ["site_id"], name: "index_users_on_site_id"
  end

  add_foreign_key "cases", "services"
  add_foreign_key "issues", "service_types"
  add_foreign_key "services", "clusters"
  add_foreign_key "services", "service_types"
end
