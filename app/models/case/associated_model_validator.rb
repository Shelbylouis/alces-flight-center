
class Case
  class AssociatedModelValidator < ActiveModel::Validator
    attr_reader :record

    def validate(record)
      @record = record

      Cluster::PART_NAMES.each do |part_name|
        validate_correct_cluster_part_relationship(part_name)
      end
      validate_service_correct_type
    end

    private

    def validate_correct_cluster_part_relationship(part_name)
      part = part(part_name)
      error = if part_required?(part_name)
                if !part
                  "issue requires a #{part_name} but one was not given"
                elsif part.cluster != record.cluster
                  "given #{part_name} is not part of given cluster"
                end
              elsif part
                "issue does not require a #{part_name} but one was given"
              end
      record.errors.add(part_name, error) if error
    end

    def validate_service_correct_type
      if part_required?(:service) && part(:service)
        required_service_type = record.issue.service_type
        return unless required_service_type

        associated_service_type = part(:service).service_type

        if associated_service_type != required_service_type
          error = "must be associated with #{required_service_type.name} " \
            "service but given a #{associated_service_type.name} service"
          record.errors.add(:service, error)
        end
      end
    end

    def part_required?(part_name)
      record.issue.send("requires_#{part_name}")
    end

    def part(part_name)
      record.send(part_name)
    end
  end
end
