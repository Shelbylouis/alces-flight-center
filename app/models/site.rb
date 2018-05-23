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

  def site
    self
  end

  def all_contacts
    users + additional_contacts
  end

  def primary_contact
    users.find_by(primary_contact: true)
  end

  def secondary_contacts
    users.where(primary_contact: false).order(:id)
  end

  def managed_clusters
    clusters.select(&:managed?)
  end
end
