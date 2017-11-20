
return unless defined?(VCR)

VCR.configure do |c|
  c.default_cassette_options = { :re_record_interval => 7.days }

  # Log most recent debug output from VCR here.
  c.debug_logger = File.open('log/vcr.log', 'w')
end
