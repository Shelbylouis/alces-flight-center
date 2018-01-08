
return unless defined?(VCR)

VCR.configure do |c|
  # Have VCR cassettes be regenerated occasionally, as a last guard against
  # these getting out of date with actual APIs.
  c.default_cassette_options = { :re_record_interval => 30.days }

  # Log most recent debug output from VCR here.
  c.debug_logger = File.open('log/vcr.log', 'w')

  # Filter sensitive data from saved cassettes.
  c.filter_sensitive_data("<RT_USERNAME>") do
    ENV.fetch('RT_USERNAME')
  end
  c.filter_sensitive_data("<RT_PASSWORD>") do
    ENV.fetch('RT_PASSWORD')
  end
  c.filter_sensitive_data("<RT_API_HOST>") do
    ENV.fetch('RT_API_HOST')
  end
  c.filter_sensitive_data("<AWS_ACCESS_KEY_ID>") do
    ENV.fetch('AWS_ACCESS_KEY_ID')
  end
end
