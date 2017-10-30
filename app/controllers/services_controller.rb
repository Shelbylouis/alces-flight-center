class ServicesController < ApplicationController
  def show
    @service = Service.find(params[:id])
    @title = "#{@service.name} Dashboard"

    # Show ServiceType name as subtitle, unless this is the same name as the
    # Service and therefore uninteresting.
    service_type = @service.service_type.name
    same_name_as_service = service_type == @service.name
    @subtitle = service_type unless same_name_as_service
  end
end
