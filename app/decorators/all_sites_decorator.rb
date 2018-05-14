class AllSitesDecorator < ApplicationDecorator
  delegate_all

  def tabs
    [
      #{ id: :overview, path: h.cases_path },
      {
        id: :cases, path: h.cases_path,
        dropdown: [
          { text: 'Current', path: h.cases_path },
          { text: 'Resolved', path: h.resolved_cases_path }
        ]
      }
    ]
  end
end
