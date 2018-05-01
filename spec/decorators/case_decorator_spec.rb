require 'rails_helper'

RSpec.describe CaseDecorator do
  # XXX Parts of these tests and corresponding code duplicated and adapted for
  # {Cluster,Component,Service}Decorator.
  describe '#association_info' do
    let :cluster { subject.cluster }

    context 'when Case has Component' do
      subject do
        create(:case_with_component).decorate.tap do
          Draper::ViewContext.clear!
        end
      end

      let :component { subject.component }

      it 'includes link to Component' do
        expect(
          subject.association_info
        ).to include(
          h.link_to(component.name, h.component_path(component))
        )
      end

      it 'includes link to Cluster' do
        expect(
          subject.association_info
        ).to include(
          h.link_to(cluster.name, h.cluster_path(cluster))
        )
      end
    end

    context 'when Case has Service' do
      subject do
        create(:case_with_service).decorate.tap do
          Draper::ViewContext.clear!
        end
      end

      let :service { subject.service }

      it 'includes link to Service' do
        expect(
          subject.association_info
        ).to include(
          h.link_to(service.name, h.service_path(service))
        )
      end

      # XXX Same as test for Component.
      it 'includes link to Cluster' do
        expect(
          subject.association_info
        ).to include(
          h.link_to(cluster.name, h.cluster_path(cluster))
        )
      end
    end

    context 'when Case has no Component or Service' do
      subject do
        create(:case).decorate.tap do
          Draper::ViewContext.clear!
        end
      end

      it 'returns link to Cluster' do
        expect(
          subject.association_info
        ).to eq(
          h.link_to(cluster.name, h.cluster_path(cluster))
        )
      end
    end
  end

  describe '#credit_charge_info' do
    it 'gives credit charge amount when set' do
      support_case = create(:case)
      create(:credit_charge, case: support_case, amount: 5)

      expect(support_case.decorate.credit_charge_info).to eq '5'
    end

    it "gives 'N/A' when issue is not chargeable" do
      issue = create(:issue, chargeable: false)
      support_case = create(:case, issue: issue)

      expect(support_case.decorate.credit_charge_info).to eq 'N/A'
    end

    it "gives 'Pending' when issue is chargeable and no credit charge" do
      issue = create(:issue, chargeable: true)
      support_case = create(:case, issue: issue)

      expect(support_case.decorate.credit_charge_info).to eq 'Pending'
    end
  end

  describe '#case_link' do
    it 'returns link to Case page with display_id as text' do
      kase = create(:case)
      kase.rt_ticket_id = 12345

      link = kase.decorate.tap do
        Draper::ViewContext.clear!
      end.case_link

      expect(link).to eq h.link_to('RT12345', h.case_path(kase))
    end
  end

  describe '#tier_description' do
    {
      1 => 'Tool',
      2 => 'Routine Maintenance',
      3 => 'General Support',
    }.each do |level, expected_description|
      it "gives correct text for level #{level} Tier" do
        kase = create(:case, tier_level: level).decorate

        expect(kase.tier_description).to eq("#{level} (#{expected_description})")
      end
    end

    it 'raises for unhandled tier_level' do
      # Use `build` as Case with this `tier_level` is currently invalid.
      kase = build(:case, tier_level: 4).decorate

      expect do
        kase.tier_description
      end.to raise_error(RuntimeError, "Unhandled tier_level: 4")
    end
  end

  describe '#display_id' do
    it "gives RT ticket ID with 'RT' prefix when RT ticket ID associated" do
      kase = create(:case, rt_ticket_id: 12345).decorate

      expect(kase.display_id).to eq('RT12345')
    end

    it "gives object ID with '#' prefix when no RT ticket ID associated" do
      kase = create(:case, id: 123).decorate

      expect(kase.display_id).to eq('#123')
    end
  end
end
