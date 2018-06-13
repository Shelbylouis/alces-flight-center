
RSpec.shared_examples 'button is disabled for viewers' do |args|
  args ||= {}
  button_link = args.fetch(:button_link, false)

  let :button do
    visit path

    if button_link
      # Just find the link, `disabled` attribute does not do anything by
      # default to `a` tags and is not a supported argument to `find_link`.
      find_link(button_text)
    else
      # Find the button, whether or not it is `disabled`.
      find_button(button_text, disabled: :all)
    end
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
