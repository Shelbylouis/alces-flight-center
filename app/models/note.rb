class Note < ApplicationRecord
  include MarkdownDescription
  include BelongsToCluster
  include AdminConfig::Note

  FLAVOURS = ['customer', 'engineering'].freeze

  belongs_to :cluster
  has_one :site, through: :cluster

  validates :description, presence: true
  validates :flavour, inclusion: { in: FLAVOURS }, presence: true

  FLAVOURS.each do |flavour|
    scope flavour, ->{ where(flavour: flavour) }
  end
end
