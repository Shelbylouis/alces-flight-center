
class AssetRecordField::DataTypeValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record
    validation_method = :"valid_#{record.definition.data_type}?"
    puts validation_method
    if respond_to? validation_method
      public_send validation_method
    else
      msg = "Can not find validation method '#{validation_method}'"
      record.errors.add :data_type, msg
    end
  end
end

