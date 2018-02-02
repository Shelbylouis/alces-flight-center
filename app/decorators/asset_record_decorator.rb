module AssetRecordDecorator
  def edit_asset_record_path
    h.public_send "edit_#{asset_record_path_method_string}", object
  end

  def asset_record_path
    h.public_send asset_record_path_method_string, object
  end

  READ_ONLY_MSG = <<-EOF
    This field can only be set at the individual Component level
  EOF

  def asset_record_form_inputs
    Enumerator.new do |memo|
      object.asset_record.each do |record|
        is_component_level = (record.definition.level == 'component')
        options = {
          class: 'form-control',
          readonly: (is_component_level && !object.is_a?(Component)),
          placeholder: object.find_parent_asset_record(record.definition)
                             .value
        }.tap do |opt|
          if opt[:readonly]
            opt[:style] = 'background-color:lightgray'
            opt[:title] = READ_ONLY_MSG
          end
        end

        memo << [
          record,
          h.text_field_tag(
            record.definition.id,
            (record.asset == model ? record.value : ''),
            **options
          )
        ]
      end
    end
  end

  private

  def asset_record_path_method_string
    "#{asset_model_name}_asset_record_path"
  end

  def asset_model_name
    object.class.to_s.tableize.singularize
  end
end
