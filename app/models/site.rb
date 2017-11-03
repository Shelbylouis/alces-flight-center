class Site < ApplicationRecord
  include AdminConfig::Site
  include MarkdownDescription

  has_many :users, dependent: :destroy
  has_many :additional_contacts, dependent: :destroy
  has_many :clusters, dependent: :destroy
  has_many :cases, through: :clusters
  has_many :components, through: :clusters
  has_many :services, through: :clusters

  validates :name, presence: true
  validates :canonical_name, presence: true

  before_validation CanonicalNameCreator.new, on: :create

  def all_contacts
    users + additional_contacts
  end

  def contacts_info
    users.map(&:info).join(', ')
  end

  def additional_contacts_info
    additional_contacts.map(&:email).join(', ')
  end
end
