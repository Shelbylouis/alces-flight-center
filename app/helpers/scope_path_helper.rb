module ScopePathHelper
  def method_missing(s, *a, &b)
    if respond_to_missing?(s, *a) == :scope_path
      send(convert_scope_path(s, a[0]), *a, &b)
    else
      super
    end
  end

  def respond_to_missing?(s, *_a)
    s.match?(/\A(.+_)?scope_(.+_)?path\Z/) ? :scope_path : super
  end

  private

  def convert_scope_path(s, scope)
    class_name = "_#{scope.class.to_s.underscore}_"
    (s.match(/\Ascope_.*/) ? "_#{s}" : s.to_s).sub(/_scope_/, class_name)
                                              .sub(/\A_/, '')
                                              .to_sym
  end
end

