class Case < ApplicationRecord
  belongs_to :issue
  belongs_to :cluster
  belongs_to :component, required: false
  belongs_to :user

  delegate :case_category, to: :issue
  delegate :site, to: :cluster

  validates :details, presence: true
  validates :rt_ticket_id, presence: true, uniqueness: true
  validate :correct_component_relationship
  validate :issue_valid_for_cluster_or_component

  before_validation :create_rt_ticket, on: :create

  def create_rt_ticket
    ticket = request_tracker.create_ticket(
      requestor_email: requestor_email,
      cc: cc_emails,
      subject: rt_ticket_subject,
      text: rt_ticket_text
    )

    self.rt_ticket_id = ticket.id
  end

  def mailto_url
    support_email = 'support@alces-software.com'
    subject = CGI.escape(rt_email_subject)
    "mailto:#{support_email}?subject=#{subject}"
  end

  def open
    !archived
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

  def requestor_email
    user.email
  end

  def cc_emails
    site.all_contacts
      .reject { |contact| contact.email == requestor_email }
      .map(&:email)
  end

  def rt_email_subject
    rt_email_identifier = "[helpdesk.alces-software.com ##{rt_ticket_id}]"
    "RE: #{rt_email_identifier} #{rt_ticket_subject}"
  end

  def rt_ticket_subject
    "Alces Flight Center ticket: #{cluster.name} - #{issue.name}"
  end

  def rt_ticket_text
    properties = {
      Cluster: cluster.name,
      'Case category': case_category.name,
      'Issue': issue.name,
      'Associated component': component&.name,
      Details: details,
    }.reject { |_k, v| v.nil? }

    # Ticket text does not need to be in this format, it is just text, but this
    # is readable and an adequate format for now.
    Utils.rt_format(properties)
  end

  def correct_component_relationship
    if issue.requires_component
      if !component
        errors.add(:component, 'issue requires a component but one was not given')
      elsif component.cluster != cluster
        errors.add(:component, 'given component is not part of given cluster')
      end
    elsif component
      errors.add(:component, 'issue does not require a component but one was given')
    end
  end

  def issue_valid_for_cluster_or_component
    # Can open cases for `advice` issues for any cluster or component.
    return if issue.advice?

    if issue.requires_component
      if component&.advice?
        errors.add(:issue, managed_issue_for_advice_component_error)
      end
    elsif cluster.advice?
      errors.add(:issue, managed_issue_for_advice_cluster_error)
    end
  end

  def managed_issue_for_advice_cluster_error
    managed_issue_error_for('cluster')
  end

  def managed_issue_for_advice_component_error
    managed_issue_error_for('component')
  end

  def managed_issue_error_for(model_type)
    <<-EOF.squish
      is only available for #{SupportType::MANAGED_TEXT}
      #{model_type.pluralize}, but given #{model_type} is
      #{SupportType::ADVICE_TEXT}
    EOF
  end
end
