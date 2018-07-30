class CreateOtherIssues < ActiveRecord::Migration[5.2]
  def up
    # We create 2 'Other' Services, both requiring and not requiring a Service.
    # This serves two purposes:
    #
    # - practical purpose: it is simpler to make this simple data change,
    # rather than the alternative approach, which would be to add the ability
    # for an Issue to optionally require a Service, and handle this throughout
    # Flight Center from now on;
    #
    # - domain model purpose: conceptually these can also be considered
    # slightly different things, since when a User selects the former they have
    # classified their problem as related to a specific Service, and decided it
    # can't be classified as an available Issue, whereas the latter means they
    # have instead classified their problem as not related to any available
    # Service.
    Issue.create!(name: 'Other', requires_service: true)
    Issue.create!(name: 'Other', requires_service: false)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
