class MigrateExistingDataToAccountForTiers < ActiveRecord::DataMigration
  def up
    create_tiers
    update_cases
  end

  private

  def create_tiers
    create_some_level_0_tiers
    create_level_1_tiers_for_support_type_change_issues
    create_initial_level_2_tiers_for_non_special_issues
    create_level_3_tiers_for_non_special_issues
  end

  def update_cases
    add_level_1_tier_fields_to_support_type_change_cases
    add_level_2_tier_fields_to_non_special_cases
    add_level_3_tier_fields_to_consultancy_cases
  end

  def create_level_3_tiers_for_non_special_issues
    non_special_issues.each do |issue|
      # We already have a (private) method to create the level 3/consultancy
      # Tier for new Issues, so just delegate to this.
      issue.send(:create_standard_consultancy_tier)
    end
  end

  def create_some_level_0_tiers
    Issue.find_by_name('Job running how-to/assistance').tiers.create!(
      level: 0,
      fields: [{
        type: 'markdown',
        content: <<~MARKDOWN.strip_heredoc
          See the corresponding documentation for a scheduler available in your
          environment:

          - [Slurm Scheduler](http://docs.alces-flight.com/en/stable/slurm/slurm.html)

          - [Open Grid Scheduler (SGE)](http://docs.alces-flight.com/en/stable/sge/sge.html)

          - [OpenLava Scheduler](http://docs.alces-flight.com/en/stable/openlava/openlava.html)

          - [TORQUE Scheduler](http://docs.alces-flight.com/en/stable/torque/torque.html)

          - [PBS Pro Scheduler](http://docs.alces-flight.com/en/stable/pbspro/pbspro.html)
        MARKDOWN
      }]
    )
  end

  def create_level_1_tiers_for_support_type_change_issues
    support_type_change_issues.each do |issue|
      issue.tiers.create!(
        level: 1,
        fields: [{
          type: 'input',
          name: 'Info'
        }],
      )
    end
  end

  def create_initial_level_2_tiers_for_non_special_issues
    generate_level_2_tiers_from_details_templates
    tweak_generated_level_2_tiers
  end

  def generate_level_2_tiers_from_details_templates
    non_special_issues.each do |issue|
      # Turn existing `details_template`s for Issues into initial fields for
      # level 2 Tiers by creating `input` field for each line in template.
      fields = issue
        .details_template
        .lines
        .map { |f| {type: 'input', name: f.strip.chomp(':')} }

      issue.tiers.create!(level: 2, fields: fields)
    end
  end

  def tweak_generated_level_2_tiers
    modify_level_2_tier_for('From available Alces Gridware') do |tier|
      # This field should just be some markdown info rather than an input.
      tier.fields[0] = {
        type: 'markdown',
        content: <<~MARKDOWN.squish
          See package listing at https://gridware.alces-flight.com for full
          details of available Alces Gridware.
        MARKDOWN
      }
    end

    storage_quota_issue = 'File System storage quota changes'

    # We want to increase space available in the last field of several level 2
    # Tiers.
    [
      'Application problems/bugs',
      'Job script how-to/assistance',
      'Self application install assistance',
      'Suspected hardware issue',
      'Suspected service issue',
      storage_quota_issue,
    ].each do |issue_name|
      modify_level_2_tier_for(issue_name) do |tier|
        last_field = tier.fields.last
        last_field['type'] = 'textarea'
        tier.fields[-1] = last_field
      end
    end

    # Tweak the wording for this field to read a bit better.
    modify_level_2_tier_for(storage_quota_issue) do |tier|
      last_field = tier.fields.last
      last_field['name'] = 'Details of the required storage quota changes'
      tier.fields[-1] = last_field
    end
  end

  def add_level_1_tier_fields_to_support_type_change_cases
    each_case(support_type_change_issues) do |kase|
      fields = [{type: 'input', name: 'Info', value: kase.details}]
      kase.update!(tier_level: 1, fields: fields)
    end
  end

  def add_level_2_tier_fields_to_non_special_cases
    each_case(non_special_issues) do |kase|
      fields = [{type: 'textarea', name: 'Details', value: kase.details}]
      kase.update!(tier_level: 2, fields: fields)
    end
  end

  def add_level_3_tier_fields_to_consultancy_cases
    each_case(consultancy_issues) do |kase|
      fields = [{type: 'textarea', name: 'Details', value: kase.details}]
      kase.update!(tier_level: 3, fields: fields)
    end
  end

  def non_special_issues
    Issue.all.reject(&:special?)
  end

  def support_type_change_issues
    [
      Issue.request_component_becomes_advice_issue,
      Issue.request_component_becomes_managed_issue,
      Issue.request_service_becomes_advice_issue,
      Issue.request_service_becomes_managed_issue,
    ]
  end

  def consultancy_issues
    [
      Issue.cluster_consultancy_issue,
      Issue.component_consultancy_issue,
      Issue.service_consultancy_issue,
    ]
  end

  def each_case(issues)
    issues.each do |issue|
      issue.cases.each do |kase|
        yield kase
      end
    end
  end

  def modify_level_2_tier_for(issue_name)
    tier = Issue.find_by_name!(issue_name)
      .tiers
      .find_by_level!(2)
    yield tier
    tier.save!
  end
end
