
class CanonicalNameCreator
  def before_validation(object)
    object.canonical_name = object.name.parameterize
  end
end
