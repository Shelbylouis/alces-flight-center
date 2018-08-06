class ClusterChecksController < ApplicationController
  def preview
    @check_result_comment ||= nil
    params.each do |key, value|
      @check_result_comment = value if key.include? 'comment'
    end

    authorize @cluster, :create?

    render layout: false
  end

  def write
    params.each do |key, value|
      @check_result_comment = value if key.include? 'comment'
    end

    authorize @cluster, :create?

    render layout: false
  end
end
