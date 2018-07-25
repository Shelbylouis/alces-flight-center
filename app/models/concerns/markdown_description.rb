module MarkdownRenderer
  def self.render(markdown_text)
    html_doc = CommonMarker.render_doc(
      markdown_text || '', :SMART, [
        :table,
        :tagfilter,
        :autolink,
        :strikethrough,
      ]
    ).to_html(
      [
        :GITHUB_PRE_LANG,
        :HARDBREAKS,
        :SAFE,
      ]
    ).strip
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
