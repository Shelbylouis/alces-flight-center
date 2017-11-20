class MakeConsultancyIssuesChargeable < ActiveRecord::DataMigration
  def up
    Issue.all.select do |issue|
      issue.name =~ /consultancy/
    end.map do |issue|
      issue.chargeable = true
      issue.save!
    end
  end
end
