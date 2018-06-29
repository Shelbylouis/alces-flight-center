
class Case
  class AssociatedModelValidator < ActiveModel::Validator
    def validate(record)
      @record = record

      Cluster::PART_NAMES.each do |part_name|
        validate_correct_cluster_part_relationship(part_name)
      end
      validate_service_correct_type
    end

    private

    attr_reader :record

    def validate_correct_cluster_part_relationship(part_name)
      if part_required?(part_name)
        parts = parts_of_type(part_name)
        if parts.empty?
          record.errors.add(part_name,  "issue requires a #{part_name} but one was not given")
        else
          parts.each do |part|
            if part.cluster != record.cluster
              record.errors.add(part_name,  "given #{part_name} #{part.name} is not part of given cluster")
            end
          end
        end
      end
    end

    def validate_service_correct_type

      services = parts_of_type(:service)

      if part_required?(:service) && !services.empty?
        required_service_type = record.issue.service_type
        return unless required_service_type

        associated_service_types = services.map(&:service_type)

        unless associated_service_types.include?(required_service_type)
          error = "must be associated with #{required_service_type.name} " \
            "service but not given one"
          record.errors.add(:service, error)
        end
      end
    end

    def part_required?(part_name)
      record.issue.send("requires_#{part_name}")
    end

    def parts_of_type(part_name)
      record.send(part_name.to_s.pluralize.to_sym)
    end
  end
end
