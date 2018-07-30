require 'rails_helper'

RSpec.describe ClusterDecorator do
  subject { create(:cluster).decorate }

  describe '#links' do
    it 'returns link to Cluster' do
      expect(
        subject.links
      ).to eq(
        h.link_to(subject.name, h.cluster_path(subject))
      )
    end
  end

  describe '#case_form_json' do
    subject do
      create(
        :cluster,
        id: 1,
        name: 'Some Cluster',
        support_type: :managed,
        charging_info: '£1000',
        motd: 'Some MOTD',
      ).tap do |cluster|
        cluster.components = [create(:component, cluster: cluster)]
        cluster.services = [create(:service, cluster: cluster)]
      end.decorate
    end

    let :standard_expected_services_json do
      subject.services.map(&:case_form_json)
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to match(
        id: 1,
        name: 'Some Cluster',
        components: subject.components.map(&:case_form_json),
        services: array_including(standard_expected_services_json),
        supportType: 'managed',
        chargingInfo: '£1000',
        motd: 'Some MOTD',
        motdHtml: h.simple_format('Some MOTD')
      )
    end

    context 'when issue with `requires_service: false` exists' do
      let! :issue do
        create(:issue, requires_service: false, name: 'Other')
      end

      it "includes additional injected 'Other' Service" do
        injected_service_id = -1

        result = subject.case_form_json
        services = result[:services]

        expect(services).to match(
          array_including(
            hash_including({
              id: injected_service_id,
              name: 'Other / N/A',
              supportType: 'managed',
            })
          )
        )
        injected_service = services.find {|s| s[:id] == injected_service_id}
        expect(injected_service[:issues]).to match(
          array_including(issue.decorate.case_form_json)
        )
      end
    end

    context 'when issue with `requires_service: false` does not exist' do
      it 'does not include additional injected Service' do
        result = subject.case_form_json
        services = result[:services]

        expect(services).to eq(standard_expected_services_json)
      end
    end
  end
end
