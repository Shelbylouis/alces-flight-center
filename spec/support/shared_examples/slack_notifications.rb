
RSpec.shared_examples 'Slack' do
  it 'sends a notification to Slack' do
    expect(SlackNotifier).to receive(notification_method)
      .with(*args)
    subject
  end
end
