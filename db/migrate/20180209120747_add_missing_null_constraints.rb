class AddMissingNullConstraints < ActiveRecord::Migration[5.1]
  def change
    # The following lines were generated using
    # `bin/generate-needed-null-constraint-migrations`.
    change_column_null :asset_record_fields, :asset_record_field_definition_id, false
    change_column_null :cases, :issue_id, false
    change_column_null :cases, :cluster_id, false
    change_column_null :cases, :user_id, false
    change_column_null :cases, :token, false
    change_column_null :cases, :subject, false
    change_column_null :cases, :rt_ticket_id, false
    change_column_null :clusters, :site_id, false
    change_column_null :clusters, :name, false
    change_column_null :clusters, :support_type, false
    change_column_null :clusters, :canonical_name, false
    change_column_null :components, :name, false
    change_column_null :components, :component_group_id, false
    change_column_null :component_groups, :component_make_id, false
    change_column_null :component_types, :ordering, false
    change_column_null :issues, :details_template, false
    change_column_null :issues, :support_type, false
    change_column_null :services, :service_type_id, false
    change_column_null :services, :cluster_id, false
    change_column_null :sites, :name, false
    change_column_null :sites, :canonical_name, false
  end
end
