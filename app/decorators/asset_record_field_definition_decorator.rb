
class AssetRecordFieldDefinitionDecorator < ApplicationDecorator
  def form_input(value, **options)
    h.text_field_tag(object.id, value, **options)
  end
end

