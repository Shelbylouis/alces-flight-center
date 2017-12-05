class ConsultancyController < ApplicationController
  def new
    @title = 'Request custom consultancy'

    cluster_id = params[:cluster_id]
    component_id = params[:component_id]
    service_id = params[:service_id]
    @case = Case.new(
      cluster_id: params[:cluster_id],
      component_id: params[:component_id],
      service_id: params[:service_id],
    )

    @case.issue_id = if @case.cluster_id
                       Issue.cluster_consultancy_issue
                     elsif @case.component_id
                       Issue.component_consultancy_issue
                     elsif @case.service_id
                       Issue.service_consultancy_issue
                     end.id
  end
end
