
class MaintenanceWindow
  class Validator < ActiveModel::Validator
    def validate(record)
      @record = record

      validate_precisely_one_associated_model
      validate_requested_period
    end

    private

    attr_reader :record
    delegate :requested_start, :requested_end, to: :record

    def validate_precisely_one_associated_model
      record.errors.add(
        :base, 'precisely one Cluster, Component, or Service can be under maintenance'
      ) unless number_associated_models == 1
    end

    def number_associated_models
      [
        record.cluster,
        record.component,
        record.service
      ].select(&:present?).length
    end

    def validate_requested_period
      return unless requested_start && requested_end
      validate_start_before_end
      validate_start_or_end_in_future_if_needed unless record.legacy_migration_mode
    end

    def validate_start_before_end
      if requested_start > requested_end
        record.errors.add(:requested_end, 'must be after start')
      end
    end

    def validate_start_or_end_in_future_if_needed
      return if maintenance_period_can_be_passed?
      validate_field_in_future(:requested_start)
      validate_field_in_future(:requested_end)
    end

    def maintenance_period_can_be_passed?
      # In any of these states the maintenance period can be passed, otherwise
      # existing saved MaintenanceWindows would become invalidated.
      #
      # Note in particular that the maintenance period can be passed when
      # maintenance is only `started` to allow maintenance which has not been
      # progressed on time to be caught up to the state it should be in (e.g. if
      # we did not progress MWs for a while for some reason); without this the MW
      # would be invalid when the `confirmed` -> `started` transition happened,
      # as it should already be `ended`.
      [
        :cancelled,
        :ended,
        :expired,
        :rejected,
        :started,
      ].include?(record.state.to_sym)
    end

    def validate_field_in_future(field_name)
      field = send(field_name)
      if field.past?
        record.errors.add(field_name, 'cannot be in the past')
      end
    end
  end
end
