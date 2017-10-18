
module MarkdownDescription
  extend ActiveSupport::Concern

  def rendered_description
    Markdown.new(description).to_html
  end
end
