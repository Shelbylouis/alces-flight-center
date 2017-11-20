class AddChargingInfoToClusters < ActiveRecord::Migration[5.1]
  def change
    add_column :clusters, :charging_info, :string
  end
end
