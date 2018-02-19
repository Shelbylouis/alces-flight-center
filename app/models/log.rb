
class Log < ApplicationRecord
  belongs_to :cluster
  has_one :site, through: :cluster
  belongs_to :engineer, class_name: 'User', foreign_key: "user_id"
  has_and_belongs_to_many :cases

  validates :details, presence: true
  validate :engineer_is_a_admin
  validate :cases_belong_to_cluster

  private

  def engineer_is_a_admin
    unless engineer&.admin?
      errors.add(:engineer, 'must be an admin')
    end
  end

  def cases_belong_to_cluster
    cases.each do |kase|
      unless kase.cluster == cluster
        msg = "ticket ##{kase.rt_ticket_id} is for a different cluster"
        errors.add(:cases, msg)
      end
    end
  end
end

