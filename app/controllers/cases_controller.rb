class CasesController < ApplicationController
  before_action :require_login

  def index
    @site = current_user.site
  end
end
