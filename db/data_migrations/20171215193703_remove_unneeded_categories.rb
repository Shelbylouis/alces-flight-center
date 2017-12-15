class RemoveUnneededCategories < ActiveRecord::DataMigration
  def up
    names_to_keep = ['Application Management', 'End User Assistance']
    Category.all.each do |category|
      category.destroy! unless names_to_keep.include? category.name
    end
  end
end
