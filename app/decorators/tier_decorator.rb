class TierDecorator < ApplicationDecorator
  delegate_all

  def case_form_json
    {
      id: id,
      level: level,
    }.merge(fields_or_tool_json)
  end

  private

  def fields_or_tool_json
    if fields
      {fields: fields}
    else
      {tool: tool}
    end
  end
end
