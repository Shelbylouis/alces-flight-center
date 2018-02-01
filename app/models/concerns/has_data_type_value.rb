
module HasDataTypeValue
  extend ActiveSupport::Concern
  include ActiveModel::Validations

  attr_reader :record

  included do
    validates :value,
              length: { maximum: 50 },
              if: :data_type_short_text?

    validates :value,
              length: { maximum: 500 },
              if: :data_type_long_text?
  end

  private

  VALID_DATA_TYPES = ['short_text', 'long_text'].tap do |types|
    types.each do |current_valid_type|
      define_method(:"data_type_#{current_valid_type}?") do
        definition.data_type == current_valid_type
      end
    end
  end
end

