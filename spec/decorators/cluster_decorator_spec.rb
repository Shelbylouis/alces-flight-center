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
        cluster.cases = [
          create(:case)
        ]
      end.decorate
    end

    it 'gives correct JSON' do
      text_helper = Class.new do
        include ActionView::Helpers::TextHelper
      end.new

      expect(subject.case_form_json).to eq(
        id: 1,
        name: 'Some Cluster',
        components: subject.components.map(&:case_form_json),
        services: subject.services.map(&:case_form_json),
        supportType: 'managed',
        chargingInfo: '£1000',
        motd: 'Some MOTD',
        motdHtml: text_helper.simple_format('Some MOTD')
      )
    end
  end
end
