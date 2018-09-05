module AdminConfig::TerminalService
  extend ActiveSupport::Concern

  included do
    rails_admin do
      show do
        configure :encrypted_ssh_key do
          hide
        end
      end

      edit do
        configure :ssh_key, :text do
          label 'Private SSH key'
          html_attributes rows: 30, cols: 80
          help <<-EOF
            It will be encrypted before being stored in the database.  Leave
            blank to use the current SSH key.
          EOF
          formatted_value do
            nil
          end
        end
        configure :encrypted_ssh_key do
          hide
        end
      end
    end
  end

  # Creating new TerminalService with rails admin breaks without this
  # method being added.
  def ssh_key
    nil
  end
end
