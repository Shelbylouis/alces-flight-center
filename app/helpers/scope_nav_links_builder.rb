
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
    site = model_from_scope :site
    return nil unless site
    path_for_site = if h.current_user.admin?
                      site
                    else
                      h.root_path
                    end
    nav_link_proc(model: site,
                  path: path_for_site,
                  nav_icon: 'fa-institution')
  end

  def cluster_link
    link_for_model(:cluster, nav_icon: 'fa-server')
  end

  def component_group_link
    link_for_model(:component_group, nav_icon: 'fa-cubes')
  end

  def cluster_part_link
    link_for_model([:service, :component], nav_icon: 'fa-cube')
  end

  def link_for_model(possible_types, nav_icon:)
    model = first_model_from_scope(possible_types)
    return nil unless model
    nav_link_proc(model: model, nav_icon: nav_icon)
  end

  def first_model_from_scope(possible_types)
    Array.wrap(possible_types)
      .lazy
      .map { |type| model_from_scope(type) }
      .find(&:itself)
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
