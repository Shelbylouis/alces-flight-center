
module Utils
  class << self
    # Format a hash consisting of string/symbol keys and values into the format
    # expected by the rt API (https://rt-wiki.bestpractical.com/wiki/REST),
    # which is also fairly human readable.
    def rt_format(properties)
      properties.map do |key, value|
        indented_value = value.gsub("\n", "\n ").strip + "\n"
        "#{key}: #{indented_value}"
      end.join("\n").squeeze("\n")
    end
  end
end
