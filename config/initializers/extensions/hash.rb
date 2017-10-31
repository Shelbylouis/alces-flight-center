
class Hash
  # From https://stackoverflow.com/a/44122015/2620402.
  def to_struct
    Struct.new(*keys).new(*values)
  end
end
