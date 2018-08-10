require 'rails_helper'

RSpec.describe CaseCommenting do
  subject { CaseCommenting.new(kase, user) }
  let(:kase) { create("#{state}_case".to_sym) }
  let(:user) { create(:user) }

  RSpec.shared_examples 'commenting enabled' do
    it 'should have commenting enabled' do
      expect(subject).not_to be_disabled
      expect(subject.disabled_text).to eq('')
    end
  end

  RSpec.shared_examples 'commenting disabled for viewer' do
    context 'for viewer' do
      let(:user) { create(:viewer) }

      it 'should have commenting disabled' do
        expect(subject).to be_disabled
        expect(subject.disabled_text).to eq(
          'As a viewer you cannot comment on cases.'
        )
      end
    end
  end

  context 'when Case is not open' do
    let(:state) { :resolved }

    RSpec.shared_examples 'commenting disabled as not open' do
      it 'should have commenting disabled' do
        expect(subject).to be_disabled
        expect(subject.disabled_text).to eq(
          "Commenting is disabled as this case is #{state}."
        )
      end
    end

    include_examples 'commenting disabled for viewer'

    context 'for admin' do
      let(:user) { create(:admin) }

      include_examples 'commenting disabled as not open'
    end

    context 'for contact' do
      let(:user) { create(:contact) }

      include_examples 'commenting disabled as not open'
    end
  end

  context 'when Case is open' do
    let(:state) { :open }

    context 'when Case is consultancy' do
      before :each do
        allow(kase).to receive(:consultancy?).and_return(true)
      end

      include_examples 'commenting disabled for viewer'

      context 'for admin' do
        let(:user) { create(:admin) }

        include_examples 'commenting enabled'
      end

      context 'for contact' do
        let(:user) { create(:contact) }

        include_examples 'commenting enabled'
      end
    end

    context 'when Case is not consultancy' do
      before :each do
        allow(kase).to receive(:consultancy?).and_return(false)
      end

      include_examples 'commenting disabled for viewer'

      context 'for admin' do
        let(:user) { create(:admin) }

        include_examples 'commenting enabled'
      end

      context 'for contact' do
        let(:user) { create(:contact) }

        it 'should have commenting disabled' do
          expect(subject).to be_disabled
          expect(subject.disabled_text).to include(
            'Additional discussion is not available'
          )
        end

        context 'when commenting explicitly enabled' do
          before :each do
            allow(kase).to receive(:comments_enabled).and_return(true)
          end

          include_examples 'commenting enabled'
        end
      end
    end
  end
end
