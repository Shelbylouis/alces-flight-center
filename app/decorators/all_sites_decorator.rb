class AllSitesDecorator < ApplicationDecorator
  delegate_all

  def tabs
    [
      { id: :all_sites, path: h.root_path },
      cases_tab
    ]
  end

  private

  def cases_tab
    tabs_builder.cases.merge(text: 'All Cases').tap do |tab|
      tab[:dropdown] = tab[:dropdown].reject do |item|
        item[:text] == 'Create'
      end
    end
  end

  # We override these to generate the top level path names
  def scope_name_for_paths
    ''
  end

  def arguments_for_scope_path(*a)
    a
  end
end
