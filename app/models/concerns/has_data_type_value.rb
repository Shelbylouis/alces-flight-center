
module HasDataTypeValue
  extend ActiveSupport::Concern
  include ActiveModel::Validations

  attr_reader :record

  MAX_LONG_TEXT_LENGTH = 500

  included do
    validates :value,
              length: { maximum: 50 }
  end

  def max_length_message(value, length)
    "'#{value}' exceeds the maximum length of #{length}"
  end

  def valid_long_text?
    return if record.value.length <= MAX_LONG_TEXT_LENGTH
    msg = max_length_message(record.value, MAX_LONG_TEXT_LENGTH)
    record.errors.add :data_type, msg
  end
end

