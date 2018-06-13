module MarkdownPreview
  WRITE_COMMIT_VALUE = 'markdown_write'.freeze
  PREVIEW_COMMIT_VALUE = 'markdown_preview'.freeze
  COMMIT_VALUES = [WRITE_COMMIT_VALUE, PREVIEW_COMMIT_VALUE].freeze

  def handle_markdown_preview(record, attribute, record_params)
    if !COMMIT_VALUES.include? params[:commit]
      false
    else
      record.send("#{attribute}=", record_params[attribute])
      template = if params[:commit] == PREVIEW_COMMIT_VALUE
                   :preview
                 elsif @note.persisted?
                   :edit
                 else
                   :new
                 end
      render template
    end
  end
end
