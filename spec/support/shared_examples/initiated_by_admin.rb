RSpec.shared_examples 'it must be initiated by an admin' do
  it 'can be initiated by admin' do
    subject.user = create(:admin)

    expect(subject).to be_valid
  end

  it 'cannot be initiated by contact' do
    subject.user = create(:contact)

    expect(subject).not_to be_valid
    expect(subject.errors.messages).to include user: [/must be an admin/]
  end
end
