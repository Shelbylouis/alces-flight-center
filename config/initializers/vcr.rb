
VCR.configure do |c|
  c.default_cassette_options = { :re_record_interval => 7.days }
end
