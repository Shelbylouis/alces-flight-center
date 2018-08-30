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
        components: [component],
        services: [service],
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

  describe 'Case creation email' do
    subject { CaseMailer.new_case(kase) }

    let (:notification_method) { :case_notification }
    let (:slack_args) { kase }

    it 'has correct subject' do
      expect(
        subject.subject
      ).to eq "[helpdesk.alces-software.com #1138] somecluster: my_subject [#{kase.token}]"
    end

    it 'has correct addressees' do
      expect(subject.to).to eq nil
      expect(subject.cc).to match_array %w(another.user@somecluster.com mailing-list@somecluster.com)
      expect(subject.bcc).to match_array(['tickets@alces-software.com'])
    end

    [:text, :html].each do |format|
      describe "#{format} body" do
        let :raw_body do
          subject.send("#{format}_part").body.raw_source
        end

        it 'includes required lines' do
          expected_lines = [
            /Cluster:.* somecluster/m,
            /Category:.* Hardware issue/m,
            /Issue:.* Crashed node/m,
            /Associated components:.* node01/m,
            /Associated services:.* Some service/m,
            /Fields:/,
            /field1:.* value1/m,
            /field2:.* value2/m,
          ]

          expected_lines.each do |line|
            expect(raw_body).to match(line)
          end
        end
      end
    end

    include_examples 'Slack'

    context 'where case is for an administrative issue' do
      let(:issue) { create(:administrative_issue) }

      it 'excludes all site email addresses' do
        expect(subject.to).to eq nil
        expect(subject.cc).to match_array []
        expect(subject.bcc).to match_array(['tickets@alces-software.com'])
      end
    end
  end

  describe 'Comment email' do
    subject { CaseMailer.comment(comment) }

    let (:comment) {
      create(:case_comment,
             case: kase,
             user: another_user,
             text: 'I can haz comment'
            )
    }
    let (:notification_method) { :comment_notification }
    let (:slack_args) { [kase, comment] }

    it 'sends an email on case comment being added' do
      expect(subject.to).to eq nil
      expect(subject.cc).to match_array %w(someuser@somecluster.com mailing-list@somecluster.com)
      expect(subject.bcc).to match_array(['tickets@alces-software.com'])

      expect(subject.body.encoded).to match('I can haz comment')
    end


    context 'where case is for an administrative issue' do
      let(:issue) { create(:administrative_issue) }

      it 'excludes all site email addresses' do
        expect(subject.to).to eq nil
        expect(subject.cc).to match_array []
        expect(subject.bcc).to match_array(['tickets@alces-software.com'])
      end
    end

    include_examples 'Slack'
  end

  describe 'Case assignment email' do
    let(:notification_method) { :assignee_notification }

    RSpec.shared_examples 'assignment notifications' do
      it 'sends an email on initial case assignment' do
        expect(subject.to).to eq nil
        expect(subject.cc).to match_array %w(another.user@somecluster.com)
        expect(subject.bcc).to match_array(['tickets@alces-software.com'])

        expect(subject.body.encoded).to match(
          "A Scientist has been set as the assigned #{role} for this case."
        )
      end

      it 'sends an email on case assignment change' do
        kase.assignee = another_user
        mail = CaseMailer.send(mailer_method, kase, another_user.id, requestor.id)

        expect(mail.to).to eq nil
        expect(mail.cc).to match_array %w(someuser@somecluster.com)
        expect(mail.bcc).to match_array(['tickets@alces-software.com'])

        expect(mail.body.encoded).to match(
          /Some User has been set as the assigned #{role} for this case\./
        )
      end
    end

    context 'engineer assignment' do
      subject { CaseMailer.change_assignee_id(kase, nil, another_user.id) }

      let(:role) { 'engineer' }
      let(:mailer_method) { :change_assignee_id }
      let(:slack_args) { [kase, another_user, role] }

      include_examples 'assignment notifications'
      include_examples 'Slack'
    end

    context 'contact assignment' do
      subject { CaseMailer.change_contact_id(kase, nil, another_user.id) }

      let(:role) { 'contact' }
      let(:mailer_method) { :change_contact_id }
      let(:slack_args) { [kase, another_user, 'contact'] }

      include_examples 'assignment notifications'
      include_examples 'Slack'
    end
  end

  describe 'Maintenance emails' do
    let (:text) { "Doesn't look like anything to me" }
    let (:window) { build(:maintenance_window) }

    context 'state transition' do
      subject { CaseMailer.maintenance_state_transition(kase, text) }

      let (:notification_method) { :maintenance_state_transition_notification }
      let (:slack_args) { [kase, text] }

      include_examples 'Slack'
    end

    context 'ending soon' do
      subject { CaseMailer.maintenance_ending_soon(window, text) }

      let (:notification_method) { :maintenance_ending_soon_notification }
      let (:slack_args) { [window.case, text] }

      it 'sets the maintenance_ending_soon_email_sent flag' do
        subject
        expect(window.maintenance_ending_soon_email_sent).to eq(true)
      end

      include_examples 'Slack'
    end
  end

  describe 'Change Request emails' do
    context 'change request event' do
      subject { CaseMailer.change_request(kase, text, requestor, kase.email_recipients) }

      let (:text) { "Request to change please" }
      let (:notification_method) { :change_request_notification }
      let (:slack_args) { [kase, text, requestor] }

      include_examples 'Slack'


      context 'where case is for an administrative issue' do
        let(:issue) { create(:administrative_issue) }

        it 'excludes all site email addresses' do
          expect(subject.to).to eq nil
          expect(subject.cc).to match_array []
          expect(subject.bcc).to match_array(['tickets@alces-software.com'])
        end
      end
    end
  end

  describe 'Case association emails' do
    subject { CaseMailer.change_association(kase, another_user) }

    let(:text) {
      reference_texts = kase.associations
        .map { |a| a.decorate.reference_text }
     %{Changed the affected components on this case to:

• #{reference_texts.join("\n • ")}
    }
    }
    let(:notification_method) { :case_association_notification }
    let(:slack_args) { [kase, another_user, text] }

    include_examples 'Slack'
  end

  describe 'Resolved case emails' do
    subject { CaseMailer.resolve_case(kase, another_user) }

    let(:text) {
      "#{kase.display_id} has been resolved by #{another_user.name} and is awaiting closure"
    }
    let(:notification_method) { :resolved_case_notification }
    let(:slack_args) { [kase, another_user, text] }

    include_examples 'Slack'
  end
end
