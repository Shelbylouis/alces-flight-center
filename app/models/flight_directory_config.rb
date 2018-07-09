class FlightDirectoryConfig < ApplicationRecord
  include AdminConfig::FlightDirectoryConfig

  belongs_to :site

  validates :hostname, presence: true
  validates :username, presence: true

  validates :encrypted_ssh_key,
    presence: true,
    length: {maximum: 4 * 1024}

  def ssh_key=(plaintext_ssh_key)
    return if plaintext_ssh_key.empty?
    self.encrypted_ssh_key = EncryptionKey.encrypt(plaintext_ssh_key)
  end
end
