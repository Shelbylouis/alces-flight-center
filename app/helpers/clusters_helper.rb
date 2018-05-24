module ClustersHelper

  def credit_value_class(value)
    if value.negative? || value.zero?
      'text-danger'
    else
      'text-success'
    end
  end

end
