
RequestMaintenanceWindow = KeywordStruct.new(
  :case_id,
  :user,
  :cluster_id,
  :component_id,
  :service_id
) do
  def initialize(**kwargs)
    defaults = {cluster_id: nil, component_id: nil, service_id: nil}
    super(**defaults.merge(kwargs))
  end

  def run
    MaintenanceWindow.create!(
      user: user,
      case: support_case,
      associated_model: associated_model
    ).tap(&:request!)
  end

  private

  def support_case
    @support_case ||= Case.find(case_id)
  end

  def associated_model
    @associated_model ||=
      if component_id.present?
        Component.find(component_id)
      elsif service_id.present?
        Service.find(service_id)
      elsif cluster_id.present?
        Cluster.find(cluster_id)
      else
        support_case.associated_model
      end
  end
end
