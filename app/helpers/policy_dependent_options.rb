
class PolicyDependentOptions
  def self.wrap(options, **kwargs)
    new(options, **kwargs).wrap
  end

  def wrap
    policy ? options : disabled_options
  end

  private

  attr_reader :options, :policy, :action_description, :user

  def initialize(options, policy:, action_description:, user:)
    @options = options
    @policy = policy
    @action_description = action_description
    @user = user
  end

  def disabled_options
    options.merge(
      disabled: true,
      title: "As a #{user.role} you cannot #{action_description}",
      class: disabled_classes
    )
  end

  def disabled_classes
    Array.wrap(options[:class]) + ['disabled']
  end
end
