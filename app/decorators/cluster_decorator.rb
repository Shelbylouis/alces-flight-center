class ClusterDecorator < ApplicationDecorator
  delegate_all
  decorates_association :components
  decorates_association :component_groups
  decorates_association :services

  def path
    h.cluster_path(self)
  end

  def links
    h.raw(
     "<i class=\"fa #{fa_icon}\" title=\"#{type_name}\"></i> " +
       h.link_to(name,path)
    )
  end

  def tabs
    [
      tabs_builder.overview,
      { id: :documents, path: h.cluster_documents_path(self) },
      { id: :credit_usage, path: h.cluster_credit_usage_path(self) },
      ({ id: :checks, path: h.cluster_checks_path(self) } unless self.cluster_check_count.zero? ),
      tabs_builder.logs,
      tabs_builder.cases,
      tabs_builder.maintenance,
      {
        id: :cluster,
        dropdown: [
          {
            text: 'Services',
            path: h.cluster_services_path(self)
          },
          {
            text: 'Components:',
            heading: true,
          }
        ].tap do |comps|
          comps.push(text: 'All', path: h.cluster_components_path(self))
          cluster.component_groups.each do |g|
            comps.push(
              text: g.name,
              path: h.component_group_path(g)
            )
          end
          if h.policy(self).import_components?
            comps.push(divider: true)
            comps.push(text: 'Import from Benchware', path: h.import_cluster_components_path(self))
          end
        end
      }
    ].compact
  end

  def case_form_json
    {
      id: id,
      name: name,
      components: components.map(&:case_form_json),
      services: services.map(&:case_form_json).tap { |services|
        # We inject an 'Other' Service, to allow Users to create Issues they do
        # not think are associated to any existing Service via the usual Case
        # form drill-down process.
        services << other_service_json if other_service_json
      },
      supportType: support_type,
      chargingInfo: charging_info,
      # Encode MOTD in two forms: the raw form, to be used as the initial value
      # to be edited in the MOTD tool, and as sanitized, formatted HTML so the
      # current value can be displayed as it will be on the Cluster and in the
      # rest of Flight Center.
      motd: motd,
      motdHtml: h.simple_format(motd),
    }
  end

  def credit_balance_class
    if credit_balance.negative? || credit_balance.zero?
      'text-danger'
    elsif credit_balance < 10
      'text-warning'
    else
      'text-success'
    end
  end

  # List the first day of each quarter since this cluster was created, including
  # the current quarter (as defined by `Date.today`).
  def all_quarter_start_dates
    first_quarter = model.created_at.beginning_of_quarter
    last_quarter =  Date.today.beginning_of_quarter.to_datetime

    [].tap do |qs|
      curr_quarter = last_quarter
      while curr_quarter >= first_quarter
        qs << curr_quarter
        curr_quarter -= 3.months
      end
    end
  end

  def fa_icon
    'fa-server'
  end

  def type_name
    'Entire cluster'
  end

  def last_checked
    if check_results.empty?
      'N/A'
    else
      check_results.order(date: :desc).first.date
    end
  end

  def no_of_checks_passed(date = last_checked)
    check_results.where(date: date).where.not(result: 'Failure').count
  end

  def check_groups(checks)
    checks.group_by(&:check_category)
  end

  def check_results_class
    if no_of_checks_passed.zero?
      'text-danger'
    elsif no_of_checks_passed < checks.count
      'text-warning'
    else
      'text-success'
    end
  end

  private

  def other_service_json
    return unless IssuesJsonBuilder.other_service_issues.present?
    @other_service_json ||=
      other_service
      .decorate
      .case_form_json
      .merge(IssuesJsonBuilder.build_for(self))
  end

  def other_service
    Service.new(
      id: -1,
      name: 'Other or N/A',
      support_type: 'managed',
      service_type: ServiceType.new
    )
  end

  class IssuesJsonBuilder < ServiceDecorator::IssuesJsonBuilder
    private

    def self.other_service_issues
      Issue.where(requires_component: false, requires_service: false).decorate.reject(&:special?)
    end

    def applicable_issues
      self.class.other_service_issues
    end
  end

end
