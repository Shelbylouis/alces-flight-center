class ContactNominationIssue < ActiveRecord::Migration[5.2]
  def up
    hpc_environment = ServiceType.find_by_name!('HPC Environment')

    flight_center_management_category = Category.create!(
      name: 'Flight Center management'
    )

    nominate_site_contact_issue = hpc_environment.issues.create!(
      name: 'Nominate new site contact',
      category: flight_center_management_category,
      requires_service: true
    )

    nominate_site_contact_issue.tiers.create!(
      level: 2,
      fields: [
        {
          type: 'markdown',
          content: <<~MARKDOWN.strip_heredoc
            Create a case of this type if you wish to exchange places in Flight
            Center as a contact for your site with an existing view-only user
            for your site.

            Once the switch has been authorised by an Alces Flight admin, you
            will no longer be able to create new support cases or otherwise
            take actions for your site, but you will still be able to view all
            of your site data and support cases.

            _Note that once authorised this action cannot be reversed by you,
            and another site contact will need to create another case of this
            type to exchange places with for you to become a site contact
            again._
          MARKDOWN
        },
        {
          type: 'input',
          name: 'User to nominate as site contact',
          help: <<~TEXT
            The current viewer user for your site that you wish to exchange
            places with. Please give either their name, email, or Flight
            platform username.
          TEXT
        }
      ]
    )

  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
