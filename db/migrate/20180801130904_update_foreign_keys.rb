class UpdateForeignKeys < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :check_results, :cluster_checks
    add_foreign_key :check_results, :logs

    add_foreign_key :checks, :check_categories

    add_foreign_key :cluster_checks, :checks
    add_foreign_key :cluster_checks, :clusters
  end
end
