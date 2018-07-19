require 'kramdown/converter/remove_html_tags'

module MarkdownRenderer
  def self.render(markdown_text)
    doc = Kramdown::Document.new(markdown_text || '')
    Kramdown::Converter::RemoveHtmlTags.convert(doc.root,
                                                remove_block_html_tags: true
                                               )
    html_doc = doc.to_html.strip
    if html_doc.empty?
      ''
    else
      "<div class=\"markdown\">\n#{html_doc}\n</div>"
    end
  end
end

def MarkdownColumn(column)
  return Module.new do
    extend ActiveSupport::Concern

    define_method "rendered_#{column}" do
      MarkdownRenderer.render(send(column) || '').html_safe
    end
  end
end

module MarkdownDescription
  include MarkdownColumn(:description)
end
