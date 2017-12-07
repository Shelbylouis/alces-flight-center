
module Request
  class << self
    def current_user
      RequestStore.store[:current_user]
    end
  end
end
