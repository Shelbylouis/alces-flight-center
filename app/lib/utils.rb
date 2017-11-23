
module Utils
  class << self
    # Format a hash consisting of string/symbol keys and values into the format
    # expected by the rt API (https://rt-wiki.bestpractical.com/wiki/REST),
    # which is also fairly human readable.
    def rt_format(properties)
      properties.map do |key, value|
        indented_value = value.to_s.gsub("\n", "\n ").strip + "\n"
        "#{key}: #{indented_value}"
      end.join("\n").squeeze("\n")
    end

    # From https://stackoverflow.com/a/7987501.
    def generate_password(length:)
      SecureRandom.urlsafe_base64(length).delete('_-')[0, length]
    end
  end
end
