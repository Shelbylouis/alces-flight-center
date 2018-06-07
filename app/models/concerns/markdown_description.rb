require 'kramdown/converter/remove_html_tags'

module MarkdownDescription
  extend ActiveSupport::Concern

  def rendered_description
    doc = Kramdown::Document.new(description || '')
    Kramdown::Converter::RemoveHtmlTags.convert(doc.root,
                                                remove_block_html_tags: true
                                               )
    doc.to_html
  end
end
