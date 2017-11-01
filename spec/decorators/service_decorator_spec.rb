require 'rails_helper'

RSpec.describe ServiceDecorator do
  describe '#change_support_type_button' do
    # These tests are almost the same as those for
    # `ComponentDecorator#change_support_type_button`.

    let! :request_advice_issue { create(:request_service_becomes_advice_issue) }
    let! :request_managed_issue { create(:request_service_becomes_managed_issue) }

    context 'for managed service' do
      subject do
        create(:managed_service).decorate
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
              service_id: subject.id,
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

    context 'for advice service' do
      subject do
        create(:advice_service).decorate
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
              service_id: subject.id,
              issue_id: request_managed_issue.id,
              details: 'User-requested from management dashboard'
            }
          },
          data: {
            confirm: "Are you sure you want to request Alces management of #{subject.name}?"
          })
      end
    end
  end
end
