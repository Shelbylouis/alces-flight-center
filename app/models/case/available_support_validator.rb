
class Case
  class AvailableSupportValidator < ActiveModel::Validator
    def validate(record)
      @record = record

      validate_can_only_request_consultancy_support_for_advice_part
    end

    private

    attr_reader :record

    def associated_models
      record.component_groups +
          record.components +
          record.services +
          [record.cluster]
    end

    def validate_can_only_request_consultancy_support_for_advice_part
      # This rule does not apply to Cases for special Issues, which are created
      # via separate buttons outside of the standard Case form.
      return if record.issue.special?

      return if record.consultancy?
      associated_models.each do |associated_model|
        if associated_model&.advice?
          record.errors.add(associated_model.readable_model_name, advice_part_error)
        end
      end
    end

    def advice_part_error
      "is #{SupportType::ADVICE_TEXT}, only consultancy support may be requested"
    end
  end
end
