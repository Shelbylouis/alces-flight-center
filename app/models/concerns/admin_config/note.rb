module AdminConfig::Note
  extend ActiveSupport::Concern

  included do
    rails_admin do
      edit do
        configure :description do
          html_attributes rows: 10, cols: 100
          help Constants::MARKDOWN_DESCRIPTION_EDIT_HELP
        end

        configure :flavour do
          help <<~EOF
            Valid flavours are #{Note::FLAVOURS.join(', ')}.
          EOF
        end
      end
    end
  end
end
