class ClustersController < ApplicationController
  decorates_assigned :cluster

  def credit_usage
    @accrued = 0
    @used = 0
  end
end
