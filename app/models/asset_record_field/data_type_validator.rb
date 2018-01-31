
class AssetRecordField::DataTypeValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    validation_method = :"valid_#{record.definition.data_type}?"
    if respond_to?(validation_method, 'include private')
      send validation_method
    else
      msg = "Can not find validation method '#{validation_method}'"
      record.errors.add :data_type, msg
    end
  end

  private

  MAX_SHORT_TEXT_LENGTH = 50

  def valid_short_text?
    return if record.value.length <= MAX_SHORT_TEXT_LENGTH
    msg = <<-EOF.squish
      '#{record.value}' exceeds the maximum length of
      #{MAX_SHORT_TEXT_LENGTH}
    EOF
    record.errors.add :data_type, msg
  end

  def valid_long_text?
  end
end

