
module SpecUtils
  class << self
    def class_factory_identifier(klass)
      klass.to_s.underscore.to_sym
    end
  end
end
