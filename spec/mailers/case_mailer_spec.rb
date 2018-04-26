require 'rails_helper'

RSpec.describe 'Case mailer', :type => :mailer do

  let :site do
    create(:site)
  end

  let :requestor do
    create(:user, name: 'Some User', email: 'someuser@somecluster.com', site: site)
  end

  let :another_user do
    create(:user, site: site, email: 'another.user@somecluster.com' )
  end

  let :additional_contact do
    create(
        :additional_contact,
        site: site,
        email: 'mailing-list@somecluster.com'
    )
  end

  let :issue do
    create(
        :issue,
        name: 'Crashed node',
        requires_component: true,
        requires_service: true,
        category: category
    )
  end

  let(:category) { create(:category, name: 'Hardware issue') }
  let(:cluster) { create(:cluster, site: site, name: 'somecluster') }
  let(:component) { create(:component, name: 'node01', cluster: cluster) }
  let(:service) { create(:service, name: 'Some service', cluster: cluster) }

  let(:kase) {
    create(
        :case,
        rt_ticket_id: 1138,
        created_at: Time.now,
        cluster: cluster,
        issue: issue,
        component: component,
        service: service,
        user: requestor,
        subject: 'my_subject',
        fields: [
          {name: 'field1', value: 'value1'},
          {name: 'field2', value: 'value2', optional: true},
        ]
    )
  }

  before(:each) do
    site.users = [requestor, another_user]
    site.additional_contacts = [additional_contact]
  end

  it 'sends an email on case creation' do
    mail = CaseMailer.new_case(kase)
    expect(mail.subject).to eq "[helpdesk.alces-software.com #1138] somecluster: my_subject [#{kase.token}]"

    expect(mail.to).to eq nil
    expect(mail.cc).to match_array %w(another.user@somecluster.com mailing-list@somecluster.com)
    expect(mail.bcc).to match_array(['tickets@alces-software.com'])

    expected_lines = [
      /Cluster:.* somecluster/m,
      /Category:.* Hardware issue/m,
      /Issue:.* Crashed node/m,
      /Associated component:.* node01/m,
      /Associated service:.* Some service/m,
      /Fields:/,
      /field1:.* value1/m,
      /field2:.* value2/m,
    ]

    [:text, :html].each do |format|
      raw_body = mail.send("#{format}_part").body.raw_source

      expected_lines.each do |line|
        expect(raw_body).to match(line)
      end
    end
  end

  it 'sends an email on case comment being added' do
    comment = create(:case_comment,
      case: kase,
      user: another_user,
      text: 'I can haz comment'
    )

    mail = CaseMailer.comment(comment)

    expect(mail.to).to eq nil
    expect(mail.cc).to match_array %w(someuser@somecluster.com mailing-list@somecluster.com)
    expect(mail.bcc).to match_array(['tickets@alces-software.com'])

    expect(mail.body.encoded).to match('I can haz comment')
  end

  it 'sends an email on initial case assignment' do
    kase.assignee = another_user
    mail = CaseMailer.change_assignee(kase, nil)

    expect(mail.to).to eq nil
    expect(mail.cc).to match_array %w(another.user@somecluster.com someuser@somecluster.com mailing-list@somecluster.com)
    expect(mail.bcc).to match_array(['tickets@alces-software.com'])

    expect(mail.body.encoded).to match('This case has been assigned to A Scientist.')
  end

  it 'sends an email on case assignment change' do
    kase.assignee = another_user
    mail = CaseMailer.change_assignee(kase, requestor)

    expect(mail.to).to eq nil
    expect(mail.cc).to match_array %w(another.user@somecluster.com someuser@somecluster.com mailing-list@somecluster.com)
    expect(mail.bcc).to match_array(['tickets@alces-software.com'])

    expect(mail.body.encoded).to match(/This case has been assigned to A Scientist \(previously\s+assigned to Some User\)\./)
  end

  it 'sends an email on case assignee removal' do
    mail = CaseMailer.change_assignee(kase, another_user)

    expect(mail.to).to eq nil
    expect(mail.cc).to match_array %w(another.user@somecluster.com someuser@somecluster.com mailing-list@somecluster.com)
    expect(mail.bcc).to match_array(['tickets@alces-software.com'])

    expect(mail.body.encoded).to match('This case is no longer assigned to A Scientist.')
  end

end
