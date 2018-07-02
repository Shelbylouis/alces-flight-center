require 'rails_helper'

RSpec.describe CaseDecorator do
  describe '#case_link' do
    it 'returns link to Case page with display_id as text' do
      kase = create(:case, rt_ticket_id: 12345)

      link = kase.decorate.case_link

      expect(link).to eq h
        .link_to('RT12345', h.cluster_case_path(kase.cluster, kase), title: kase.subject)
    end
  end

  describe '#tier_description' do
    {
      1 => 'Tool',
      2 => 'Routine Maintenance',
      3 => 'General Support',
      4 => 'Change request',
    }.each do |level, expected_description|
      it "gives correct text for level #{level} Tier" do
        kase = build(:case, tier_level: level).decorate

        expect(kase.tier_description).to eq("#{level} (#{expected_description})")
      end
    end

    it 'raises for unhandled tier_level' do
      # Use `build` as Case with this `tier_level` is currently invalid.
      kase = build(:case, tier_level: 5).decorate

      expect do
        kase.tier_description
      end.to raise_error(RuntimeError, "Unhandled tier_level: 5")
    end
  end

  describe '#issue_type_text' do
    let(:issue) { create(:issue, name: 'My issue', category: category) }

    let(:kase) { create(:open_case, issue: issue) }

    subject do
      kase.decorate.issue_type_text
    end

    context 'without a category' do
      let(:category) { nil }
      it 'returns issue name' do
        expect(subject).to eq issue.name
      end
    end

    context 'with a category' do
      let(:category) { create(:category, name: 'My Category') }
      it 'returns combination of category and issue name' do
        expect(subject).to eq "#{category.name}: #{issue.name}"
      end
    end

  end
end
