class ServiceDecorator < ClusterPartDecorator
  decorates_association :service_type

  def change_support_type_button
    render_change_support_type_button(
      request_advice_issue: Issue.request_service_becomes_advice_issue,
      request_managed_issue: Issue.request_service_becomes_managed_issue
    )
  end

  def path
    h.service_path(self)
  end

  def tabs
    [
      tabs_builder.overview,
      tabs_builder.read_only_cases,
      tabs_builder.maintenance,
      tabs_builder.cluster_composition(h),
    ]
  end

  def case_form_json
    issues_json = IssuesJsonBuilder.build_for(self)
    super.merge(issues_json)
  end

  def fa_icon
    'fa-gears'
  end

  def type_name
    'Service'
  end

  private

  class IssuesJsonBuilder
    def self.build_for(service)
      new(service).build
    end

    def build
      if any_categorised_issues?
        {categories: categorised_applicable_issues}
      else
        {issues: applicable_issues.map(&:case_form_json)}
      end
    end

    private

    attr_reader :service
    delegate :service_type, to: :service

    def initialize(service)
      @service = service
    end

    def any_categorised_issues?
      applicable_issues.any?(&:category)
    end

    def categorised_applicable_issues
      applicable_issues
        .group_by(&:category)
        .transform_keys { |category| category.nil? ? other_category : category }
        .map { |category, issues| category_json_for(category, issues: issues) }
    end

    def applicable_issues
      @applicable_issues ||=
        (service_type.issues + issues_requiring_any_service).reject(&:special?)
    end

    def issues_requiring_any_service
      Issue.where(
        requires_service: true,
        service_type: nil
      ).decorate
    end

    def other_category
      Category.new(name: 'Other', id: -1).decorate
    end

    def category_json_for(category, issues:)
      category.case_form_json.merge(issues: issues.map(&:case_form_json))
    end
  end
end
