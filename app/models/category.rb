class Category < ApplicationRecord
  include AdminConfig::Category

  has_many :issues

  validates :name, presence: true

  def case_form_json
    {
      id: id,
      name: name,
    }
  end

  def self.globally_available?
    true
  end
end
