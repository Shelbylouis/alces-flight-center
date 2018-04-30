# To use ActiveRecord objects directly as arguments to mailers
Resque::Mailer.argument_serializer = Resque::Mailer::Serializers::ActiveRecordSerializer

Resque::Mailer.excluded_environments = [:test]

class Resque::Mailer::MessageDecoy
  # Make interface compatible with existing code
  alias_method :deliver_later, :deliver
end
