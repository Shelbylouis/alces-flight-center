class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Every model in app is assumed to be related to a specific Site, unless it
  # is explicitly defined as global by adding it to this whitelist.
  GLOBAL_MODELS = [
    AssetRecordFieldDefinition,
    CaseCategory,
    ComponentType,
    Issue,
    ServiceType,
  ]


  def readable_model_name
    self.class.to_s.tableize.humanize(capitalize: false).singularize
  end
end
