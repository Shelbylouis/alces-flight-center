class Case < ApplicationRecord
  belongs_to :case_category
  belongs_to :cluster
  belongs_to :component, required: false
  belongs_to :user

  validates :details, presence: true
  validates :rt_ticket_id, presence: true, uniqueness: true

  before_validation :create_rt_ticket, on: :create

  def create_rt_ticket
    # XXX Adjust info included in ticket.
    ticket = request_tracker.create_ticket(
      requestor_email: user.email,
      subject: "Supportware ticket: #{cluster.name} - #{case_category.name}",
      text: <<-EOF.strip_heredoc
        Cluster: #{cluster.name}
        Case category: #{case_category.name}
        Associated component: #{component&.name || 'None'}
        Details: #{details}
      EOF
    )

    self.rt_ticket_id = ticket.id
  end

  private

  def request_tracker
    # Note: `rt_interface_class` is a string which we `constantize`, rather
    # than a constant directly, otherwise Rails autoloading in development
    # could leave us holding a reference to an outdated version of the class,
    # which would then cause things to blow up (e.g. see
    # https://stackoverflow.com/a/23008837).
    @rt ||= Rails.configuration.rt_interface_class.constantize.new
  end
end
