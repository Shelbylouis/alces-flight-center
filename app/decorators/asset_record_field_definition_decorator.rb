
class AssetRecordFieldDefinitionDecorator < ApplicationDecorator
  READ_ONLY_MSG = <<-EOF
    This field can only be set at the individual Component level
  EOF

  def form_input(value, asset)
    options = {
      class: 'form-control',
      readonly: readonly(asset),
      placeholder: placeholder(asset)
    }.tap do |opt|
      if opt[:readonly]
        opt[:style] = 'background-color:lightgray'
        opt[:title] = READ_ONLY_MSG
      end
    end

    h.text_field_tag(object.id, value, **options)
  end

  private

  def readonly(asset)
    (object.level == 'component') && !(asset.is_a? Component)
  end

  def placeholder(asset)
    asset.find_parent_asset_record(object).value
  end
end

