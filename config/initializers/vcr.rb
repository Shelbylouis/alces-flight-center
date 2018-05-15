
return unless defined?(VCR)

VCR.configure do |c|
  # Have VCR cassettes be regenerated occasionally, as a last guard against
  # these getting out of date with actual APIs.
  c.default_cassette_options = { :re_record_interval => 30.days }

  # Log most recent debug output from VCR here.
  c.debug_logger = File.open('log/vcr.log', 'w')

  c.ignore_request do |request|
    # Required so tests using Selenium can work, as these need to make
    # requests to URLs like `http://127.0.0.1:34129/__identify__`.
    true if request.uri =~ /^http:\/\/127\.0\.0\.1/
  end

  # Filter sensitive data from saved cassettes, or any other data which will
  # prevent VCR from identifying cassettes as being for the same request in
  # different environments.
  [
    'RT_PASSWORD',

    # These are included in the URL in requests to RT so must be filtered so
    # VCR identifies requests as the same.
    'RT_USERNAME',
    'RT_API_HOST',

    'AWS_ACCESS_KEY_ID',
  ].each do |env_var|
    c.filter_sensitive_data("<#{env_var}>") do
      ENV.fetch(env_var)
    end
  end
end
