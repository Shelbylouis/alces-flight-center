require "openssl"

#
# Public key pair to encrypt private ssh keys.
#
class EncryptionKey < ActiveRecord::Base

  include AdminConfig::EncryptionKey

  validates :public_key,
    presence: true

  def self.encrypt(string)
    first.encrypt(string)
  end

  def encrypt(string)
    # We're explicit about the padding used as the default used by the Ruby
    # OpenSSL bindings and the default used by the nodejs bindings are not the
    # same.
    padding = OpenSSL::PKey::RSA::PKCS1_PADDING
    Base64.strict_encode64(public_key.public_encrypt(string, padding))
  end

  def public_key
    @public_key ||= OpenSSL::PKey::RSA.new(super)
  end
end
