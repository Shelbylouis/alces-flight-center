
RSpec.shared_examples 'case_form_buttons' do |model_name|
  context "when #{model_name} is advice-only" do
    subject { create(:"advice_#{model_name}").decorate }

    it 'disables Case form button' do
      disabled_regex = /<a.* class=".*disabled".*title="This #{model_name}.*self-managed.*".*<\/a>/

      expect(subject.case_form_buttons).to match(disabled_regex)
    end
  end

  context "when #{model_name} is managed" do
    subject { create(:"managed_#{model_name}").decorate }

    it 'does not disable Case form button' do
      expect(subject.case_form_buttons).not_to include('disabled')
    end
  end
end
