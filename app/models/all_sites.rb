class AllSites
  include Draper::Decoratable
  def cases
    Case.all
  end

  def readable_model_name
    'All Sites'
  end

  def ==(other_object)
    other_object.is_a?(AllSites)
  end
end
