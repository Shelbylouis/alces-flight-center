class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def readable_model_name
    self.class.to_s.tableize.humanize(capitalize: false).singularize
  end
end
