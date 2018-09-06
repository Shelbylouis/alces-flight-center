
class TabsBuilder
  def initialize(user:, scope:)
    @user = user
    @scope = scope.decorate
  end

  def overview
    { id: :overview, path: scope.scope_path }
  end

  def cases
    read_only_cases.tap { |roc|
      nce = new_case_entry
      roc[:dropdown].unshift(new_case_entry) if nce
    }
  end

  def read_only_cases
    {
      id: :cases, path: scope.scope_cases_path,
      dropdown: [
        current_cases_entry,
        resolved_cases_entry,
      ].compact
    }
  end

  def logs
    { id: :logs, path: scope.scope_logs_path }
  end

  def maintenance
    {
      id: :maintenance,
      path: scope.scope_maintenance_windows_path,
    }
  end

  def cluster_composition(h)
    cluster = cluster_from_scope
    return unless cluster
    {
      id: :cluster,
      dropdown: [
        {
          text: 'Services',
          path: h.cluster_services_path(cluster)
        },
        {
          text: 'Components:',
          heading: true,
        }
      ].tap do |comps|
        comps.push(text: 'All', path: h.cluster_components_path(cluster))
        cluster.component_groups.each do |g|
          comps.push(
            text: g.name,
            path: h.component_group_path(g)
          )
        end
        if h.policy(cluster).import_components?
          comps.push(divider: true)
          comps.push(text: 'Import from Benchware', path: h.import_cluster_components_path(cluster))
        end
      end
    }
  end

  private

  attr_reader :user, :scope

  def new_case_entry
    if Pundit.policy!(user, Case).create?
      {
        text: 'Create',
        path: scope.new_scope_case_path,
      }
    end
  end

  def current_cases_entry
    {
      text: "Current (#{scope.cases.active.size})",
      path: scope.scope_cases_path(state: 'open'),
    }
  end

  def resolved_cases_entry
    {
      text: 'Resolved',
      path: scope.scope_cases_path(state: %w(resolved closed)),
    }
  end

  def cluster_from_scope
    if scope.is_a? Cluster
      scope
    elsif scope.respond_to?(:cluster)
      scope.cluster
    end
  end
end
