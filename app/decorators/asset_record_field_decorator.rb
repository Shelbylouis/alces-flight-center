
class AssetRecordFieldDecorator < ApplicationDecorator
  delegate_all

  READ_ONLY_MSG = <<-EOF
    This field can only be set at the individual Component level
  EOF

  def form_input(current_asset)
    value = (asset == current_asset ? object.value : '')
    options = {
      class: 'form-control',
      readonly: readonly(current_asset),
      placeholder: placeholder(current_asset)
    }.tap do |opt|
      if opt[:readonly]
        opt[:style] = 'background-color:lightgray'
        opt[:title] = READ_ONLY_MSG
      end
    end
    definition.decorate.form_input(value, **options)
  end

  private

  def readonly(current_asset)
    (definition.level == 'component') && !(current_asset.is_a? Component)
  end

  def placeholder(current_asset)
    current_asset.find_parent_asset_record(definition).value
  end
end

