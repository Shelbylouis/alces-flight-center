require 'rails_helper'

RSpec.describe ComponentDecorator do
  describe '#change_support_type_button' do
    let! :request_advice_issue { create(:request_component_becomes_advice_issue) }
    let! :request_managed_issue { create(:request_component_becomes_managed_issue) }

    context 'for managed component' do
      subject do
        create(:managed_component).decorate
      end

      it 'renders correctly' do
        expect(subject.change_support_type_button).to eq(
          h.button_to 'Request self-management',
          h.cases_path,
          class: 'btn btn-danger support-type-button',
          title: request_advice_issue.name,
          params: {
            case: {
              cluster_id: subject.cluster.id,
              component_id: subject.id,
              issue_id: request_advice_issue.id,
              details: 'User-requested from management dashboard'
            }
          },
          data: {
            confirm: "Are you sure you want to request self-management of #{subject.name}?"
          }
        )
      end
    end

    context 'for advice component' do
      subject do
        create(:advice_component).decorate
      end

      it 'renders correctly' do
        expect(subject.change_support_type_button).to eq(
          h.button_to 'Request Alces management',
          h.cases_path,
          class: 'btn btn-success support-type-button',
          title: request_managed_issue.name,
          params: {
            case: {
              cluster_id: subject.cluster.id,
              component_id: subject.id,
              issue_id: request_managed_issue.id,
              details: 'User-requested from management dashboard'
            }
          },
          data: {
            confirm: "Are you sure you want to request Alces management of #{subject.name}?"
          })
      end
    end

    it 'gives nothing for internal Component' do
      component = create(:component, internal: true).decorate

      expect(component.change_support_type_button).to be nil
    end
  end

  describe '#links' do
    subject { create(:component).decorate }

    it 'includes link to Component' do
      expect(
        subject.links
      ).to include(
        h.link_to(subject.name, h.component_path(subject))
      )
    end

    it 'includes link to Cluster' do
      expect(
        subject.links
      ).to include(
        h.link_to(subject.cluster.name, h.cluster_path(subject.cluster))
      )
    end
  end

  describe '#case_form_buttons' do
    subject { create(:component).decorate }

    it 'includes link to Component Case form' do
      expect(subject.case_form_buttons).to include(
        h.new_component_case_path(component_id: subject.id)
      )
    end

    it 'includes link to Component consultancy form' do
      expect(subject.case_form_buttons).to include(
        h.new_component_consultancy_path(component_id: subject.id)
      )
    end
  end
end
