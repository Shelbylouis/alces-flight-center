module WaitForClusterTree

  def wait_for_cluster_tree
    # Waits for the data-initialized attribute to be added to the cluster tree
    # at end of initialisation.

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until cluster_tree_initialised?
    end
  end

  private

  def cluster_tree_initialised?
    page.evaluate_script('$ !== undefined && $(".cluster-tree").data("initialised")')
  end

end

RSpec.configure do |config|
  config.include WaitForClusterTree, type: :feature
end
