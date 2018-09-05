class Site < ApplicationRecord
  include AdminConfig::Site
  include MarkdownDescription

  # TODO uncomment this when identifier migration has happened & been deployed
  # default_scope { order(:identifier) }

  has_many :users, dependent: :destroy
  has_many :additional_contacts, dependent: :destroy
  has_many :clusters, dependent: :destroy
  has_many :cases, through: :clusters
  has_many :components, through: :clusters
  has_many :services, through: :clusters
  has_one :terminal_service

  belongs_to :default_assignee,
             class_name: 'User',
             required: false

  validates :name, presence: true
  validates :canonical_name, presence: true

  before_validation CanonicalNameCreator.new, on: :create

  def site
    self
  end

  def email_recipients
    (users + additional_contacts).map(&:email)
  end

  def primary_contact
    users.find_by(role: 'primary_contact')
  end
end
