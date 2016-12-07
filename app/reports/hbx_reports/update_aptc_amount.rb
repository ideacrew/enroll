require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateAptcAmount < MongoidMigrationTask
  
  def migrate
	families = Family
	families.all.each do |family|
		family.enrollments.by_year(2017).each do |en|

			ehb_premium = en.total_premium
			if en.plan.present? && en.plan.ehb > 0
				ehb_premium = (en.total_premium * en.plan.ehb).round(2)
			end
			if ehb_premium < en.applied_aptc_amount.to_f
				en.update_attribute("applied_aptc_amount", ehb_premium)
				puts "The applied_aptc_amount: #{en.applied_aptc_amount}, ehb_premium: #{ehb_premium} for hbx_id: #{en.hbx_id}"
			end
		end
	end

  end

end