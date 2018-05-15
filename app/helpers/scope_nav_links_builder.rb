
class ScopeNavLinksBuilder
  include Draper::ViewHelpers

  def initialize(scope:)
    @scope = scope
  end

  def build
    return [] unless scope
    scope_nav_link_procs = []

    if h.current_user&.admin?
      scope_nav_link_procs << nav_link_proc(text: 'All Sites',
                                            path: h.root_path,
                                            nav_icon: 'fa-globe')
    end

    site_obj = model_from_scope :site
    path_for_site = if h.current_user.admin?
                      site_obj
                    else
                      h.root_path
                    end
    if site_obj
      scope_nav_link_procs << nav_link_proc(model: site_obj,
                                            path: path_for_site,
                                            nav_icon: 'fa-institution')
    end

    cluster_obj = model_from_scope :cluster
    if cluster_obj
      scope_nav_link_procs << nav_link_proc(model: cluster_obj,
                                            nav_icon: 'fa-server')
    end

    component_group_obj = model_from_scope :component_group
    if component_group_obj
      scope_nav_link_procs << nav_link_proc(model: component_group_obj,
                                            nav_icon: 'fa-cubes')
    end

    cluster_part = model_from_scope(:service) || model_from_scope(:component)
    if cluster_part
      scope_nav_link_procs << nav_link_proc(model: cluster_part,
                                            nav_icon: 'fa-cube')
    end

    scope_nav_link_procs
  end

  private

  attr_reader :scope

  def model_from_scope(type)
    if scope.respond_to? type
      scope.public_send type
    elsif scope.is_a?(type.to_s.classify.constantize)
      scope
    else
      nil
    end
  end

  def nav_link_proc(**inputs_to_partial)
    Proc.new do |**additional_inputs|
      h.render 'partials/nav_link', **additional_inputs, **inputs_to_partial
    end
  end
end
