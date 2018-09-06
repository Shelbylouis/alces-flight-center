class Note < ApplicationRecord
  include MarkdownDescription
  include BelongsToCluster
  include AdminConfig::Note

  VISIBILITIES = %w(customer engineering).freeze

  belongs_to :cluster
  has_one :site, through: :cluster

  validates :description, presence: true
  validates :visibility, inclusion: { in: VISIBILITIES }, presence: true

  VISIBILITIES.each do |v|
    scope v, ->{ where(visibility: v) }
  end

  def visibilities_enum
    VISIBILITIES
  end

  private

  def check_read_permissions
    super
    return if permissions_check_unneeded?

    allowed = visibility == 'customer' || current_user.admin?

    unless allowed
      raise ReadPermissionsError,
            <<-EOF.squish
          User #{current_user.name} (site_id: #{current_user.site_id}) forbidden
          from accessing #{model_identifier} (site_id: #{site.id})
      EOF
    end
  end
end
