class UsersController < ApplicationController
  def show
    if current_user.nil?
      render json: nil
      return
    end
    render json: {
      name: current_user.name,
      role: current_user.role,
    }
  end
end
