
class MaintenanceWindow < ApplicationRecord
  class Validator < ActiveModel::Validator
    def validate(record)
      @record = record

      validate_at_least_one_associated_model
      validate_homogenous_cluster
      validate_requested_period
      validate_case_not_administrative
    end

    private

    attr_reader :record
    delegate :requested_start, to: :record

    def validate_at_least_one_associated_model
      unless number_associated_models >= 1
        record.errors.add(
          :base, 'at least one Cluster, Component, or Service must be under maintenance'
        )
      end
    end

    def number_associated_models
      record.associated_models.length
    end

    def validate_requested_period
      return unless requested_start
      validate_start_in_future_if_needed unless record.legacy_migration_mode
    end

    def validate_start_in_future_if_needed
      return if maintenance_period_can_be_passed?
      validate_field_in_future(:requested_start)
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

    def validate_homogenous_cluster
      clusters = record.associated_models.map { |m|
        case m
        when Cluster
          m
        else
          m.cluster
        end
      }.uniq

      unless clusters.length == 1
        record.errors.add(
          :base, 'All associated components must belong to the same cluster'
        )
      end
    end

    def validate_case_not_administrative
      if !record.finished? && record.case&.issue&.administrative?
        record.errors.add(
          :case, 'must not be an administrative case'
        )
      end
    end
  end
end
