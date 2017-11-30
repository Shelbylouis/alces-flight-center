
# From https://stackoverflow.com/a/38811145/2620402.
class KeywordStruct < Struct
  def initialize(**kwargs)
    super(*members.map{|k| kwargs.fetch(k) })
  end
end
