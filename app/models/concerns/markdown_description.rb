require 'kramdown/converter/remove_html_tags'

module MarkdownRenderer
  def self.render(markdown_text)
    doc = Kramdown::Document.new(markdown_text || '')
    Kramdown::Converter::RemoveHtmlTags.convert(doc.root,
                                                remove_block_html_tags: true
                                               )
    "<div class=\"markdown\">#{doc.to_html}</div>".html_safe
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
