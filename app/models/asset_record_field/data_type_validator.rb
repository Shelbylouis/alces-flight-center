
class AssetRecordField::DataTypeValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    validation_method = :"valid_#{record.definition.data_type}?"
    puts validation_method
    if respond_to?(validation_method, 'include private')
      send validation_method
    else
      msg = "Can not find validation method '#{validation_method}'"
      record.errors.add :data_type, msg
    end
  end

  private

  def valid_short_text?
  end

  def valid_long_text?
  end
end

