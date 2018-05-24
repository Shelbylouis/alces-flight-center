
module Utils
  class << self
    # From https://stackoverflow.com/a/7987501.
    def generate_password(length:)
      SecureRandom.urlsafe_base64(length).delete('_-')[0, length]
    end
  end
end
