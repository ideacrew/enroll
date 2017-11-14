# Notice to 1/1/2018 Renewal EEs Dental Carriers are Exiting SHOP in 2018
# RAILS_ENV=production bundle exec rake migrations:notify_renewal_employees_dental_carriers_exiting_shop

namespace :migrations do
  desc "Notify Renewal Employees of dental plan carriers are exiting SHOP market"
  task :notify_renewal_employees_dental_carriers_exiting_shop => :environment do |task, args|
    hbx_ids = ["19814254", "19877154", "19942484", "19762647", "19766095", "19928514", "19757938", "19758867", "19758885", "19752871", "19823559", "19823561", "19956666", "19919361", "19919211", "19880909", "19880416", "19881565", "19881402", "19881015", "19880548", "19880417", "19881537", "19821076", "19825599", "19745089", "19759490", "19762739", "19744203", "19885915", "19936491", "158398", "19761660", "19776417", "19897691", "19776288", "19832668", "19850252", "19832807", "19960990", "19952270", "19943290", "19938673", "19929288", "19913723", "19909640", "19881294", "19880308", "19891114", "19881154", "19880500", "19894231", "19894227", "19881148", "19880339", "19881295", "19894229", "19894228", "19881162", "19881504", "19894225", "19881282", "19878730", "19894237", "19880567", "19894226", "19894242", "19880384", "19880335", "19900475", "19882204", "19882205", "19894719"]
    
    hbx_ids.each do |hbx_id|
      begin
        person = Person.where(hbx_id: hbx_id).first
       	enrollments = person.primary_family.active_household.hbx_enrollments.by_coverage_kind("dental").shop_market.select{ |enr| enr.plan.present?}
        enrollments.each do |hbx_enrollment|
          if ["Delta Dental", "MetLife"].include?(hbx_enrollment.plan.carrier_profile.organization.legal_name)
            ShopNoticesNotifierJob.perform_later(hbx_enrollment.census_employee.id.to_s, "notify_renewal_employees_dental_carriers_exiting_shop", hbx_enrollment: hbx_enrollment)
          end 
        end
      rescue Exception => e
        Rails.logger.error {"Unable to deliver dental carriers exiting shop notice to employees #{hbx_id} due to #{e}"}) unless Rails.env.test?
      end
    end
  end
end
