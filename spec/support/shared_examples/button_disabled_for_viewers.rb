
RSpec.shared_examples 'button is disabled for viewers' do |args|
  args ||= {}
  button_tag = args.fetch(:button_tag, 'button')

  let :button do
    visit path
    find(button_tag, text: button_text)
  end

  context 'for viewer' do
    let :user do
      create(:viewer, site: site)
    end

    it 'has disabled button' do
      expect(button).to be_disabled
      expect(button[:class]).to include('disabled')
      expect(button[:title]).to eq(disabled_button_title)
    end
  end

  context 'for non-viewer' do
    let(:user) do
      create(:contact, site: site)
    end

    it 'does not have disabled button' do
      expect(button).not_to be_disabled
      expect(button[:class]).not_to include('disabled')
      expect(button[:title]).to be nil
    end
  end
end
