
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

  MAX_LONG_TEXT_LENGTH = 500
  MAX_SHORT_TEXT_LENGTH = 50

  def max_length_message(value, length)
    "'#{value}' exceeds the maximum length of #{length}"
  end

  def valid_short_text?
    return if record.value.length <= MAX_SHORT_TEXT_LENGTH
    msg = max_length_message(record.value, MAX_SHORT_TEXT_LENGTH)
    record.errors.add :data_type, msg
  end

  def valid_long_text?
    return if record.value.length <= MAX_LONG_TEXT_LENGTH
    msg = max_length_message(record.value, MAX_LONG_TEXT_LENGTH)
    record.errors.add :data_type, msg
  end
end

