# This rake task used to generate dry run report for MA NFP.
# To run task: RAILS_ENV=production rake dry_run:reports:nfp start_on_date="1/1/2020"

require 'csv'

namespace :dry_run do
  namespace :reports do

    desc "deatiled, non deatiled and unassigned packge reports for NFP"
    task :nfp => :environment do
      
      def assign_packages(start_on_date)
        file_name = "#{Rails.root}/unnassigned_packages_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
        system("rm -rf #{file_name}")
        CSV.open(file_name, "w") do |csv|
          csv << ["Sponsor fein", "Sponsor legal_name", "Census_Employee", "ce id"]
            BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications.effective_period.min'=>start_on_date).each do |ben_spon|
              ben_spon.benefit_applications.each do |bene_app|
                if bene_app.effective_period.min == start_on_date && bene_app.is_renewing?
                  bene_app_2018 = ben_spon.benefit_applications.where(:"effective_period.min".lt=>start_on_date, aasm_state: :active).first
                  ben_spon.census_employees.active.each do |census|
                    if census.employee_role.present?
                      if census.benefit_group_assignments.where(:benefit_package_id.in => bene_app.benefit_packages.map(&:id)).blank?
                        unless census.aasm_state == "employment_terminated" || census.aasm_state == "rehired" ||  census.aasm_state == "cobra_terminated"
                      data = [ben_spon.fein, ben_spon.legal_name, census.full_name, census.id]  
                      csv << data
                      end
                    end
                  end
                  puts "#{ben_spon.fein} has errors #{ben_spon.errors}" if ben_spon.errors.present? unless Rails.env.test?
                end
              end
            end
          end
          puts "Unnasigned packages file created #{file_name}" unless Rails.env.test?
        end
      end

      def detailed_report(start_on_date)
        file_name = "#{Rails.root}/dry_run_ma_nfp_detailed_report_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
        field_names = ["Employer Legal Name",
                      "Employer FEIN",
                      "Employer HBX ID",
                      "#{start_on_date.prev_year.year} effective_date",
                      "#{start_on_date.prev_year.year} State",
                      "#{start_on_date.year} effective_date",
                      "#{start_on_date.year} State",
                      "First name",
                      "Last Name",
                      "Roster status",
                      "Hbx ID",
                      "#{start_on_date.prev_year.year} enrollment",
                      "#{start_on_date.prev_year.year} enrollment kind",
                      "#{start_on_date.prev_year.year} plan",
                      "#{start_on_date.prev_year.year} effective_date",
                      "#{start_on_date.prev_year.year} status",
                      "#{start_on_date.year} enrollment",
                      "#{start_on_date.year} enrollment kind",
                      "#{start_on_date.year} plan",
                      "#{start_on_date.year} effective_date",
                      "#{start_on_date.year} status",
                      "Reasons"
                     ]

        system("rm -rf #{file_name}")

        CSV.open(file_name, "w", force_quotes: true) do |csv|
          csv << field_names
          begin 
            BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications.effective_period.min'=>start_on_date).each do |ben_spon|
              ben_spon.benefit_applications.each do |ben_app|

                if ben_app.effective_period.min == start_on_date && ben_app.is_renewing?
                  ben_app_prev_year = ben_spon.benefit_applications.where(:"effective_period.min".lt=>start_on_date, aasm_state: :active).first
                  ben_spon.census_employees.active.each do |census|
                    if census.employee_role.present?
                      family = census.employee_role.person.primary_family
                    elsif Person.by_ssn(census.ssn).present? && Person.by_ssn(census.ssn).employee_roles.select{|e| e.census_employee_id == census.id && e.is_active == true}.present?
                      person = Person.by_ssn(census.ssn).first
                      family = person.primary_family
                    end
                    if family.present?
                      ben_app_prev_year = ben_spon.benefit_applications.where(:"effective_period.min".lt =>start_on_date, aasm_state: :active).first
                      packages_prev_year = ben_app_prev_year.present? ? ben_app_prev_year.benefit_packages.map(&:id) : []
                      package_ids = packages_prev_year + ben_app.benefit_packages.map(&:id)
                      enrollments = family.active_household.hbx_enrollments.where(:sponsored_benefit_package_id.in=>package_ids, :aasm_state.nin=>["shopping","coverage_canceled","coverage_expired"])
                    end

                    next unless enrollments
                    ["health", "dental"].each do |kind|
                      enrollment_prev_year = enrollments.where(coverage_kind: kind, :"effective_on".lt=> start_on_date).first
                      enrollment_current_year = enrollments.where(coverage_kind: kind, :effective_on=> start_on_date).first
                      next unless enrollment_prev_year || enrollment_current_year
                      data = [ben_spon.profile.legal_name,
                              ben_spon.profile.fein,
                              ben_spon.profile.hbx_id,
                              ben_app_prev_year.try(:effective_period).try(:min),
                              ben_app_prev_year.try(:aasm_state),
                              ben_app.effective_period.min,
                              "renewing_#{ben_app.aasm_state}",
                              census.first_name,
                              census.last_name,
                              census.aasm_state,
                              census.try(:employee_role).try(:person).try(:hbx_id) || Person.by_ssn(census.ssn).first.hbx_id,
                              enrollment_prev_year.try(:hbx_id),
                              enrollment_prev_year.try(:coverage_kind),
                              enrollment_prev_year.try(:product).try(:hios_id),
                              enrollment_prev_year.try(:effective_on),
                              enrollment_prev_year.try(:aasm_state),
                              enrollment_current_year.try(:hbx_id),
                              enrollment_prev_year.try(:coverage_kind),
                              enrollment_current_year.try(:product).try(:hios_id),
                              enrollment_current_year.try(:effective_on),
                              enrollment_current_year.try(:aasm_state),
                              ]
                      data += [find_failure_reason(enrollment_prev_year, enrollment_current_year, ben_app)]
                      csv << data
                    end
                  end
                end
              end
            end
            puts "Successfully generated detailed_report #{file_name}"
          rescue => e
            puts "#{e}"
          end
        end
      end

      def find_failure_reason(enrollment_prev_year, enrollment_current_year, ben_app)
        current_year_state = enrollment_current_year.try(:aasm_state)
        prev_year_state = enrollment_prev_year.try(:aasm_state)
        rp_id = enrollment_prev_year.product.renewal_product_id rescue nil
        cp_id = enrollment_current_year.product.id rescue nil

        if current_year_state == "auto_renewing"
          return "Successfully Generated"
        elsif current_year_state == "coverage_enrolled"
          return "The plan year was manually published by stakeholders" if ["active","enrollment_eligible"].include?(ben_app.aasm_state)
        elsif current_year_state == "coverage_selected"
          unless rp_id == cp_id
             return "Plan was manually selected for the current year" 
          end
        elsif ["inactive","renewing_waived"].include?(current_year_state)
          return "enrollment is waived"
        elsif current_year_state == nil && ben_app.aasm_state == 'pending'
         return "ER zip code is not in DC"
        elsif current_year_state == nil && prev_year_state.in?(HbxEnrollment::WAIVED_STATUSES + HbxEnrollment::TERMINATED_STATUSES)
          return "Previous plan has waived or terminated and did not generate renewal"
        elsif ["coverage_selected", "coverage_enrolled"].include?(prev_year_state) && current_year_state == nil
          unless rp_id == cp_id
            return "Enrollment plan was changed either for current year or previous year"
          end
        else 
          return ""
        end
      end

      def non_detailed_report(start_on_date)
        file_name = "#{Rails.root}/ma_nfp_non_detailed_report_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.csv"
        field_names  = [
          "Employer_Legal_Name",
          "Employer_FEIN",
          "Renewal State",
          "#{start_on_date.prev_year.year} Active Enrollments",
          "#{start_on_date.prev_year.year} Passive Renewal Enrollments"
        ]
        system("rm -rf #{file_name}")

        CSV.open(file_name, "w", force_quotes: true) do |csv|
          csv << field_names
          begin
            BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:'benefit_applications.effective_period.min'=>start_on_date).each do |ben_spon|
              ben_spon.benefit_applications.each do |bene_app|
                if bene_app.effective_period.min == start_on_date && bene_app.is_renewing?
                  data =  [ben_spon.legal_name, ben_spon.fein, ben_spon.renewal_benefit_application.aasm_state.to_s.camelcase]
                  next if ben_spon.renewal_benefit_application.blank?
                  active_bg_ids = ben_spon.current_benefit_application.benefit_packages.pluck(:id)
                  families = Family.where(:"households.hbx_enrollments" => {:$elemMatch => {:sponsored_benefit_package_id.in => active_bg_ids, :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
                    }})
                  if ben_spon.renewal_benefit_application.present?
                    renewal_bg_ids = ben_spon.renewal_benefit_application.benefit_packages.pluck(:id)
                  end

                  active_enrollment_count = 0
                  renewal_enrollment_count = 0
                  families.each do |family|
                        enrollments = family.active_household.hbx_enrollments.where({
                          :sponsored_benefit_package_id.in => active_bg_ids,
                          :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES
                        })
                        %w(health dental).each do |coverage_kind|
                          if enrollments.where(:coverage_kind => coverage_kind).present?
                            active_enrollment_count += 1
                          end
                        end

                        if renewal_bg_ids.present?
                          renewal_enrollments = family.active_household.hbx_enrollments.where({
                            :sponsored_benefit_package_id.in => renewal_bg_ids,
                            :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES + ['auto_renewing']
                          })

                          %w(health dental).each do |coverage_kind|
                            if renewal_enrollments.where(:coverage_kind => coverage_kind).present?
                              renewal_enrollment_count += 1
                            end
                          end
                        end
                      end
                  data += [active_enrollment_count, renewal_enrollment_count]
                  csv << data
                end
              end
            end
            puts "Successfully generated non_detailed_report #{file_name}"
          rescue => e
            puts "#{e}"
          end
        end
      end

      def dry_run
        start_on_date = Date.strptime(ENV['start_on_date'], "%m/%d/%Y")
        detailed_report(start_on_date)
        assign_packages(start_on_date)
        non_detailed_report(start_on_date)
      end
      dry_run
    end
  end
end
