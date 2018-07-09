module AdminConfig::EncryptionKey
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :public_key do
          label 'Public RSA key'
          html_attributes rows: 30, cols: 80
        end
      end
    end
  end
end
