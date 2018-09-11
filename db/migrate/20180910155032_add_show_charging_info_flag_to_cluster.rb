class AddShowChargingInfoFlagToCluster < ActiveRecord::Migration[5.2]
  def change
    add_column :clusters, :show_charging_info, :boolean,
      default: true,
      null: false
  end
end
