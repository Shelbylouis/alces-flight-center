
module MarkdownDescription
  extend ActiveSupport::Concern

  def rendered_description
    Kramdown::Document.new(description).to_html
  end
end
