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

  describe 'Case creation email' do
    subject { CaseMailer.new_case(kase) }

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
            /Associated component:.* node01/m,
            /Associated service:.* Some service/m,
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

    it 'sends a notification to Slack' do
      expect(SlackNotifier).to receive(:case_notification).with(kase)
      subject
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

    it 'sends an email on case comment being added' do
      expect(subject.to).to eq nil
      expect(subject.cc).to match_array %w(someuser@somecluster.com mailing-list@somecluster.com)
      expect(subject.bcc).to match_array(['tickets@alces-software.com'])

      expect(subject.body.encoded).to match('I can haz comment')
    end

    it 'sends a notification to Slack' do
      expect(SlackNotifier).to receive(:comment_notification).with(kase, comment)
      subject
    end
  end

  describe 'Case assignment email' do
    subject { CaseMailer.change_assignee(kase, another_user) }

    it 'sends an email on initial case assignment' do
      expect(subject.to).to eq nil
      expect(subject.cc).to match_array %w(another.user@somecluster.com)
      expect(subject.bcc).to match_array(['tickets@alces-software.com'])

      expect(subject.body.encoded).to match('This case has now been assigned to A Scientist.')
    end

    it 'sends an email on case assignment change' do
      kase.assignee = another_user
      mail = CaseMailer.change_assignee(kase, requestor)

      expect(mail.to).to eq nil
      expect(mail.cc).to match_array %w(someuser@somecluster.com)
      expect(mail.bcc).to match_array(['tickets@alces-software.com'])

      expect(mail.body.encoded).to match(/This case has now been assigned to Some User\./)
    end

    it 'sends a notification to Slack' do
      expect(SlackNotifier).to receive(:assignee_notification).with(kase, another_user)
      subject
    end
  end

  describe 'Maintenance emails' do
    let (:text) { "Doesn't look like anything to me" }
    let(:window) { build(:maintenance_window) }

    context 'state transition' do
      subject { CaseMailer.maintenance_state_transition(kase, text) }

      it 'sends a notification to Slack' do
        expect(SlackNotifier).to receive(:maintenance_state_transition_notification)
          .with(kase, text)
        subject
      end
    end

    context 'ending soon' do
      subject { CaseMailer.maintenance_ending_soon(window, text) }

      it 'sends a notification to Slack' do
        expect(SlackNotifier).to receive(:maintenance_ending_soon_notification)
          .with(window.case, text)
        subject
      end

      it 'sets the maintenance_ending_soon_email_sent flag' do
        subject
        expect(window.maintenance_ending_soon_email_sent).to eq(true)
      end
    end
  end

  describe 'Change Request emails' do
    let (:text) { "Request to change please" }
    context 'change request event' do
      subject { CaseMailer.change_request(kase, text, requestor) }
      it 'sends a notification to Slack' do
        expect(SlackNotifier).to receive(:change_request_notification)
          .with(kase, text, requestor)
        subject
      end
    end
  end
end
