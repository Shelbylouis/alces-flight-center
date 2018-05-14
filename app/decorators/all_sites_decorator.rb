class AllSitesDecorator < ApplicationDecorator
  delegate_all

  def tabs
    [
      { id: :all_sites, path: h.root_path },
      {
        id: :cases, text: 'All Cases', path: h.cases_path,
        dropdown: [
          { text: 'Current', path: h.cases_path },
          { text: 'Resolved', path: h.resolved_cases_path }
        ]
      }
    ]
  end
end
