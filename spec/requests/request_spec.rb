require 'rails_helper'

class RequestTestsController < ApplicationController
  def show
    @current_user = Request.current_user
    redirect_to root_path
  end
end

# Tests for Request module; because this depends on the handling of the current
# request these need to make actual requests and depend on the above controller
# and corresponding `request_test` being defined.
RSpec.describe Request, type: :request do
  describe '#current_user' do
    let(:user) { create(:user) }

    it 'returns current user when in request' do
      get request_test_path(as: user)

      expect(assigns(:current_user)).to eq(user)
    end

    it 'returns nil when in request and no current user' do
      get request_test_path

      expect(assigns(:current_user)).to be nil
    end

    it 'returns nil when not in request' do
      expect(Request.current_user).to be nil
    end
  end
end
