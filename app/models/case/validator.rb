
class Case
  class Validator < ActiveModel::Validator
    attr_reader :record

    private

    def part_required?(part_name)
      record.issue.send("requires_#{part_name}")
    end

    def part(part_name)
      record.send(part_name)
    end
  end
end
