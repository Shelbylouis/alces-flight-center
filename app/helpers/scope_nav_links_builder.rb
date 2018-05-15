
class ScopeNavLinksBuilder
  include Draper::ViewHelpers

  def initialize(scope:)
    @scope = scope
  end

  def build
    [
      all_sites_link,
      site_link,
      cluster_link,
      component_group_link,
      cluster_part_link,
    ].compact
  end

  private

  attr_reader :scope

  def all_sites_link
    if h.current_user&.admin?
      nav_link_proc(text: 'All Sites',
                    path: h.root_path,
                    nav_icon: 'fa-globe')
    end
  end

  def site_link
    site_obj = model_from_scope :site
    return nil unless site_obj
    path_for_site = if h.current_user.admin?
                      site_obj
                    else
                      h.root_path
                    end
    nav_link_proc(model: site_obj,
                  path: path_for_site,
                  nav_icon: 'fa-institution')
  end

  def cluster_link
    cluster_obj = model_from_scope :cluster
    return nil unless cluster_obj
    nav_link_proc(model: cluster_obj,
                  nav_icon: 'fa-server')
  end

  def component_group_link
    component_group_obj = model_from_scope :component_group
    return nil unless component_group_obj
    nav_link_proc(model: component_group_obj,
                  nav_icon: 'fa-cubes')
  end

  def cluster_part_link
    cluster_part = model_from_scope(:service) || model_from_scope(:component)
    return nil unless cluster_part
    nav_link_proc(model: cluster_part,
                  nav_icon: 'fa-cube')
  end

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
